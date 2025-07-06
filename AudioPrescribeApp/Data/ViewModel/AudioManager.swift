//
//  AudioManager.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import Foundation

import AVFoundation
import Combine
import Speech

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var recordingSession: RecordingSession?
    @Published var permissionGranted = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    private var segmentTimer: Timer?
    private var currentSegmentStartTime: TimeInterval = 0
    private let segmentDuration: TimeInterval = 30.0
    private var segments: [TranscriptionSegment] = []
    
    // FIXED: Use consistent format throughout
    private var recordingFormat: AVAudioFormat?
    
    private let transcriptionService = TranscriptionService()
    
    override init() {
        super.init()
        setupAudioSession()
        requestPermissions()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(audioSessionInterrupted),
                name: AVAudioSession.interruptionNotification,
                object: audioSession
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(audioRouteChanged),
                name: AVAudioSession.routeChangeNotification,
                object: audioSession
            )
            
        } catch {
            print("Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio session"
        }
    }
    
    private func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                if !granted {
                    self.errorMessage = "Microphone permission denied"
                }
            }
        }
    }
    
    @objc private func audioSessionInterrupted(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pauseRecording()
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resumeRecording()
            }
        @unknown default:
            break
        }
    }
    
    @objc private func audioRouteChanged(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            if isRecording {
                pauseRecording()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.resumeRecording()
                }
            }
        default:
            break
        }
    }
    
    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Microphone permission required"
            return
        }
        
        guard !isRecording else { return }
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine!.inputNode
            
            // FIXED: Use the input node's format for consistency
            let inputFormat = inputNode.outputFormat(forBus: 0)
            recordingFormat = inputFormat
            
            // FIXED: Create file format that matches input format
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: Int(inputFormat.channelCount),
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: settings)
            
            // FIXED: Use a format converter if needed
            let outputFormat = audioFile!.processingFormat
            
            if inputFormat.isEqual(outputFormat) {
                // Direct recording - formats match
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, when in
                    do {
                        try self.audioFile?.write(from: buffer)
                    } catch {
                        print("Error writing audio buffer: \(error)")
                    }
                    
                    self.updateAudioLevel(from: buffer)
                }
            } else {
                // FIXED: Use format converter for mismatched formats
                let converter = AVAudioConverter(from: inputFormat, to: outputFormat)!
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, when in
                    // Convert buffer to output format
                    let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: buffer.frameCapacity)!
                    
                    var error: NSError?
                    converter.convert(to: outputBuffer, error: &error) { _, _ in
                        return buffer
                    }
                    
                    if error == nil {
                        do {
                            try self.audioFile?.write(from: outputBuffer)
                        } catch {
                            print("Error writing converted audio buffer: \(error)")
                        }
                    }
                    
                    self.updateAudioLevel(from: buffer)
                }
            }
            
            try audioEngine!.start()
            
            recordingSession = RecordingSession(
                title: "Recording \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))",
                startTime: Date(),
                filePath: audioFilename.path
            )
            
            isRecording = true
            recordingTime = 0
            currentSegmentStartTime = 0
            
            startTimers()
            
        } catch {
            print("Failed to start recording: \(error)")
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    // FIXED: Separate audio level calculation
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frames = buffer.frameLength
        var sum: Float = 0
        
        for i in 0..<Int(frames) {
            sum += abs(channelData[i])
        }
        
        let averageLevel = sum / Float(frames)
        DispatchQueue.main.async {
            self.audioLevel = averageLevel
        }
    }
    
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.recordingTime += 0.1
        }
        
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { _ in
            self.processCurrentSegment()
        }
    }
    
    private func processCurrentSegment() {
        guard let session = recordingSession else { return }
        
        let segmentEndTime = recordingTime
        let segment = TranscriptionSegment(
            sessionId: session.id,
            startTime: currentSegmentStartTime,
            endTime: segmentEndTime,
            audioFilePath: session.filePath
        )
        
        segments.append(segment)
        
        // FIXED: Add delay to ensure file is written before processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.extractAndTranscribeSegment(segment)
        }
        
        currentSegmentStartTime = segmentEndTime
    }
    
    private func extractAndTranscribeSegment(_ segment: TranscriptionSegment) {
        transcriptionService.transcribeSegment(segment) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcription):
                    segment.transcriptionText = transcription
                    segment.processingStatus = .completed
                    segment.isProcessing = false
                    print("✅ Transcription completed for segment \(segment.id)")
                    
                case .failure(let error):
                    print("❌ Transcription failed: \(error)")
                    segment.retryCount += 1
                    
                    if segment.retryCount >= 3 { // FIXED: Reduced retry count
                        segment.processingStatus = .localFallback
                        segment.transcriptionText = "Transcription failed. Try again later."
                        segment.isProcessing = false
                        print("🔄 Using local fallback for segment \(segment.id)")
                    } else {
                        segment.processingStatus = .failed
                        segment.isProcessing = false
                        
                        let retryDelay = pow(2.0, Double(segment.retryCount))
                        print("🔄 Scheduling retry \(segment.retryCount) for segment \(segment.id) in \(retryDelay) seconds")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            self.retryTranscription(segment)
                        }
                    }
                }
            }
        }
    }
    
    private func retryTranscription(_ segment: TranscriptionSegment) {
        print("🔄 Retrying transcription for segment \(segment.id), attempt \(segment.retryCount + 1)")
        extractAndTranscribeSegment(segment)
    }
    
    func pauseRecording() {
        guard isRecording else { return }
        
        audioEngine?.pause()
        recordingTimer?.invalidate()
        segmentTimer?.invalidate()
    }
    
    func resumeRecording() {
        guard isRecording else { return }
        
        do {
            try audioEngine?.start()
            startTimers()
        } catch {
            print("Failed to resume recording: \(error)")
            errorMessage = "Failed to resume recording"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recordingTimer?.invalidate()
        segmentTimer?.invalidate()
        
        // FIXED: Ensure file is closed properly
        audioFile = nil
        
        // FIXED: Add delay before processing final segment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.recordingTime > self.currentSegmentStartTime {
                self.processCurrentSegment()
            }
        }
        
        recordingSession?.endTime = Date()
        recordingSession?.duration = recordingTime
        recordingSession?.segments = segments
        
        isRecording = false
        recordingTime = 0
        audioLevel = 0.0
        
        segments.removeAll()
        currentSegmentStartTime = 0
    }
}

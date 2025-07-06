//
//  TranscriptionService.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import Foundation
import AVFoundation
import Speech

class TranscriptionService {
    private let apiKey = "your-api-key-here" // SECURITY: Remove the actual key from code
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private let session = URLSession.shared
    
    private let speechRecognizer = SFSpeechRecognizer()
    
    enum TranscriptionError: Error {
        case noApiKey
        case invalidAudioFile
        case networkError
        case apiError(String)
        case localTranscriptionNotAvailable
        case fileNotFound
        case formatNotSupported
    }
    
    func transcribeSegment(_ segment: TranscriptionSegment, completion: @escaping (Result<String, Error>) -> Void) {
        segment.isProcessing = true
        segment.processingStatus = .processing
        
        // FIXED: Validate file exists and is readable first
        guard FileManager.default.fileExists(atPath: segment.audioFilePath) else {
            completion(.failure(TranscriptionError.fileNotFound))
            return
        }
        
        // First try OpenAI Whisper API
        transcribeWithWhisperAPI(segment: segment) { [weak self] result in
            switch result {
            case .success(let transcription):
                completion(.success(transcription))
            case .failure(let error):
                print("Whisper API failed: \(error)")
                // If API fails, try local transcription
                self?.transcribeLocally(segment: segment, completion: completion)
            }
        }
    }
    
    private func transcribeWithWhisperAPI(segment: TranscriptionSegment, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty && apiKey != "your-api-key-here" else {
            completion(.failure(TranscriptionError.noApiKey))
            return
        }
        
        // FIXED: Better audio data extraction with validation
        guard let audioData = extractAudioSegment(segment: segment) else {
            completion(.failure(TranscriptionError.invalidAudioFile))
            return
        }
        
        // FIXED: Validate audio data is not empty
        guard !audioData.isEmpty else {
            completion(.failure(TranscriptionError.invalidAudioFile))
            return
        }
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartFormData(audioData: audioData, boundary: boundary)
        request.httpBody = httpBody
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(TranscriptionError.networkError))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "HTTP \(httpResponse.statusCode)"
                completion(.failure(TranscriptionError.apiError(errorMessage)))
                return
            }
            
            guard let data = data else {
                completion(.failure(TranscriptionError.networkError))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(WhisperResponse.self, from: data)
                completion(.success(response.text))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func transcribeLocally(segment: TranscriptionSegment, completion: @escaping (Result<String, Error>) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(TranscriptionError.localTranscriptionNotAvailable))
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                completion(.failure(TranscriptionError.localTranscriptionNotAvailable))
                return
            }
            
            // FIXED: Use the original file directly for local transcription
            let audioURL = URL(fileURLWithPath: segment.audioFilePath)
            
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, result.isFinal else {
                    return
                }
                
                let transcription = result.bestTranscription.formattedString
                completion(.success(transcription))
            }
        }
    }
    
    private func extractAudioSegment(segment: TranscriptionSegment) -> Data? {
        // FIXED: Better error handling and validation
        guard let segmentURL = createSegmentAudioFile(segment: segment) else {
            print("Failed to create segment audio file")
            return nil
        }
        
        defer {
            // Clean up temporary file
            try? FileManager.default.removeItem(at: segmentURL)
        }
        
        do {
            let audioData = try Data(contentsOf: segmentURL)
            print("Successfully extracted audio segment: \(audioData.count) bytes")
            return audioData
        } catch {
            print("Failed to read audio data: \(error)")
            return nil
        }
    }
    
    private func createSegmentAudioFile(segment: TranscriptionSegment) -> URL? {
        let audioURL = URL(fileURLWithPath: segment.audioFilePath)
        
        // FIXED: Better error handling for file operations
        guard FileManager.default.fileExists(atPath: segment.audioFilePath) else {
            print("Audio file does not exist: \(segment.audioFilePath)")
            return nil
        }
        
        do {
            let originalAudioFile = try AVAudioFile(forReading: audioURL)
            let format = originalAudioFile.processingFormat
            let sampleRate = format.sampleRate
            
            // FIXED: Validate segment times
            guard segment.startTime >= 0 && segment.endTime > segment.startTime else {
                print("Invalid segment times: start=\(segment.startTime), end=\(segment.endTime)")
                return nil
            }
            
            let startFrame = AVAudioFramePosition(segment.startTime * sampleRate)
            let endFrame = AVAudioFramePosition(segment.endTime * sampleRate)
            let frameCount = AVAudioFrameCount(endFrame - startFrame)
            
            // FIXED: Validate frame positions
            guard startFrame >= 0 && endFrame <= originalAudioFile.length else {
                print("Invalid frame positions: start=\(startFrame), end=\(endFrame), fileLength=\(originalAudioFile.length)")
                return nil
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(segment.id).m4a")
            
            // FIXED: Use the same format as original file
            let outputFile = try AVAudioFile(forWriting: tempURL, settings: originalAudioFile.fileFormat.settings)
            
            // Set frame position for reading
            originalAudioFile.framePosition = startFrame
            
            // FIXED: Create buffer with proper capacity
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("Failed to create audio buffer")
                return nil
            }
            
            // Read the segment from original file
            try originalAudioFile.read(into: buffer, frameCount: frameCount)
            
            // Write to output file
            try outputFile.write(from: buffer)
            
            print("Created segment audio file: \(tempURL.path)")
            return tempURL
            
        } catch {
            print("Error creating segment audio file: \(error)")
            return nil
        }
    }
    
    private func createMultipartFormData(audioData: Data, boundary: String) -> Data {
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter (optional)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response_format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

struct WhisperResponse: Codable {
    let text: String
}

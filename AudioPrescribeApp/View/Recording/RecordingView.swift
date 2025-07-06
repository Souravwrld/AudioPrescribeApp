//
//  RecordingView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 20) {
            // Audio Level Visualization
            AudioVisualizationView(level: audioManager.audioLevel)
                .frame(height: 60)
            
            // Recording Time
            Text(formatTime(audioManager.recordingTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
            
            // Recording Controls
            HStack(spacing: 30) {
                Button(action: {
                    if audioManager.isRecording {
                        audioManager.stopRecording()
                        if let session = audioManager.recordingSession {
                            modelContext.insert(session)
                        }
                    } else {
                        audioManager.startRecording()
                    }
                }) {
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(audioManager.isRecording ? Color.red : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(!audioManager.permissionGranted)
                
                if audioManager.isRecording {
                    Button(action: {
                        audioManager.pauseRecording()
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Recording Status
            if audioManager.isRecording {
                Text("Recording in progress...")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

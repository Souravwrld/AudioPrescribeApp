//
//  SessionRowView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct SessionRowView: View {
    let session: RecordingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)
            
            HStack {
                Text(formatDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if session.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(height: 10)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

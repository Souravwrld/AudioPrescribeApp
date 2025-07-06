//
//  SegmentView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct SegmentView: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Segment \(formatTimeRange(segment.startTime, segment.endTime))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                StatusBadge(status: segment.processingStatus)
            }
            
            if let transcription = segment.transcriptionText {
                Text(transcription)
                    .font(.body)
                    .padding(.top, 4)
            } else if segment.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTimeRange(_ start: TimeInterval, _ end: TimeInterval) -> String {
        let startMinutes = Int(start) / 60
        let startSeconds = Int(start) % 60
        let endMinutes = Int(end) / 60
        let endSeconds = Int(end) % 60
        
        return String(format: "%02d:%02d - %02d:%02d", startMinutes, startSeconds, endMinutes, endSeconds)
    }
}

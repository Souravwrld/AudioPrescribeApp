//
//  SessionDetailView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct SessionDetailView: View {
    let session: RecordingSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Session Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Information")
                        .font(.headline)
                    
                    InfoRow(label: "Duration", value: formatDuration(session.duration))
                    InfoRow(label: "Start Time", value: formatDate(session.startTime))
                    if let endTime = session.endTime {
                        InfoRow(label: "End Time", value: formatDate(endTime))
                    }
                }
                
                Divider()
                
                // Transcription Segments
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription Segments")
                        .font(.headline)
                    
                    if session.segments.isEmpty {
                        Text("No segments available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(session.segments, id: \.id) { segment in
                            SegmentView(segment: segment)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Info Row View
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

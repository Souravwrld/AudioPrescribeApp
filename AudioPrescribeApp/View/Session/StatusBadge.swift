//
//  StatusBadge.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct StatusBadge: View {
    let status: TranscriptionSegment.ProcessingStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .gray
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .localFallback:
            return .orange
        }
    }
    
    private var textColor: Color {
        return .white
    }
}

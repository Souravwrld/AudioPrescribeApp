//
//  AudioVisualizationView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct AudioVisualizationView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
        .frame(height: 60)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let normalizedLevel = CGFloat(level * 100)
        let threshold = CGFloat(index) * 5
        return normalizedLevel > threshold ? min(normalizedLevel, 60) : 2
    }
    
    private func barColor(for index: Int) -> Color {
        let normalizedLevel = CGFloat(level * 100)
        let threshold = CGFloat(index) * 5
        
        if normalizedLevel > threshold {
            return index < 10 ? .green : index < 15 ? .yellow : .red
        }
        return .gray.opacity(0.3)
    }
}

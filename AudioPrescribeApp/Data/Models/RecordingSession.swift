//
//  RecordingSession.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import Foundation
import SwiftData

@Model
final class RecordingSession {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var filePath: String
    var isProcessing: Bool
    var segments: [TranscriptionSegment]
    
    init(title: String, startTime: Date, filePath: String) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = nil
        self.duration = 0
        self.filePath = filePath
        self.isProcessing = false
        self.segments = []
    }
}

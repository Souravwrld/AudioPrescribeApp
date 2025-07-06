//
//  TranscriptionSegment.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import Foundation
import SwiftData



@Model
final class TranscriptionSegment {
    var id: UUID
    var sessionId: UUID
    var startTime: TimeInterval
    var endTime: TimeInterval
    var audioFilePath: String
    var transcriptionText: String?
    var isProcessing: Bool
    var processingStatus: ProcessingStatus
    var retryCount: Int
    var session: RecordingSession?
    
    enum ProcessingStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
        case localFallback = "local_fallback"
    }
    
    init(sessionId: UUID, startTime: TimeInterval, endTime: TimeInterval, audioFilePath: String) {
        self.id = UUID()
        self.sessionId = sessionId
        self.startTime = startTime
        self.endTime = endTime
        self.audioFilePath = audioFilePath
        self.transcriptionText = nil
        self.isProcessing = false
        self.processingStatus = .pending
        self.retryCount = 0
    }
}

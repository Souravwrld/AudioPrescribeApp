//
//  Item.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

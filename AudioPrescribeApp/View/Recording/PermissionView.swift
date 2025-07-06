//
//  PermissionView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI

struct PermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Microphone Permission Required")
                .font(.headline)
            
            Text("Please enable microphone access in Settings to use this app.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

//
//  ContentView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [RecordingSession]
    
    var body: some View {
        NavigationView {
            VStack {
                if !audioManager.permissionGranted {
                    PermissionView()
                } else {
                    RecordingView()
                    
                    Divider()
                        .padding(.vertical)
                    
                    SessionsListView()
                }
            }
            .navigationTitle("Audio Recorder")
            .environmentObject(audioManager)
            .alert("Error", isPresented: .constant(audioManager.errorMessage != nil)) {
                Button("OK") {
                    audioManager.errorMessage = nil
                }
            } message: {
                Text(audioManager.errorMessage ?? "")
            }
        }
    }
}

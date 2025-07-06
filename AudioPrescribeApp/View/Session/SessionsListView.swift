//
//  SessionsListView.swift
//  AudioPrescribeApp
//
//  Created by Sourav on 06/07/25.
//

import SwiftUI
import _SwiftData_SwiftUI

struct SessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecordingSession.startTime, order: .reverse) private var sessions: [RecordingSession]
    
    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRowView(session: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(PlainListStyle())
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}

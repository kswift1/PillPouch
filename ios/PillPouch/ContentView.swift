//
//  ContentView.swift
//  PillPouch
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        PouchShowcaseView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
        ], inMemory: true)
}

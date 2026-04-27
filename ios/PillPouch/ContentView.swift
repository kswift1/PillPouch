//
//  ContentView.swift
//  PillPouch
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        Text("Pill Pouch")
            .font(.title)
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

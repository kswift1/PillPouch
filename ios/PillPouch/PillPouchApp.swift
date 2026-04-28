//
//  PillPouchApp.swift
//  PillPouch
//

import SwiftUI
import SwiftData

@main
struct PillPouchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Supplement.self,
            IntakeSchedule.self,
            IntakeLog.self,
            UserSettings.self,
            CategoryMirror.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

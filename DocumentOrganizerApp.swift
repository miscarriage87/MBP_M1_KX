import SwiftUI
import UniformTypeIdentifiers

@main
struct DocumentOrganizerApp: App {
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var indexingManager = IndexingManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
                .environmentObject(indexingManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            SettingsView()
                .environmentObject(documentManager)
                .environmentObject(indexingManager)
        }
    }
}

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DocumentOrganizerApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DocumentOrganizerApp",
            targets: ["DocumentOrganizerApp"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "DocumentOrganizerApp",
            path: ".",
            sources: [
                "DocumentOrganizerApp.swift",
                "DocumentManager.swift", 
                "IndexingManager.swift",
                "AIManager.swift",
                "ContentView.swift",
                "AIAnalysisView.swift",
                "AdditionalViews.swift"
            ]
        )
    ]
)

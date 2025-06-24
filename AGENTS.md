# AGENTS.md

## Project Purpose and High-Level Architecture

The Document Organizer is a native macOS application designed to intelligently organize and index SAP SuccessFactors HR transformation documents, optimizing them for LLM access and analysis. Key components include:

- **DocumentManager**: Handles file operations and organization. Utilizes Combine for reactive programming and OSLog for performance logging.
- **IndexingManager**: Manages search indexing and content extraction. Supports metadata extraction optimized for LLMs.
- **AIManager**: Integrates with OpenAI for AI-powered document analysis, including summarization, keyword extraction, and relevance scoring.
- **SwiftUI Views**: Provides the user interface, including main interfaces and additional supporting views.

## Folder Layout and Build System

- **Folder Structure**:
  ```
  DocumentOrganizerApp/
  ├── DocumentOrganizerApp.swift    # Main app entry point
  ├── DocumentManager.swift         # File operations and organization
  ├── IndexingManager.swift         # Search indexing and content extraction
  ├── AIManager.swift               # OpenAI integration and analysis
  ├── ContentView.swift             # Main user interface
  ├── AIAnalysisView.swift          # AI analysis interface
  ├── AdditionalViews.swift         # Supporting UI components
  ├── Package.swift                 # Swift Package Manager config
  ├── build.sh                      # Build script for Apple Silicon
  ├── README.md                     # Comprehensive documentation
  └── build/                        # Build output directory
  ```

- **Build System**: Uses Swift Package Manager (SwiftPM) for building and managing dependencies.
- **Requirements**: macOS 14+.

## Coding Standards

- **Language Version**: Swift 5.9.
- **Frameworks**: Adheres to SwiftUI best practices and makes use of Combine.
- **Async/Await**: Used for managing asynchronous tasks.
- **Logging**: Implements OSLog for logging.
- **Optimization**: Optimized for Apple Silicon, leveraging multi-threaded processing and ARM64 compilation.

## Interaction Policy

- Propose changes via Pull Requests (PRs).
- Run `swift test` to ensure code quality.
- If added, adhere to `.swiftformat` rules for consistent code formatting.
- Respect project's LICENSE and ensure no proprietary data is included.

## Security and Privacy

- Customer documents must **never** be uploaded.
- AI features rely on an OpenAI key securely stored in the macOS Keychain.

## Extension Points

AI agents can add value by:

- Implementing SAP-specific categorization.
- Enhancing performance tuning.
- Developing new analyses for SAP SuccessFactors documents.


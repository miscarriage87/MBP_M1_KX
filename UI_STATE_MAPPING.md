# UI State and Controls Mapping

## Overview
This document maps the current UI controls and state management in the DocumentOrganizerApp to establish a baseline for design system integration.

## Environment Managers (ObservableObjects)

### 1. DocumentManager
**Location**: `DocumentManager.swift`
**State Properties**:
- `@Published var documents: [DocumentItem] = []`
- `@Published var isScanning = false`
- `@Published var scanProgress: Double = 0.0`
- `@Published var totalDocuments = 0`
- `@Published var organizedDocuments = 0`

**Controls**:
- Directory scanning and document categorization
- Document organization and file system operations
- Progress tracking for scanning operations

### 2. IndexingManager
**Location**: `IndexingManager.swift`
**State Properties**:
- `@Published var isIndexing = false`
- `@Published var indexingProgress: Double = 0.0`
- `@Published var searchResults: [SearchResult] = []`
- `@Published var indexedCount = 0`

**Controls**:
- Document content indexing and search functionality
- Full-text search with relevance scoring
- LLM-optimized index generation for export

### 3. AIManager
**Location**: `AIManager.swift`
**State Properties**:
- `@Published var isAnalyzing = false`
- `@Published var analysisProgress: Double = 0.0`
- `@Published var analysisResults: [DocumentAnalysis] = []`
- `@Published var apiKey: String = ""`
- `@Published var hasValidKey = false`

**Controls**:
- OpenAI API integration for document analysis
- Batch processing of AI analysis tasks
- API key management and validation

## Main Views and UI Components

### ContentView
**Location**: `ContentView.swift`
**Local State**:
- `@State private var selectedDirectory: URL?`
- `@State private var searchText = ""`
- `@State private var selectedCategory: DocumentCategory? = nil`
- `@State private var showingFileImporter = false`
- `@State private var showingAIAnalysis = false`
- `@State private var showingExportSheet = false`

**UI Controls**:
- Navigation split view with sidebar, content, and detail panes
- Category filtering system
- Search functionality
- File import dialogs
- Progress indicators for scanning and indexing

### Reusable Components

#### CategoryRow
**Location**: `ContentView.swift` (lines 274-310)
**Props**: `category`, `count`, `isSelected`, `action`
**Visual State**: Selection highlighting, icon display, count badges

#### DocumentRow  
**Location**: `ContentView.swift` (lines 312-355)
**Props**: `document`
**Visual Elements**: Category icons, metadata display, formatted dates

#### SearchResultRow
**Location**: `ContentView.swift` (lines 357-391)
**Props**: `result`
**Visual Elements**: Relevance scoring, highlighted matching text

### Additional Views

#### AIAnalysisView
**Location**: `AIAnalysisView.swift`
**Local State**:
- `@State private var showingAPIKeyInput = false`

**UI Components**:
- Analysis progress tracking
- API key configuration interface
- Analysis results display with business value indicators

#### DocumentDetailView
**Location**: `AdditionalViews.swift` (lines 106-259)
**Local State**:
- `@State private var showingQuickLook = false`
- `@State private var quickLookURL: URL?`

**UI Components**:
- Document metadata display
- AI analysis results presentation
- Business value assessment visualization

#### SettingsView
**Location**: `AdditionalViews.swift` (lines 310-367)
**UI Controls**:
- Toggle switches for feature configuration
- Performance metrics display
- Cache management controls

## Current Design Patterns

### Color Usage
- **Accent Color**: Used for primary actions, category icons, progress indicators
- **Secondary Color**: Used for metadata text, supplementary information
- **System Colors**: `NSColor.controlBackgroundColor`, `NSColor.textBackgroundColor`

### Typography Patterns
- **Titles**: `.title2` with `.fontWeight(.bold)` for section headers
- **Body Text**: `.system(size: 14, weight: .medium)` for document names
- **Metadata**: `.system(size: 11)` with `.foregroundColor(.secondary)` for details
- **Captions**: `.caption` and `.caption2` for small text

### Spacing Patterns
- **Card Padding**: 12-16px internal padding
- **Section Spacing**: 16-24px between major sections
- **List Item Spacing**: 8px vertical padding
- **Button Spacing**: 12px between action buttons

### Component Patterns
- **Progress Views**: Linear style for operations, circular for business values
- **Buttons**: `.borderedProminent` for primary, `.bordered` for secondary
- **Lists**: `.plain` style for clean presentation
- **Cards**: Rounded rectangles with background color and padding

## Integration with New Services

### Potential Impact Areas
1. **MarkdownConversionService**: May need progress indicators and status displays
2. **MemoryContextService**: Could require connection status indicators
3. **ExportManager**: Will need enhanced export UI with format selection

### Design System Alignment
The new `DesignSystem.swift` provides:
- **AppColors**: Centralized color palette including SAP-specific colors
- **AppFonts**: Semantic typography system with proper weight assignments
- **Insets**: Consistent spacing system from extra-small to jumbo
- **CornerRadius**: Standardized border radius values
- **AppShadows**: Elevation system for visual hierarchy

## Recommendations for Future Development

1. **State Management**: Consider consolidating related state into fewer, more focused managers
2. **Component Library**: Extract reusable components into separate files
3. **Design Tokens**: Gradually replace hardcoded values with design system tokens
4. **Responsive Design**: Plan for different window sizes and screen densities
5. **Accessibility**: Add semantic labels and VoiceOver support to components

## Screenshots Reference
- **Before Design System**: `~/Desktop/before_design_system.png`
- **After Design System**: `~/Desktop/after_design_system.png`

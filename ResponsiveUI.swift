import SwiftUI

// MARK: - Responsive Design Utilities

struct ResponsiveContainer<Content: View>: View {
    let content: (SizeClass) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            content(SizeClass.from(geometry.size))
        }
    }
}

enum SizeClass {
    case compact    // < 600 width
    case regular    // 600-900 width
    case large      // > 900 width
    
    static func from(_ size: CGSize) -> SizeClass {
        if size.width < 600 {
            return .compact
        } else if size.width < 900 {
            return .regular
        } else {
            return .large
        }
    }
}

// MARK: - Adaptive Layouts

struct AdaptiveHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            Group {
                if sizeClass == .compact {
                    VStack(alignment: .leading, spacing: spacing) {
                        content()
                    }
                } else {
                    HStack(alignment: alignment, spacing: spacing) {
                        content()
                    }
                }
            }
        }
    }
}

struct AdaptiveGrid<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            LazyVGrid(
                columns: gridColumns(for: sizeClass),
                spacing: 16
            ) {
                content()
            }
        }
    }
    
    private func gridColumns(for sizeClass: SizeClass) -> [GridItem] {
        switch sizeClass {
        case .compact:
            return [GridItem(.flexible())]
        case .regular:
            return Array(repeating: GridItem(.flexible()), count: 2)
        case .large:
            return Array(repeating: GridItem(.flexible()), count: 3)
        }
    }
}

// MARK: - Dynamic Button Styles

struct AdaptiveButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            Button(action: action) {
                if sizeClass == .compact {
                    // Compact: Icon only
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .font(.title2)
                    } else {
                        Text(String(title.prefix(1)))
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                } else {
                    // Regular/Large: Icon + Text
                    if let systemImage = systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                }
            }
            .buttonStyle(.bordered)
            .help(title) // Tooltip for compact mode
        }
    }
}

// MARK: - Progress Indicators with Dynamic Detail

struct SmartProgressView: View {
    let title: String
    let progress: Double
    let isActive: Bool
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(sizeClass == .compact ? .caption : .subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if sizeClass != .compact {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .opacity(isActive ? 1.0 : 0.5)
                
                if sizeClass == .compact && isActive {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Adaptive List Rows

struct AdaptiveDocumentRow: View {
    let document: DocumentItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            Button(action: onTap) {
                HStack(spacing: sizeClass == .compact ? 8 : 12) {
                    Image(systemName: document.category.icon)
                        .font(sizeClass == .compact ? .body : .title2)
                        .foregroundColor(.accentColor)
                        .frame(width: sizeClass == .compact ? 24 : 32, height: sizeClass == .compact ? 24 : 32)
                    
                    VStack(alignment: .leading, spacing: sizeClass == .compact ? 2 : 4) {
                        Text(document.name)
                            .font(.system(size: sizeClass == .compact ? 12 : 14, weight: .medium))
                            .lineLimit(sizeClass == .compact ? 1 : 2)
                        
                        if sizeClass != .compact {
                            HStack(spacing: 8) {
                                Text(document.category.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Text(document.formattedSize)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if sizeClass == .compact {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, sizeClass == .compact ? 6 : 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
    }
}

// MARK: - Status Bar Component

struct StatusBarView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var indexingManager: IndexingManager
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            Group {
                if documentManager.isScanning || indexingManager.isIndexing {
                    VStack(spacing: sizeClass == .compact ? 4 : 8) {
                        if documentManager.isScanning {
                            SmartProgressView(
                                title: "Scanning Documents",
                                progress: documentManager.scanProgress,
                                isActive: documentManager.isScanning
                            )
                        }
                        
                        if indexingManager.isIndexing {
                            SmartProgressView(
                                title: "Building Index",
                                progress: indexingManager.indexingProgress,
                                isActive: indexingManager.isIndexing
                            )
                        }
                    }
                    .padding(sizeClass == .compact ? 8 : 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.3), value: documentManager.isScanning)
                    .animation(.easeInOut(duration: 0.3), value: indexingManager.isIndexing)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Error and Empty State Views

struct SmartEmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        _ title: String,
        subtitle: String = "",
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            VStack(spacing: sizeClass == .compact ? 12 : 20) {
                Image(systemName: systemImage)
                    .font(.system(size: sizeClass == .compact ? 32 : 48))
                    .foregroundColor(.secondary)
                
                VStack(spacing: sizeClass == .compact ? 4 : 8) {
                    Text(title)
                        .font(sizeClass == .compact ? .headline : .title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(sizeClass == .compact ? .caption : .subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if let actionTitle = actionTitle, let action = action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

// MARK: - Responsive Navigation

struct ResponsiveSidebar<Content: View>: View {
    @Binding var isVisible: Bool
    let content: () -> Content
    
    var body: some View {
        ResponsiveContainer { sizeClass in
            Group {
                if sizeClass == .compact && !isVisible {
                    EmptyView()
                } else {
                    content()
                        .frame(
                            minWidth: sizeClass == .compact ? 0 : 250,
                            maxWidth: sizeClass == .compact ? .infinity : 300
                        )
                }
            }
        }
    }
}

// MARK: - View Modifiers

extension View {
    func adaptiveFont(compact: Font, regular: Font) -> some View {
        ResponsiveContainer { sizeClass in
            self.font(sizeClass == .compact ? compact : regular)
        }
    }
    
    func adaptivePadding(compact: CGFloat, regular: CGFloat) -> some View {
        ResponsiveContainer { sizeClass in
            self.padding(sizeClass == .compact ? compact : regular)
        }
    }
    
    func hideInCompactMode() -> some View {
        ResponsiveContainer { sizeClass in
            Group {
                if sizeClass != .compact {
                    self
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    func showOnlyInCompactMode() -> some View {
        ResponsiveContainer { sizeClass in
            Group {
                if sizeClass == .compact {
                    self
                } else {
                    EmptyView()
                }
            }
        }
    }
}

#Preview("Responsive Container") {
    ResponsiveContainer { sizeClass in
        VStack {
            Text("Current size class: \(String(describing: sizeClass))")
            
            AdaptiveHStack {
                Button("Action 1") { }
                Button("Action 2") { }
                Button("Action 3") { }
            }
            
            SmartEmptyStateView(
                "No Documents",
                subtitle: "Select a directory to get started",
                systemImage: "doc.text.magnifyingglass",
                actionTitle: "Select Directory"
            ) { }
        }
        .padding()
    }
    .frame(width: 400, height: 300)
}

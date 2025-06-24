# Document Organizer for SAP SuccessFactors

A native macOS application optimized for Apple Silicon that intelligently organizes and indexes your SAP SuccessFactors HR transformation documents for optimal LLM access and analysis.

## Features

### 🚀 Core Capabilities
- **Intelligent Document Organization**: Automatically categorizes documents based on SAP SuccessFactors and HR context
- **Advanced Search & Indexing**: Fast full-text search with semantic understanding
- **AI-Powered Analysis**: OpenAI GPT-4 integration for document insights and recommendations
- **LLM-Optimized Export**: Generates structured indexes perfect for AI consumption
- **Apple Silicon Optimized**: Native performance on M1/M2/M3 Macs

### 📁 Document Categories
- SAP SuccessFactors specific documents
- HR Documents & Policies
- Implementation & Project docs
- Configuration & Setup guides
- Templates & Forms
- Training Materials
- Data & Reports
- Presentations
- Documentation

### 🧠 AI Features
- Document summarization and keyword extraction
- Business value assessment
- Implementation relevance scoring
- Recommended actions
- Smart categorization
- Compliance and security analysis

## Installation

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1/M2/M3)
- Xcode Command Line Tools
- OpenAI API Key (optional, for AI features)

### Build from Source

1. **Clone or download the source code**:
   ```bash
   # If you have the files, navigate to the directory
   cd DocumentOrganizerApp
   ```

2. **Install Xcode Command Line Tools** (if not already installed):
   ```bash
   xcode-select --install
   ```

3. **Build the application**:
   ```bash
   ./build.sh
   ```

4. **Run the application**:
   ```bash
   ./build/DocumentOrganizerApp
   ```

### System Installation (Optional)
```bash
sudo cp build/DocumentOrganizerApp /usr/local/bin/
```

## Configuration

### OpenAI API Key Setup
To enable AI analysis features:

1. Visit [platform.openai.com](https://platform.openai.com)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new secret key
5. In the app, go to Settings or click "AI Analysis" and enter your key

## Usage

### Basic Workflow

1. **Select Directory**: Click "Select Directory" to choose your document folder
2. **Scan Documents**: The app automatically scans and categorizes your files
3. **Build Index**: Click "Build Index" for advanced search capabilities
4. **AI Analysis**: Run AI analysis for detailed insights (requires API key)
5. **Export**: Generate LLM-optimized indexes for external use

### Document Management

- **Auto-Organization**: Creates organized folder structure with symbolic links
- **Search**: Use the search bar for instant document discovery
- **Categories**: Filter documents by type and business relevance
- **Quick Look**: Preview documents directly in the app

### AI-Powered Insights

The AI analysis provides:
- **Summaries**: Concise descriptions of document content
- **Keywords**: Extracted relevant terms and concepts
- **Business Value Scores**: Implementation, configuration, training, data, and compliance relevance
- **Recommended Actions**: Suggested next steps for each document
- **Smart Tags**: AI-generated classification tags

## File Types Supported

- **Documents**: PDF, DOC, DOCX, TXT, RTF
- **Spreadsheets**: XLS, XLSX, CSV
- **Presentations**: PPT, PPTX
- **Data**: JSON, XML
- **Archives**: ZIP

## Performance

### Optimized for Large Collections
- Handles 100-200GB document collections efficiently
- Multi-threaded processing for fast scanning
- Incremental indexing for updates
- Memory-efficient design for sustained performance

### Apple Silicon Optimization
- Native ARM64 compilation
- Metal Performance Shaders integration
- Unified memory architecture utilization
- Power-efficient background processing

## LLM Integration

### Export Formats
- **Markdown**: Human-readable structured index
- **JSON**: Machine-readable data format
- **CSV**: Tabular data for analysis

### LLM-Optimized Features
- Hierarchical document organization
- Semantic keyword extraction
- Business context classification
- Relevance scoring
- Actionable insights

## Privacy & Security

- **Local Processing**: All indexing happens on your Mac
- **Secure API Key Storage**: Keys stored in macOS Keychain
- **No Data Collection**: Your documents stay private
- **Symbolic Links**: No file duplication, original files unchanged

## Troubleshooting

### Common Issues

**Build Errors**:
- Ensure Xcode Command Line Tools are installed
- Check that you're on macOS 14.0 or later
- Verify Apple Silicon architecture

**Performance Issues**:
- Close other memory-intensive applications
- Consider indexing smaller batches for very large collections
- Ensure sufficient free disk space

**AI Analysis Not Working**:
- Verify OpenAI API key is valid and has credits
- Check internet connection
- Ensure API key has appropriate permissions

### Performance Tips

- **Indexing**: Run during off-hours for large collections
- **Organization**: Use symbolic links to save disk space
- **Search**: Build index first for optimal search performance
- **AI Analysis**: Process in batches to respect API rate limits

## Architecture

### Core Components
- **DocumentManager**: File system operations and organization
- **IndexingManager**: Search indexing and content extraction
- **AIManager**: OpenAI integration and analysis
- **ContentView**: Main user interface
- **Additional Views**: Settings, export, and analysis interfaces

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **PDFKit**: Native PDF processing
- **Foundation**: Core system integration
- **Combine**: Reactive programming
- **OSLog**: Performance logging

## Contributing

We welcome contributions to improve the Document Organizer! This application is designed specifically for SAP SuccessFactors HR transformation consultants.

**See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to get involved**, including:
- Development setup and workflow
- Coding standards and best practices
- How to submit issues and pull requests
- Testing requirements

Contributions should focus on:
- Enhanced SAP-specific document recognition
- Improved HR process categorization
- Additional AI analysis capabilities
- Performance optimizations

## License

This project is provided as-is for professional use in SAP SuccessFactors implementations.

**See [LICENSE](LICENSE) for complete license terms and conditions.**

## Support

For issues related to:
- **Build Problems**: Check Xcode and macOS requirements
- **Performance**: Monitor system resources and document collection size
- **AI Features**: Verify OpenAI API configuration
- **SAP Integration**: Ensure document naming follows SAP conventions

---

**Built with ❤️ for SAP SuccessFactors HR Transformation Teams**

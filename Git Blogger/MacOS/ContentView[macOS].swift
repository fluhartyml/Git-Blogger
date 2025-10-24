//
//  ContentView[macOS].swift
//  Git Blogger (macOS)
//
//  Main interface for macOS - GitHub QA Issue Tracker
//  Last Updated: 2025 OCT 24 1055
//

import SwiftUI

#if os(macOS)
struct ContentView: View {
    @State private var repositories: [Repository] = []
    @State private var selectedRepository: Repository?
    @State private var selectedIssue: Issue?
    @State private var currentIssues: [Issue] = []
    @State private var showCompletedIssues = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    private let configManager = ConfigManager()
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar - Repository or Issue List
            if currentIssues.isEmpty {
                // Show repository list
                repositoryListView
            } else {
                // Show issue list for selected repository
                issueListView
            }
        } detail: {
            if let issue = selectedIssue {
                IssueDetailView(
                    issue: issue,
                    configManager: configManager,
                    repository: selectedRepository ?? .mock,
                    onStatusChange: { updatedIssue in
                        handleStatusChange(updatedIssue)
                    }
                )
            } else if let repo = selectedRepository {
                RepositoryDetailView(
                    repository: repo,
                    onIssuesClick: {
                        loadIssues(for: repo)
                    }
                )
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "folder",
                    description: Text("Choose a repository from the sidebar to view details")
                )
            }
        }
        .task {
            await fetchRepositories()
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
    }
    
    // MARK: - Repository List View
    
    private var repositoryListView: some View {
        List(selection: $selectedRepository) {
            Section("GitHub Repositories") {
                ForEach(repositories) { repo in
                    NavigationLink(value: repo) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                Text(repo.name)
                                    .font(.headline)
                            }
                            
                            if let description = repo.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            HStack(spacing: 12) {
                                if let language = repo.language {
                                    Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                                        .font(.caption2)
                                }
                                
                                Label("\(repo.stargazersCount)", systemImage: "star")
                                    .font(.caption2)
                                
                                if repo.hasWiki {
                                    Label("Wiki", systemImage: "book.closed")
                                        .font(.caption2)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Git Issue Tracker")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await fetchRepositories()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onChange(of: selectedRepository) { _, newValue in
            if newValue != nil {
                selectedIssue = nil
                currentIssues = []
            }
        }
    }
    
    // MARK: - Issue List View
    
    private var issueListView: some View {
        VStack(spacing: 0) {
            // Header with back button and toggle
            HStack {
                Button {
                    currentIssues = []
                    selectedIssue = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Toggle("Show Completed", isOn: $showCompletedIssues)
                    .toggleStyle(.checkbox)
                    .font(.caption)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Issue list
            List(selection: $selectedIssue) {
                Section("Issues (\(filteredIssues.count))") {
                    ForEach(filteredIssues) { issue in
                        NavigationLink(value: issue) {
                            IssueRowView(issue: issue)
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedRepository?.name ?? "Issues")
    }
    
    private var filteredIssues: [Issue] {
        let filtered = showCompletedIssues
            ? currentIssues
            : currentIssues.filter { !$0.isArchived }
        
        // Sort by priority (red > yellow > green > dark green), then by date
        return filtered.sorted { lhs, rhs in
            if lhs.priorityLevel != rhs.priorityLevel {
                return lhs.priorityLevel < rhs.priorityLevel
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchRepositories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = GitHubService(configManager: configManager)
            repositories = try await service.fetchRepositories()
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching repositories: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadIssues(for repository: Repository) {
        Task {
            do {
                let service = GitHubService(configManager: configManager)
                let issues = try await service.fetchIssues(for: repository, state: "all")
                
                await MainActor.run {
                    currentIssues = issues
                    
                    // Auto-select first red issue if any
                    if let firstRed = issues.first(where: { $0.priorityColor == .red }) {
                        selectedIssue = firstRed
                    } else if let firstIssue = issues.first {
                        selectedIssue = firstIssue
                    }
                }
            } catch {
                print("Error fetching issues: \(error)")
            }
        }
    }
    
    private func handleStatusChange(_ updatedIssue: Issue) {
        // Update the issue in the current list
        if let index = currentIssues.firstIndex(where: { $0.id == updatedIssue.id }) {
            currentIssues[index] = updatedIssue
            selectedIssue = updatedIssue
        }
    }
}

// MARK: - Repository Detail View

struct RepositoryDetailView: View {
    let repository: Repository
    let onIssuesClick: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(repository.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = repository.description {
                            Text(description)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Stats row with clickable colored issue button
                HStack(spacing: 20) {
                    Label("\(repository.stargazersCount)", systemImage: "star")
                    Label("\(repository.forksCount)", systemImage: "tuningfork")
                    
                    // Colored issue button
                    Button(action: onIssuesClick) {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(issueColor)
                            Text("📋 \(repository.openIssuesCount) issues")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(issueColor.opacity(0.2))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    if let language = repository.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                Divider()
                
                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button {
                            // Manage wiki action
                        } label: {
                            Label("Manage Wiki", systemImage: "book.closed")
                        }
                        .disabled(!repository.hasWiki)
                        
                        Button {
                            // Clone repository action
                        } label: {
                            Label("Clone Repository", systemImage: "arrow.down.circle")
                        }
                        
                        Button {
                            if let url = repository.url {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label("Open on GitHub", systemImage: "safari")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Repository Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repository Info")
                        .font(.headline)
                    
                    InfoRow(label: "Default Branch", value: repository.defaultBranch)
                    InfoRow(label: "Created", value: repository.createdAt.formatted(date: .abbreviated, time: .omitted))
                    InfoRow(label: "Last Updated", value: repository.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    InfoRow(label: "Size", value: "\(repository.size) KB")
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var issueColor: Color {
        if repository.openIssuesCount == 0 {
            return .green // All resolved
        }
        return .red // Has open issues (highest priority)
    }
}

// MARK: - Issue Row View

struct IssueRowView: View {
    let issue: Issue
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("#\(issue.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(issue.title)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 8) {
                    Text("by \(issue.user.login)")
                        .font(.caption2)
                    Text("•")
                    Text(issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                    Text("•")
                    Text("\(issue.comments) comments")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Labels
            if !issue.labels.isEmpty {
                Text(issue.labels.first?.name ?? "")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(issue.priorityColor.opacity(0.3))
        .foregroundStyle(issue.textColor)
        .cornerRadius(6)
    }
}

// MARK: - Issue Detail View

struct IssueDetailView: View {
    let issue: Issue
    let configManager: ConfigManager
    let repository: Repository
    let onStatusChange: (Issue) -> Void
    
    @State private var privateNotes: String
    @State private var currentIssue: Issue
    
    init(issue: Issue, configManager: ConfigManager, repository: Repository, onStatusChange: @escaping (Issue) -> Void) {
        self.issue = issue
        self.configManager = configManager
        self.repository = repository
        self.onStatusChange = onStatusChange
        _privateNotes = State(initialValue: issue.privateNotes ?? "")
        _currentIssue = State(initialValue: issue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: currentIssue.isOpen ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(currentIssue.priorityColor)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("#\(currentIssue.number)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text(currentIssue.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text(currentIssue.isOpen ? "Open" : "Closed")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(currentIssue.isOpen ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                                .foregroundStyle(currentIssue.isOpen ? .green : .purple)
                                .cornerRadius(4)
                            
                            Text("by \(currentIssue.user.login)")
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text(currentIssue.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                
                // Labels
                if !currentIssue.labels.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(currentIssue.labels, id: \.name) { label in
                            Text(label.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: label.color).opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Divider()
                
                // Body
                if let body = currentIssue.body, !body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(body)
                            .textSelection(.enabled)
                    }
                } else {
                    Text("No description provided.")
                        .foregroundStyle(.secondary)
                        .italic()
                }
                
                Divider()
                
                // Comments section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comments")
                        .font(.headline)
                    
                    Text("\(currentIssue.comments) comments on GitHub")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        if let url = currentIssue.url {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("View Comments on GitHub", systemImage: "bubble.left.and.bubble.right")
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Private Notes (local only)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Private Notes (Local Only)")
                        .font(.headline)
                    
                    TextEditor(text: $privateNotes)
                        .frame(minHeight: 100)
                        .border(Color.secondary.opacity(0.3))
                        .onChange(of: privateNotes) { _, newValue in
                            savePrivateNotes(newValue)
                        }
                }
                
                Spacer()
                
                // Status Buttons (bottom center)
                HStack(spacing: 12) {
                    StatusButton(
                        title: "Mark New",
                        color: .red,
                        isActive: currentIssue.priorityColor == .red,
                        action: { setStatus("red") }
                    )
                    
                    StatusButton(
                        title: "Working On",
                        color: .yellow,
                        isActive: currentIssue.priorityColor == .yellow,
                        action: { setStatus("yellow") }
                    )
                    
                    StatusButton(
                        title: "Resolved",
                        color: .green,
                        isActive: currentIssue.priorityColor == .green,
                        action: { setStatus("lightGreen") }
                    )
                    
                    StatusButton(
                        title: "Archive",
                        color: Color(red: 0, green: 0.5, blue: 0),
                        isActive: currentIssue.priorityColor == Color(red: 0, green: 0.5, blue: 0),
                        action: { setStatus("darkGreen") }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding()
        }
    }
    
    private func savePrivateNotes(_ notes: String) {
        let service = GitHubService(configManager: configManager)
        try? service.updateLocalIssueData(
            repository: repository,
            issueNumber: currentIssue.number,
            privateNotes: notes
        )
        
        var updated = currentIssue
        updated.privateNotes = notes
        currentIssue = updated
        onStatusChange(updated)
    }
    
    private func setStatus(_ status: String) {
        Task {
            let service = GitHubService(configManager: configManager)
            
            // Handle GitHub state changes
            switch status {
            case "red", "yellow":
                if currentIssue.isClosed {
                    try? await service.reopenIssue(repository: repository, issueNumber: currentIssue.number)
                }
            case "lightGreen":
                if currentIssue.isOpen {
                    try? await service.closeIssue(repository: repository, issueNumber: currentIssue.number)
                }
            case "darkGreen":
                if currentIssue.isOpen {
                    try? await service.closeIssue(repository: repository, issueNumber: currentIssue.number)
                }
                try? service.updateLocalIssueData(
                    repository: repository,
                    issueNumber: currentIssue.number,
                    isArchived: true
                )
            default:
                break
            }
            
            // Update manual status locally
            try? service.updateLocalIssueData(
                repository: repository,
                issueNumber: currentIssue.number,
                manualStatus: status
            )
            
            // Refresh issue data
            let issues = try? await service.fetchIssues(for: repository, state: "all")
            if let updatedIssue = issues?.first(where: { $0.number == currentIssue.number }) {
                await MainActor.run {
                    currentIssue = updatedIssue
                    onStatusChange(updatedIssue)
                }
            }
        }
    }
}

// MARK: - Status Button

struct StatusButton: View {
    let title: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? color : color.opacity(0.3))
                .foregroundColor(textColor)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var textColor: Color {
        if isActive {
            switch color {
            case .red, Color(red: 0, green: 0.5, blue: 0): return .white
            case .yellow, .green: return .black
            default: return .white
            }
        } else {
            return .primary
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Helper for hex color

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
#endif


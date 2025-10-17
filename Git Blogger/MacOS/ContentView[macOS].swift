//
//  ContentView[macOS].swift
//  Git Blogger (macOS)
//
//  Main interface for macOS - Full GitHub account management
//

import SwiftUI

#if os(macOS)
struct ContentView: View {
    @State private var repositories: [Repository] = []
    @State private var selectedRepository: Repository?
    @State private var selectedIssue: Issue?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var showingIssuePicker = false
    @State private var issuesForPicker: [Issue] = []
    private let configManager = ConfigManager()
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar
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
                        
                        // Issues subsection
                        if repo.openIssuesCount > 0 {
                            DisclosureGroup {
                                Button("Issue #1") {
                                    handleIssueClick(for: repo)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                
                                if repo.openIssuesCount > 1 {
                                    Button("Issue #2") {
                                        handleIssueClick(for: repo)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                            } label: {
                                Button(action: {
                                    handleIssueClick(for: repo)
                                }) {
                                    Label("\(repo.openIssuesCount) Issues", systemImage: "exclamationmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Git Blogger")
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
        } detail: {
            if let issue = selectedIssue {
                IssueDetailView(issue: issue)
            } else if let repo = selectedRepository {
                RepositoryDetailView(repository: repo, onIssueClick: {
                    handleIssueClick(for: repo)
                })
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "folder",
                    description: Text("Choose a repository from the sidebar to view details")
                )
            }
        }
        .onChange(of: selectedRepository) { _, newValue in
            // Clear selected issue when switching repositories
            if newValue != nil {
                selectedIssue = nil
            }
        }
        .task {
            await fetchRepositories()
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
        .sheet(isPresented: $showingIssuePicker) {
            IssuePickerView(issues: issuesForPicker, selectedIssue: $selectedIssue, isPresented: $showingIssuePicker)
        }
    }
    
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
    
    private func handleIssueClick(for repository: Repository) {
        Task {
            do {
                let service = GitHubService(configManager: configManager)
                let issues = try await service.fetchIssues(for: repository, state: "all")
                
                await MainActor.run {
                    if issues.count == 1 {
                        // Single issue - open directly
                        selectedIssue = issues.first
                        selectedRepository = nil
                    } else if issues.count > 1 {
                        // Multiple issues - show picker
                        issuesForPicker = issues
                        showingIssuePicker = true
                    }
                }
            } catch {
                print("Error fetching issues: \(error)")
            }
        }
    }
}

struct RepositoryDetailView: View {
    let repository: Repository
    let onIssueClick: () -> Void
    
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
                
                // Stats row with clickable issue indicator
                HStack(spacing: 20) {
                    Label("\(repository.stargazersCount)", systemImage: "star")
                    Label("\(repository.forksCount)", systemImage: "tuningfork")
                    Label("0", systemImage: "clock")
                    
                    // Clickable issue indicator with color coding
                    if repository.openIssuesCount > 0 {
                        Button(action: onIssueClick) {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption2)
                                
                                Text("📋 \(repository.openIssuesCount) open / 0 closed")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption2)
                            
                            Text("📋 0 open / 0 closed")
                        }
                    }
                    
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
}

struct IssueDetailView: View {
    let issue: Issue
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: issue.isOpen ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(issue.isOpen ? .red : .green)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("#\(issue.number)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text(issue.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text(issue.isOpen ? "Open" : "Closed")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(issue.isOpen ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                                .foregroundStyle(issue.isOpen ? .green : .purple)
                                .cornerRadius(4)
                            
                            Text("by \(issue.user.login)")
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text(issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                
                // Labels
                if !issue.labels.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(issue.labels, id: \.name) { label in
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
                if let body = issue.body, !body.isEmpty {
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
                
                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text("Issue Info")
                        .font(.headline)
                    
                    InfoRow(label: "Comments", value: "\(issue.comments)")
                    InfoRow(label: "Created", value: issue.createdAt.formatted(date: .abbreviated, time: .shortened))
                    InfoRow(label: "Updated", value: issue.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    
                    if let closedAt = issue.closedAt {
                        InfoRow(label: "Closed", value: closedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                
                Divider()
                
                // Actions
                Button {
                    if let url = issue.url {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open on GitHub", systemImage: "safari")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct IssuePickerView: View {
    let issues: [Issue]
    @Binding var selectedIssue: Issue?
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select an Issue")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Issue list
            List(issues) { issue in
                Button {
                    selectedIssue = issue
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: issue.isOpen ? "exclamationmark.circle" : "checkmark.circle")
                            .foregroundStyle(issue.isOpen ? .red : .green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("#\(issue.number)")
                                    .foregroundStyle(.secondary)
                                Text(issue.title)
                                    .fontWeight(.medium)
                            }
                            
                            Text("by \(issue.user.login) • \(issue.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if !issue.labels.isEmpty {
                            Text(issue.labels.first?.name ?? "")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 600, height: 400)
    }
}

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

// Helper for hex color
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

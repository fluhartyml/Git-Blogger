//
//  ContentView[macOS].swift
//  Git Blogger (macOS)
//
//  Main interface for macOS - GitHub QA Issue Tracker with All Issues view
//

import SwiftUI

#if os(macOS)
struct ContentView: View {
    @State private var repositories: [Repository] = []
    @State private var selectedRepository: Repository?
    @State private var selectedIssue: Issue?
    @State private var allIssues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var selectedNavigator: NavigatorTab = .repos
    @State private var showingComments = false
    private let configManager = ConfigManager()
    
    enum NavigatorTab: String, CaseIterable {
        case repos = "Repos"
        case issues = "Issues"
        case wiki = "Wiki"
        
        var icon: String {
            switch self {
            case .repos: return "folder"
            case .issues: return "list.clipboard"
            case .wiki: return "book.closed"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Pane B - Navigator with segmented control
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Navigator", selection: $selectedNavigator) {
                    ForEach(NavigatorTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)
                
                Divider()
                
                // Navigator content based on selected tab
                switch selectedNavigator {
                case .repos:
                    repositoryListView
                case .issues:
                    issueNavigatorView
                case .wiki:
                    wikiPlaceholderView
                }
            }
        } detail: {
            // Pane A - Main content
            if showingComments, let issue = selectedIssue {
                CommentsView(
                    issue: issue,
                    configManager: configManager,
                    repository: repositories.first(where: { repo in
                        allIssues.first(where: { $0.id == issue.id })?.repositoryName == repo.fullName
                    }) ?? .mock,
                    onBack: {
                        showingComments = false
                    }
                )
            } else if let issue = selectedIssue {
                IssueDetailView(
                    issue: issue,
                    configManager: configManager,
                    repository: repositories.first(where: { repo in
                        allIssues.first(where: { $0.id == issue.id })?.repositoryName == repo.fullName
                    }) ?? .mock,
                    onBack: {
                        selectedIssue = nil
                    },
                    onViewComments: {
                        showingComments = true
                    },
                    onStatusChange: { updatedIssue in
                        handleStatusChange(updatedIssue)
                    }
                )
            } else if let repo = selectedRepository {
                RepositoryDetailView(
                    repository: repo,
                    configManager: configManager,
                    onBack: {
                        selectedRepository = nil
                    }
                )
            } else {
                allIssuesView
            }
        }
        .task {
            await fetchAllData()
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
    }
    
    // MARK: - Repository List View (Pane B - Repos Tab)
    
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
                        await fetchAllData()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
    }
    
    // MARK: - Issue Navigator View (Pane B - Issues Tab)
    
    private var issueNavigatorView: some View {
        List(selection: $selectedIssue) {
            Section("All Issues (\(sortedIssuesForNavigator.count))") {
                ForEach(sortedIssuesForNavigator) { issue in
                    Button {
                        selectedIssue = issue
                    } label: {
                        IssueRowView(issue: issue, showRepoName: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // Issues sorted OLDER on top for navigator (Pane B)
    private var sortedIssuesForNavigator: [Issue] {
        allIssues.sorted { lhs, rhs in
            if lhs.priorityLevel != rhs.priorityLevel {
                return lhs.priorityLevel < rhs.priorityLevel
            }
            return lhs.createdAt < rhs.createdAt // Older first
        }
    }
    
    // MARK: - All Issues View (Pane A Default)
    
    private var allIssuesView: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedIssue) {
                Section("All Issues (\(sortedIssuesForDisplay.count))") {
                    ForEach(sortedIssuesForDisplay) { issue in
                        Button {
                            selectedIssue = issue
                            selectedNavigator = .issues
                        } label: {
                            IssueRowView(issue: issue, showRepoName: true)
                        }
                        .buttonStyle(.plain)
                        .id(issue.id)
                    }
                }
            }
            .navigationTitle("All Issues")
            .onChange(of: selectedIssue) { _, newValue in
                if let issue = newValue {
                    withAnimation {
                        proxy.scrollTo(issue.id, anchor: .center)
                    }
                }
            }
        }
    }
    
    // Issues sorted NEWER on top for display (Pane A)
    private var sortedIssuesForDisplay: [Issue] {
        allIssues.sorted { lhs, rhs in
            if lhs.priorityLevel != rhs.priorityLevel {
                return lhs.priorityLevel < rhs.priorityLevel
            }
            return lhs.createdAt > rhs.createdAt // Newer first
        }
    }
    
    // MARK: - Wiki Placeholder
    
    private var wikiPlaceholderView: some View {
        ContentUnavailableView(
            "Wiki Navigator",
            systemImage: "book.closed",
            description: Text("Wiki navigation coming soon")
        )
    }
    
    // MARK: - Data Fetching
    
    private func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = GitHubService(configManager: configManager)
            repositories = try await service.fetchRepositories()
            
            // Fetch issues from all repositories
            var allFetchedIssues: [Issue] = []
            for repo in repositories {
                let issues = try await service.fetchIssues(for: repo, state: "all")
                allFetchedIssues.append(contentsOf: issues)
            }
            
            await MainActor.run {
                allIssues = allFetchedIssues
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching data: \(error)")
        }
        
        isLoading = false
    }
    
    private func handleStatusChange(_ updatedIssue: Issue) {
        if let index = allIssues.firstIndex(where: { $0.id == updatedIssue.id }) {
            allIssues[index] = updatedIssue
            selectedIssue = updatedIssue
        }
    }
}

// MARK: - Issue Row View

struct IssueRowView: View {
    let issue: Issue
    var showRepoName: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("#\(issue.number)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(issue.title)
                        .fontWeight(.medium)
                        .font(.caption)
                }
                
                if showRepoName {
                    Text("\(issue.repositoryName) by \(issue.user.login) \(issue.createdAt.formatted(date: .abbreviated, time: .omitted)) \(issue.comments) comments")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("by \(issue.user.login) \(issue.createdAt.formatted(date: .abbreviated, time: .omitted)) \(issue.comments) comments")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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
    let onBack: () -> Void
    let onViewComments: () -> Void
    let onStatusChange: (Issue) -> Void
    
    @State private var privateNotes: String
    @State private var currentIssue: Issue
    
    init(issue: Issue, configManager: ConfigManager, repository: Repository, onBack: @escaping () -> Void, onViewComments: @escaping () -> Void, onStatusChange: @escaping (Issue) -> Void) {
        self.issue = issue
        self.configManager = configManager
        self.repository = repository
        self.onBack = onBack
        self.onViewComments = onViewComments
        self.onStatusChange = onStatusChange
        _privateNotes = State(initialValue: issue.privateNotes ?? "")
        _currentIssue = State(initialValue: issue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Issue detail content
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
                                
                                Text(currentIssue.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comments")
                            .font(.headline)
                        
                        Text("\(currentIssue.comments) comments on GitHub")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            onViewComments()
                        } label: {
                            Label("View Comments", systemImage: "bubble.left.and.bubble.right")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
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
                    
                    Button {
                        toggleIssueState()
                    } label: {
                        Label(
                            currentIssue.isOpen ? "Close Issue" : "Reopen Issue",
                            systemImage: currentIssue.isOpen ? "xmark.circle" : "arrow.clockwise.circle"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(currentIssue.isOpen ? Color.red : Color.green)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 20)
                }
                .padding()
            }
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
    
    private func toggleIssueState() {
        Task {
            let service = GitHubService(configManager: configManager)
            
            do {
                if currentIssue.isOpen {
                    try await service.closeIssue(repository: repository, issueNumber: currentIssue.number)
                } else {
                    try await service.reopenIssue(repository: repository, issueNumber: currentIssue.number)
                }
                
                let issues = try await service.fetchIssues(for: repository, state: "all")
                if let updatedIssue = issues.first(where: { $0.number == currentIssue.number }) {
                    await MainActor.run {
                        currentIssue = updatedIssue
                        onStatusChange(updatedIssue)
                    }
                }
            } catch {
                print("Error toggling issue state: \(error)")
            }
        }
    }
}

// MARK: - Repository Detail View

struct RepositoryDetailView: View {
    let repository: Repository
    let configManager: ConfigManager
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Repository detail content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(repository.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let description = repository.description {
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Repository info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repository Information")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            if let language = repository.language {
                                Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                            }
                            
                            Label("\(repository.stargazersCount) stars", systemImage: "star.fill")
                            
                            Label(repository.isPrivate ? "Private" : "Public", systemImage: repository.isPrivate ? "lock.fill" : "globe")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        if let pushedAt = repository.pushedAt {
                            Text("Last updated: \(pushedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actions")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            Button {
                                if let url = repository.url {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Open on GitHub")
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                let cloneURL = repository.cloneUrl
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(cloneURL, forType: .string)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.doc")
                                    Text("Copy Clone URL")
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // Clone command
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clone Command")
                            .font(.headline)
                        
                        HStack {
                            Text("git clone \(repository.cloneUrl)")
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("git clone \(repository.cloneUrl)", forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let issue: Issue
    let configManager: ConfigManager
    let repository: Repository
    let onBack: () -> Void
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isLoading = false
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Comments (\(comments.count))")
                    .font(.headline)
                
                Spacer()
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Comments list
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Issue context
                    VStack(alignment: .leading, spacing: 8) {
                        Text("#\(issue.number) \(issue.title)")
                            .font(.headline)
                        Text(issue.repositoryName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No comments yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Be the first to comment!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(comments) { comment in
                            CommentRowView(comment: comment)
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Add comment section
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Comment")
                    .font(.headline)
                
                TextEditor(text: $newCommentText)
                    .frame(minHeight: 80)
                    .border(Color.secondary.opacity(0.3))
                
                HStack {
                    Spacer()
                    
                    Button("Post Comment") {
                        postComment()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCommentText.isEmpty || isPosting)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = GitHubService(configManager: configManager)
            comments = try await service.fetchComments(repository: repository, issueNumber: issue.number)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading comments: \(error)")
        }
        
        isLoading = false
    }
    
    private func postComment() {
        isPosting = true
        errorMessage = nil
        
        Task {
            do {
                let service = GitHubService(configManager: configManager)
                try await service.addComment(repository: repository, issueNumber: issue.number, body: newCommentText)
                
                await MainActor.run {
                    newCommentText = ""
                }
                
                // Reload comments
                await loadComments()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isPosting = false
                }
            }
            
            await MainActor.run {
                isPosting = false
            }
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.user.login)
                    .font(.headline)
                
                Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(comment.body)
                .textSelection(.enabled)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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
        case 6:
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

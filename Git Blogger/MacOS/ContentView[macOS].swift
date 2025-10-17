//
//  ContentView[macOS].swift
//  Git Blogger (macOS)
//
//  Main interface for macOS - Full GitHub account management
//

import SwiftUI

struct ContentView: View {
    @StateObject private var configManager = ConfigManager()
    @State private var repositories: [Repository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    
    private var githubService: GitHubService {
        GitHubService(configManager: configManager)
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR - Repository and content browser
            List {
                Section("GitHub Repositories") {
                    if repositories.isEmpty && !isLoading {
                        Text("No repositories loaded")
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(repositories) { repo in
                        NavigationLink(destination: RepositoryDetailView(repository: repo)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: repo.isPrivate ? "lock.fill" : "folder")
                                    Text(repo.name)
                                        .font(.headline)
                                }
                                
                                if let description = repo.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                HStack {
                                    if let language = repo.language {
                                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                                            .font(.caption2)
                                    }
                                    
                                    if repo.hasWiki {
                                        Label("Wiki", systemImage: "book")
                                            .font(.caption2)
                                    }
                                    
                                    if repo.hasPages {
                                        Label("Pages", systemImage: "globe")
                                            .font(.caption2)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(repo.lastActivity)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("Blog Posts") {
                    Label("My First Post", systemImage: "doc.text")
                    Label("Another Post", systemImage: "doc.text")
                }
            }
            .navigationTitle("Git Blogger")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: loadRepositories) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading || !configManager.hasGitHubToken)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            
        } detail: {
            // DETAIL VIEW - Content browser and editor
            if configManager.hasGitHubToken {
                VStack(spacing: 20) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select a repository to manage")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView("Loading repositories...")
                    }
                    
                    if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.secondary)
                            Button("Try Again") {
                                loadRepositories()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("GitHub Token Required")
                        .font(.title2)
                    
                    Text("Configure your GitHub personal access token to get started")
                        .foregroundColor(.secondary)
                    
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            PathSettingsView(configManager: configManager)
        }
        .onAppear {
            // Load cached repositories on launch
            if let cached = githubService.loadCachedRepositories() {
                repositories = cached
            }
            
            // Auto-refresh if token is configured
            if configManager.hasGitHubToken {
                loadRepositories()
            }
        }
    }
    
    private func loadRepositories() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let repos = try await githubService.fetchRepositories()
                await MainActor.run {
                    repositories = repos
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Repository Detail View

struct RepositoryDetailView: View {
    let repository: Repository
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: repository.isPrivate ? "lock.fill" : "folder")
                            .font(.title)
                        Text(repository.name)
                            .font(.largeTitle)
                            .bold()
                    }
                    
                    if let description = repository.description {
                        Text(description)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats
                HStack(spacing: 20) {
                    Label("\(repository.stargazersCount)", systemImage: "star")
                    Label("\(repository.forksCount)", systemImage: "tuningfork")
                    Label("\(repository.openIssuesCount)", systemImage: "exclamationmark.circle")
                    
                    if let language = repository.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                .font(.caption)
                
                Divider()
                
                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.headline)
                    
                    if repository.hasWiki {
                        Button(action: {}) {
                            Label("Manage Wiki", systemImage: "book")
                        }
                    }
                    
                    if repository.hasPages {
                        Button(action: {}) {
                            Label("View GitHub Pages", systemImage: "globe")
                        }
                    }
                    
                    Button(action: { cloneRepository(repository) }) {
                        Label("Clone Repository", systemImage: "arrow.down.circle")
                    }
                    
                    if let url = repository.url {
                        Link(destination: url) {
                            Label("Open on GitHub", systemImage: "arrow.up.forward")
                        }
                    }
                }
                
                Divider()
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repository Info")
                        .font(.headline)
                    
                    LabeledContent("Default Branch", value: repository.defaultBranch)
                    LabeledContent("Created", value: repository.createdAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Last Updated", value: repository.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Size", value: "\(repository.size) KB")
                }
                .font(.caption)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func cloneRepository(_ repository: Repository) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Clone Here"
        panel.message = "Choose where to clone \(repository.name)"
        
        // Set default location to ~/Developer/Git Blogger Repos/
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let defaultCloneLocation = homeDir.appendingPathComponent("Developer/Git Blogger Repos")
        
        // Create default directory if it doesn't exist
        try? FileManager.default.createDirectory(at: defaultCloneLocation, withIntermediateDirectories: true)
        
        panel.directoryURL = defaultCloneLocation
        panel.nameFieldStringValue = repository.name
        
        panel.begin { response in
            guard response == .OK, let selectedURL = panel.url else { return }
            
            // Clone the repository
            Task {
                await self.performClone(repository: repository, to: selectedURL)
            }
        }
    }
    
    private func performClone(repository: Repository, to destination: URL) async {
        print("🔄 Cloning \(repository.name) to \(destination.path)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["clone", repository.cloneUrl, destination.path]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                print("✅ Successfully cloned \(repository.name)")
                
                // Show success notification
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Clone Successful"
                    alert.informativeText = "\(repository.name) has been cloned to:\n\(destination.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Show in Finder")
                    alert.addButton(withTitle: "OK")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        NSWorkspace.shared.selectFile(destination.path, inFileViewerRootedAtPath: destination.deletingLastPathComponent().path)
                    }
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("❌ Clone failed: \(errorString)")
                
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Clone Failed"
                    alert.informativeText = errorString
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        } catch {
            print("❌ Clone error: \(error)")
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Clone Error"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}

#Preview {
    ContentView()
}

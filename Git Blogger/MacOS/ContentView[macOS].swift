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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
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
                                // Placeholder for issue list
                                Text("Issue #1")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Issue #2")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } label: {
                                Label("\(repo.openIssuesCount) Issues", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
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
            if let repo = selectedRepository {
                RepositoryDetailView(repository: repo)
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
}

struct RepositoryDetailView: View {
    let repository: Repository
    
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
                
                // Stats row with issue indicator
                HStack(spacing: 20) {
                    Label("\(repository.stargazersCount)", systemImage: "star")
                    Label("\(repository.forksCount)", systemImage: "tuningfork")
                    Label("0", systemImage: "clock")
                    
                    // Issue indicator with color coding
                    HStack(spacing: 4) {
                        if repository.openIssuesCount > 0 {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption2)
                        } else {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption2)
                        }
                        
                        Text("📋 \(repository.openIssuesCount) open")
                        
                        // Show closed count if we have it (placeholder for now)
                        Text("/ 0 closed")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    
                    if let language = repository.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
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

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
#endif

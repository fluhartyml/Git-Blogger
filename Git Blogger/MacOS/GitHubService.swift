//
//  GitHubService.swift
//  Git Blogger
//
//  GitHub API integration with QA issue tracking
//  Last Updated: 2025 OCT 24 1050
//

import Foundation

class GitHubService {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
    }
    
    // MARK: - Fetch Repositories
    
    func fetchRepositories() async throws -> [Repository] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let username = configManager.config.github.username
        let urlString = "https://api.github.com/users/\(username)/repos?per_page=100&sort=updated"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching GitHub repos from: \(urlString)")
        print("ð Using token: \(configManager.config.github.token.prefix(10))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("ð¦ Received response: \(response)")
        if let httpResponse = response as? HTTPURLResponse {
            print("ð Status code: \(httpResponse.statusCode)")
            print("ð Headers: \(httpResponse.allHeaderFields)")
        }
        print("ð¾ Data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let repos = try decoder.decode([Repository].self, from: data)
            print("â Successfully decoded \(repos.count) repositories")
            
            // Cache to data directory
            try? cacheRepositories(repos)
            
            return repos
        } catch {
            print("â JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("ð Raw JSON (first 500 chars): \(jsonString.prefix(500))")
            }
            throw error
        }
    }
    
    // MARK: - Fetch Issues
    
    func fetchIssues(for repository: Repository, state: String = "all") async throws -> [Issue] {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues?state=\(state)&per_page=100"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        print("ð Fetching issues for \(repository.name) from: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            var issues = try decoder.decode([Issue].self, from: data)
            print("â Successfully decoded \(issues.count) issues for \(repository.name)")
            
            // Merge with cached local data (private notes, archive status, manual status)
            if let cachedIssues = loadCachedIssues(for: repository) {
                issues = mergeLocalData(github: issues, cached: cachedIssues)
            }
            
            // Cache to data directory
            try? cacheIssues(issues, for: repository)
            
            return issues
        } catch {
            print("â JSON Decode Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Create Issue
    
    func createIssue(repository: Repository, title: String, body: String?) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = ["title": title]
        if let body = body {
            payload["body"] = body
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("ð Creating issue '\(title)' in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully created issue '\(title)'")
    }
    
    // MARK: - Update Issue
    
    func updateIssue(
        repository: Repository,
        issueNumber: Int,
        title: String,
        body: String
    ) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "title": title,
            "body": body
        ]
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("ð Updating issue #\(issueNumber) in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully updated issue #\(issueNumber)")
    }
    
    // MARK: - Close/Reopen Issue
    
    func closeIssue(repository: Repository, issueNumber: Int) async throws {
        try await updateIssueState(repository: repository, issueNumber: issueNumber, state: "closed")
    }
    
    func reopenIssue(repository: Repository, issueNumber: Int) async throws {
        try await updateIssueState(repository: repository, issueNumber: issueNumber, state: "open")
    }
    
    private func updateIssueState(repository: Repository, issueNumber: Int, state: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = ["state": state]
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("ð \(state == "closed" ? "Closing" : "Reopening") issue #\(issueNumber) in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully \(state == "closed" ? "closed" : "reopened") issue #\(issueNumber)")
    }
    
    // MARK: - Add Comment
    
    func addComment(repository: Repository, issueNumber: Int, body: String) async throws {
        guard !configManager.config.github.token.isEmpty else {
            throw GitHubError.noToken
        }
        
        let urlString = "https://api.github.com/repos/\(repository.fullName)/issues/\(issueNumber)/comments"
        
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = ["body": body]
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("ð¬ Adding comment to issue #\(issueNumber) in \(repository.name)")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            print("â HTTP Error: \(httpResponse.statusCode)")
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        print("â Successfully added comment to issue #\(issueNumber)")
    }
    
    // MARK: - Local Data Management
    
    func updateLocalIssueData(
        repository: Repository,
        issueNumber: Int,
        privateNotes: String? = nil,
        isArchived: Bool? = nil,
        manualStatus: String? = nil
    ) throws {
        var issues = loadCachedIssues(for: repository) ?? []
        
        if let index = issues.firstIndex(where: { $0.number == issueNumber }) {
            if let notes = privateNotes {
                issues[index].privateNotes = notes
            }
            if let archived = isArchived {
                issues[index].isArchived = archived
            }
            if let status = manualStatus {
                issues[index].manualStatus = status
            }
            
            try cacheIssues(issues, for: repository)
            print("â Updated local data for issue #\(issueNumber)")
        }
    }
    
    private func mergeLocalData(github: [Issue], cached: [Issue]) -> [Issue] {
        var merged = github
        
        for (index, githubIssue) in merged.enumerated() {
            if let cachedIssue = cached.first(where: { $0.id == githubIssue.id }) {
                // Preserve local-only data
                merged[index].privateNotes = cachedIssue.privateNotes
                merged[index].isArchived = cachedIssue.isArchived
                merged[index].manualStatus = cachedIssue.manualStatus
            }
        }
        
        return merged
    }
    
    // MARK: - Cache Management
    
    private func cacheRepositories(_ repos: [Repository]) throws {
        configManager.ensureDataDirectoryExists()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(repos)
        let cacheURL = configManager.dataFileURL(for: "repositories.json")
        
        try data.write(to: cacheURL)
        print("ð Cached repositories to: \(cacheURL.path)")
    }
    
    func loadCachedRepositories() -> [Repository]? {
        let cacheURL = configManager.dataFileURL(for: "repositories.json")
        
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode([Repository].self, from: data)
    }
    
    private func cacheIssues(_ issues: [Issue], for repository: Repository) throws {
        configManager.ensureDataDirectoryExists()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(issues)
        let cacheURL = configManager.dataFileURL(for: "issues-\(repository.name).json")
        
        try data.write(to: cacheURL)
        print("ð Cached issues to: \(cacheURL.path)")
    }
    
    func loadCachedIssues(for repository: Repository) -> [Issue]? {
        let cacheURL = configManager.dataFileURL(for: "issues-\(repository.name).json")
        
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode([Issue].self, from: data)
    }
}

// MARK: - Errors

enum GitHubError: LocalizedError {
    case noToken
    case invalidURL
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No GitHub token configured. Please add your token in settings."
        case .invalidURL:
            return "Invalid GitHub API URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .httpError(let code):
            return "GitHub API error: HTTP \(code)"
        }
    }
}

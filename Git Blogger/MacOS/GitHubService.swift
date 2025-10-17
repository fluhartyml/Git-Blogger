//
//  GitHubService.swift
//  Git Blogger
//
//  GitHub API integration using unencrypted token from config
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
        request.setValue("token \(configManager.config.github.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GitHubError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let repos = try decoder.decode([Repository].self, from: data)
        
        // Cache to data directory
        try? cacheRepositories(repos)
        
        return repos
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
        print("Cached repositories to: \(cacheURL.path)")
    }
    
    func loadCachedRepositories() -> [Repository]? {
        let cacheURL = configManager.dataFileURL(for: "repositories.json")
        
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode([Repository].self, from: data)
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

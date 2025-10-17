//
//  ConfigManager.swift
//  Git Blogger
//
//  Manages unencrypted JSON configuration and user-configurable paths
//

import Foundation
import Combine

struct AppConfig: Codable {
    var github: GitHubConfig
    var paths: PathConfig
    var settings: AppSettings
    
    struct GitHubConfig: Codable {
        var token: String
        var username: String
    }
    
    struct PathConfig: Codable {
        var dataDirectory: String
    }
    
    struct AppSettings: Codable {
        var theme: String
        var refreshInterval: Int
    }
    
    static var `default`: AppConfig {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return AppConfig(
            github: GitHubConfig(token: "", username: ""),
            paths: PathConfig(dataDirectory: "\(homeDir)/Documents/Git Blogger Data"),
            settings: AppSettings(theme: "dark", refreshInterval: 300)
        )
    }
}

class ConfigManager: ObservableObject {
    @Published var config: AppConfig
    
    private let configFileName = "config.json"
    private var configDirectory: URL
    
    init() {
        // Default config directory: ~/Library/Application Support/Git Blogger/
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        configDirectory = appSupport.appendingPathComponent("Git Blogger")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        
        // Load or create config
        config = Self.loadConfig(from: configDirectory.appendingPathComponent(configFileName)) ?? .default
    }
    
    var configFileURL: URL {
        configDirectory.appendingPathComponent(configFileName)
    }
    
    var dataDirectoryURL: URL {
        URL(fileURLWithPath: config.paths.dataDirectory)
    }
    
    // MARK: - Load Config
    
    private static func loadConfig(from url: URL) -> AppConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(AppConfig.self, from: data)
    }
    
    // MARK: - Save Config
    
    func saveConfig() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(config) else {
            print("Failed to encode config")
            return
        }
        
        do {
            try data.write(to: configFileURL)
            print("Config saved to: \(configFileURL.path)")
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    // MARK: - Path Management
    
    func updateConfigDirectory(_ newPath: URL) {
        configDirectory = newPath
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        
        // Save config to new location
        saveConfig()
    }
    
    func updateDataDirectory(_ newPath: String) {
        config.paths.dataDirectory = newPath
        
        // Create data directory if needed
        try? FileManager.default.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
        
        saveConfig()
    }
    
    // MARK: - GitHub Token
    
    func updateGitHubToken(_ token: String, username: String) {
        config.github.token = token
        config.github.username = username
        saveConfig()
    }
    
    var hasGitHubToken: Bool {
        !config.github.token.isEmpty
    }
    
    // MARK: - Data Directory Helpers
    
    func ensureDataDirectoryExists() {
        try? FileManager.default.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
    }
    
    func dataFileURL(for filename: String) -> URL {
        dataDirectoryURL.appendingPathComponent(filename)
    }
}

//
//  PathSettingsView.swift
//  Git Blogger
//
//  User interface for configuring file paths and GitHub token
//

import SwiftUI
import UniformTypeIdentifiers

struct PathSettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var showingConfigPicker = false
    @State private var showingDataPicker = false
    @State private var tokenInput = ""
    @State private var usernameInput = ""
    @State private var showingSaveAlert = false
    
    var body: some View {
        Form {
            // GitHub Configuration
            Section("GitHub Configuration") {
                TextField("GitHub Username", text: $usernameInput)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Personal Access Token", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Save GitHub Token") {
                    configManager.updateGitHubToken(tokenInput, username: usernameInput)
                    showingSaveAlert = true
                }
                .disabled(tokenInput.isEmpty || usernameInput.isEmpty)
                
                if configManager.hasGitHubToken {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Token configured for \(configManager.config.github.username)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Token is stored unencrypted in config.json")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Path Configuration
            Section("File Paths") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Settings Location")
                        .font(.headline)
                    
                    Text(configManager.configFileURL.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Button("Change Settings Path...") {
                        showingConfigPicker = true
                    }
                    
                    Text("Contains: config.json with GitHub token and preferences")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Storage Location")
                        .font(.headline)
                    
                    Text(configManager.config.paths.dataDirectory)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Button("Change Data Path...") {
                        showingDataPicker = true
                    }
                    
                    Text("Contains: repositories.json, blog posts, wiki pages (can be on NAS)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // File Management
            Section("File Management") {
                Button("Open Settings Folder in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: configManager.configFileURL.deletingLastPathComponent().path)
                }
                
                Button("Open Data Folder in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: configManager.config.paths.dataDirectory)
                }
                
                Button("Create Data Directory") {
                    configManager.ensureDataDirectoryExists()
                }
            }
            
            // Info
            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All configuration is stored in plain text JSON files that you can edit manually.")
                    Text("The GitHub token is NOT encrypted - keep your config files secure.")
                    Text("You can move the data directory to a NAS for shared access across devices.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            tokenInput = configManager.config.github.token
            usernameInput = configManager.config.github.username
        }
        .fileImporter(
            isPresented: $showingConfigPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                configManager.updateConfigDirectory(url)
            }
        }
        .fileImporter(
            isPresented: $showingDataPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                configManager.updateDataDirectory(url.path)
            }
        }
        .alert("Token Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Your GitHub token has been saved to config.json")
        }
    }
}

#Preview {
    PathSettingsView(configManager: ConfigManager())
}

//
//  Repository.swift
//  Git Blogger
//
//  GitHub repository data model
//

import Foundation

struct Repository: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let cloneUrl: String
    let sshUrl: String
    let homepage: String?
    let language: String?
    let forksCount: Int
    let stargazersCount: Int
    let watchersCount: Int
    let size: Int
    let defaultBranch: String
    let openIssuesCount: Int
    let isPrivate: Bool
    let isFork: Bool
    let isArchived: Bool
    let hasWiki: Bool
    let hasPages: Bool
    let createdAt: Date
    let updatedAt: Date
    let pushedAt: Date?
    
    var url: URL? {
        URL(string: htmlUrl)
    }
    
    // Hashable conformance (automatically synthesized for structs with Hashable properties)
    // Swift will auto-generate hash(into:) and == based on all properties
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlUrl = "html_url"
        case cloneUrl = "clone_url"
        case sshUrl = "ssh_url"
        case homepage
        case language
        case forksCount = "forks_count"
        case stargazersCount = "stargazers_count"
        case watchersCount = "watchers_count"
        case size
        case defaultBranch = "default_branch"
        case openIssuesCount = "open_issues_count"
        case isPrivate = "private"
        case isFork = "fork"
        case isArchived = "archived"
        case hasWiki = "has_wiki"
        case hasPages = "has_pages"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
    }
}

// Mock data for previews
extension Repository {
    static let mock = Repository(
        id: 1,
        name: "fluhartyml.github.io",
        fullName: "fluhartyml/fluhartyml.github.io",
        description: "Personal portfolio showcasing my Apple/iOS development projects",
        htmlUrl: "https://github.com/fluhartyml/fluhartyml.github.io",
        cloneUrl: "https://github.com/fluhartyml/fluhartyml.github.io.git",
        sshUrl: "git@github.com:fluhartyml/fluhartyml.github.io.git",
        homepage: "https://fluhartyml.github.io",
        language: "Swift",
        forksCount: 0,
        stargazersCount: 5,
        watchersCount: 1,
        size: 1024,
        defaultBranch: "main",
        openIssuesCount: 2,
        isPrivate: false,
        isFork: false,
        isArchived: false,
        hasWiki: true,
        hasPages: true,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date().addingTimeInterval(-86400 * 2),
        pushedAt: Date().addingTimeInterval(-86400)
    )
    
    static let mockList = [
        mock,
        Repository(
            id: 2,
            name: "Git-Blogger",
            fullName: "fluhartyml/Git-Blogger",
            description: "macOS app for managing GitHub repositories and blogging",
            htmlUrl: "https://github.com/fluhartyml/Git-Blogger",
            cloneUrl: "https://github.com/fluhartyml/Git-Blogger.git",
            sshUrl: "git@github.com:fluhartyml/Git-Blogger.git",
            homepage: nil,
            language: "Swift",
            forksCount: 0,
            stargazersCount: 0,
            watchersCount: 0,
            size: 256,
            defaultBranch: "main",
            openIssuesCount: 0,
            isPrivate: false,
            isFork: false,
            isArchived: false,
            hasWiki: false,
            hasPages: false,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            updatedAt: Date(),
            pushedAt: Date()
        )
    ]
}

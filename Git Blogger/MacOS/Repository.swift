//
//  Repository.swift
//  Git Blogger
//
//  GitHub repository data model
//

import Foundation

struct Repository: Codable, Identifiable {
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
    let `private`: Bool
    let fork: Bool
    let archived: Bool
    let hasWiki: Bool
    let hasPages: Bool
    let createdAt: Date
    let updatedAt: Date
    let pushedAt: Date?
    
    var url: URL? {
        URL(string: htmlUrl)
    }
    
    var displayName: String {
        name.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    var isPrivate: Bool { `private` }
    var isFork: Bool { fork }
    var isArchived: Bool { archived }
    
    var lastActivity: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Mock Data for Development

extension Repository {
    static var mock: [Repository] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            Repository(
                id: 1,
                name: "fluhartyml.github.io",
                fullName: "fluhartyml/fluhartyml.github.io",
                description: "Personal portfolio and blog",
                htmlUrl: "https://github.com/fluhartyml/fluhartyml.github.io",
                cloneUrl: "https://github.com/fluhartyml/fluhartyml.github.io.git",
                sshUrl: "git@github.com:fluhartyml/fluhartyml.github.io.git",
                homepage: "https://fluhartyml.github.io",
                language: "HTML",
                forksCount: 0,
                stargazersCount: 5,
                watchersCount: 1,
                size: 1024,
                defaultBranch: "main",
                openIssuesCount: 0,
                `private`: false,
                fork: false,
                archived: false,
                hasWiki: true,
                hasPages: true,
                createdAt: calendar.date(byAdding: .year, value: -2, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                pushedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            Repository(
                id: 2,
                name: "Git-Blogger",
                fullName: "fluhartyml/Git-Blogger",
                description: "Personal blogging app with GitHub integration",
                htmlUrl: "https://github.com/fluhartyml/Git-Blogger",
                cloneUrl: "https://github.com/fluhartyml/Git-Blogger.git",
                sshUrl: "git@github.com:fluhartyml/Git-Blogger.git",
                homepage: nil,
                language: "Swift",
                forksCount: 0,
                stargazersCount: 2,
                watchersCount: 1,
                size: 512,
                defaultBranch: "main",
                openIssuesCount: 3,
                `private`: false,
                fork: false,
                archived: false,
                hasWiki: false,
                hasPages: false,
                createdAt: calendar.date(byAdding: .month, value: -1, to: now)!,
                updatedAt: now,
                pushedAt: now
            ),
            Repository(
                id: 3,
                name: "InkwellBinary",
                fullName: "fluhartyml/InkwellBinary",
                description: "Binary clock iOS app",
                htmlUrl: "https://github.com/fluhartyml/InkwellBinary",
                cloneUrl: "https://github.com/fluhartyml/InkwellBinary.git",
                sshUrl: "git@github.com:fluhartyml/InkwellBinary.git",
                homepage: nil,
                language: "Swift",
                forksCount: 0,
                stargazersCount: 8,
                watchersCount: 2,
                size: 2048,
                defaultBranch: "main",
                openIssuesCount: 1,
                `private`: false,
                fork: false,
                archived: false,
                hasWiki: false,
                hasPages: false,
                createdAt: calendar.date(byAdding: .month, value: -6, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -7, to: now)!,
                pushedAt: calendar.date(byAdding: .day, value: -7, to: now)!
            )
        ]
    }
}

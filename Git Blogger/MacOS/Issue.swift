//
//  Issue.swift
//  Git Blogger
//
//  GitHub issue data model for blog posts and project tracking
//

import Foundation

struct Issue: Codable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let htmlUrl: String
    let user: User
    let labels: [Label]
    let assignees: [User]
    let milestone: Milestone?
    let comments: Int
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    
    struct User: Codable {
        let login: String
        let id: Int
        let avatarUrl: String
        let htmlUrl: String
    }
    
    struct Label: Codable, Identifiable {
        let id: Int
        let name: String
        let color: String
        let description: String?
        
        var displayColor: String {
            "#\(color)"
        }
    }
    
    struct Milestone: Codable {
        let id: Int
        let title: String
        let description: String?
        let state: String
        let dueOn: Date?
    }
    
    var isOpen: Bool {
        state == "open"
    }
    
    var isClosed: Bool {
        state == "closed"
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
    
    var labelNames: [String] {
        labels.map { $0.name }
    }
    
    var hasLabels: Bool {
        !labels.isEmpty
    }
    
    var statusEmoji: String {
        isOpen ? "🟢" : "🔴"
    }
    
    var url: URL? {
        URL(string: htmlUrl)
    }
}

// MARK: - Mock Data for Development

extension Issue {
    static var mock: [Issue] {
        let now = Date()
        let calendar = Calendar.current
        
        let mockUser = User(
            login: "fluhartyml",
            id: 961824,
            avatarUrl: "https://avatars.githubusercontent.com/u/961824?v=4",
            htmlUrl: "https://github.com/fluhartyml"
        )
        
        let blogLabel = Label(
            id: 1,
            name: "blog",
            color: "0075ca",
            description: "Blog post"
        )
        
        let enhancementLabel = Label(
            id: 2,
            name: "enhancement",
            color: "a2eeef",
            description: "New feature or request"
        )
        
        return [
            Issue(
                id: 1,
                number: 1,
                title: "Tally Matrix Clock",
                body: "This actual project took less than a day from initial Xcode project creation, git integration to App Store Connect submission...",
                state: "open",
                htmlUrl: "https://github.com/fluhartyml/TallyMatrices/issues/1",
                user: mockUser,
                labels: [blogLabel],
                assignees: [],
                milestone: nil,
                comments: 0,
                createdAt: calendar.date(byAdding: .hour, value: -19, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -19, to: now)!,
                closedAt: nil
            ),
            Issue(
                id: 2,
                number: 2,
                title: "First blog post",
                body: "This is an issue to make my first blog post",
                state: "open",
                htmlUrl: "https://github.com/fluhartyml/fluhartyml.github.io/issues/2",
                user: mockUser,
                labels: [blogLabel],
                assignees: [],
                milestone: nil,
                comments: 0,
                createdAt: calendar.date(byAdding: .hour, value: -20, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -20, to: now)!,
                closedAt: nil
            ),
            Issue(
                id: 3,
                number: 5,
                title: "Add clone repository feature",
                body: "Users should be able to clone repositories to their local machine",
                state: "closed",
                htmlUrl: "https://github.com/fluhartyml/Git-Blogger/issues/5",
                user: mockUser,
                labels: [enhancementLabel],
                assignees: [mockUser],
                milestone: nil,
                comments: 2,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -2, to: now)!,
                closedAt: calendar.date(byAdding: .hour, value: -2, to: now)!
            )
        ]
    }
}

//
//  Issue.swift
//  Git Blogger
//
//  GitHub issue data model
//

import Foundation

struct Issue: Codable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let htmlUrl: String
    let user: IssueUser
    let labels: [IssueLabel]
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    let comments: Int
    
    var url: URL? {
        URL(string: htmlUrl)
    }
    
    var isOpen: Bool {
        state == "open"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case body
        case state
        case htmlUrl = "html_url"
        case user
        case labels
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
        case comments
    }
}

struct IssueUser: Codable, Hashable {
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

struct IssueLabel: Codable, Hashable {
    let name: String
    let color: String
}

// Mock data for previews
extension Issue {
    static let mock = Issue(
        id: 1,
        number: 1,
        title: "Add dark mode support",
        body: "It would be great to have dark mode support for better nighttime viewing.",
        state: "open",
        htmlUrl: "https://github.com/fluhartyml/fluhartyml.github.io/issues/1",
        user: IssueUser(login: "fluhartyml", avatarUrl: "https://avatars.githubusercontent.com/u/961824"),
        labels: [
            IssueLabel(name: "enhancement", color: "a2eeef"),
            IssueLabel(name: "good first issue", color: "7057ff")
        ],
        createdAt: Date().addingTimeInterval(-86400 * 7),
        updatedAt: Date().addingTimeInterval(-86400 * 2),
        closedAt: nil,
        comments: 3
    )
    
    static let mockClosed = Issue(
        id: 2,
        number: 2,
        title: "Fix broken link on about page",
        body: "The contact link returns a 404 error.",
        state: "closed",
        htmlUrl: "https://github.com/fluhartyml/fluhartyml.github.io/issues/2",
        user: IssueUser(login: "contributor", avatarUrl: "https://avatars.githubusercontent.com/u/1"),
        labels: [IssueLabel(name: "bug", color: "d73a4a")],
        createdAt: Date().addingTimeInterval(-86400 * 14),
        updatedAt: Date().addingTimeInterval(-86400 * 10),
        closedAt: Date().addingTimeInterval(-86400 * 10),
        comments: 1
    )
}

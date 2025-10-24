//
//  Issue.swift
//  Git Blogger
//
//  GitHub issue data model with local QA tracking
//  Last Updated: 2025 OCT 24 1045
//

import Foundation
import SwiftUI

struct Issue: Codable, Identifiable, Hashable {
    // GitHub data
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
    
    // Local tracking data
    var privateNotes: String?
    var isArchived: Bool
    var manualStatus: String?
    
    var url: URL? {
        URL(string: htmlUrl)
    }
    
    var isOpen: Bool {
        state == "open"
    }
    
    var isClosed: Bool {
        state == "closed"
    }
    
    // Priority color logic
    var priorityColor: Color {
        // If manual status mode is being used, return that
        if let manual = manualStatus {
            switch manual {
            case "red": return .red
            case "yellow": return .yellow
            case "lightGreen": return .green
            case "darkGreen": return Color(red: 0, green: 0.5, blue: 0)
            default: break
            }
        }
        
        // Automatic color logic (GitHub is source of truth)
        if isArchived {
            return Color(red: 0, green: 0.5, blue: 0) // Dark green
        }
        
        if isClosed {
            return .green // Light green
        }
        
        if isOpen {
            if comments == 0 {
                return .red // No comments yet
            } else {
                return .yellow // Has comments
            }
        }
        
        return .gray // Fallback
    }
    
    var priorityLevel: Int {
        switch priorityColor {
        case .red: return 0 // Highest priority
        case .yellow: return 1
        case .green: return 2
        case Color(red: 0, green: 0.5, blue: 0): return 3 // Dark green lowest
        default: return 4
        }
    }
    
    var textColor: Color {
        // Return contrasting text color for each background
        switch priorityColor {
        case .red: return .white
        case .yellow: return .black
        case .green: return .black
        case Color(red: 0, green: 0.5, blue: 0): return .white // Dark green
        default: return .black
        }
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
        case privateNotes
        case isArchived
        case manualStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        state = try container.decode(String.self, forKey: .state)
        htmlUrl = try container.decode(String.self, forKey: .htmlUrl)
        user = try container.decode(IssueUser.self, forKey: .user)
        labels = try container.decode([IssueLabel].self, forKey: .labels)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        closedAt = try container.decodeIfPresent(Date.self, forKey: .closedAt)
        comments = try container.decode(Int.self, forKey: .comments)
        
        // Local data - use defaults if not present
        privateNotes = try container.decodeIfPresent(String.self, forKey: .privateNotes)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        manualStatus = try container.decodeIfPresent(String.self, forKey: .manualStatus)
    }
    
    init(id: Int, number: Int, title: String, body: String?, state: String, htmlUrl: String, user: IssueUser, labels: [IssueLabel], createdAt: Date, updatedAt: Date, closedAt: Date?, comments: Int, privateNotes: String? = nil, isArchived: Bool = false, manualStatus: String? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.body = body
        self.state = state
        self.htmlUrl = htmlUrl
        self.user = user
        self.labels = labels
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.closedAt = closedAt
        self.comments = comments
        self.privateNotes = privateNotes
        self.isArchived = isArchived
        self.manualStatus = manualStatus
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

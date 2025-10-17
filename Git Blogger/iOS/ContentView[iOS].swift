//
//  ContentView[iOS].swift
//  Git Blogger (iOS)
//
//  Main interface for iPhone - Lightweight blog posting
//

import SwiftUI
import SwiftData

#if os(iOS)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var showingNewPost = false
    
    var body: some View {
        NavigationStack {
            List {
                // Quick Actions
                Section {
                    Button(action: { showingNewPost = true }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text("New Blog Post")
                                    .font(.headline)
                                Text("Create and publish")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Recent Posts
                Section("Recent Posts") {
                    ForEach(items) { item in
                        NavigationLink {
                            PostDetailView(item: item)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Blog Post Title")
                                        .font(.headline)
                                    
                                    Text("Draft • \(item.timestamp, format: .relative(presentation: .named))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                
                // Blogs Section
                Section("My Blogs") {
                    Label("Personal Blog", systemImage: "person.circle")
                    Label("Business Blog", systemImage: "briefcase")
                    Label("Portfolio Blog", systemImage: "folder")
                }
                
                // Settings
                Section {
                    NavigationLink {
                        Text("Settings View")
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Git Blogger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// Placeholder for post detail view
struct PostDetailView: View {
    let item: Item
    
    var body: some View {
        VStack(spacing: 20) {
            Text("📝")
                .font(.system(size: 60))
            
            Text("Post Editor")
                .font(.title)
            
            Text("Rich text editor with photo picker")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Publish") {
                // Publish action
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Edit Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Placeholder for new post view
struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("✏️")
                    .font(.system(size: 60))
                
                Text("New Blog Post")
                    .font(.title)
                
                Text("Editor interface coming soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
#endif

//
//  ContentView[macOS].swift
//  Git Blogger (macOS)
//
//  Main interface for macOS - Full GitHub account management
//

import SwiftUI
import SwiftData

#if os(macOS)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR - Repository and content browser
            List {
                Section("GitHub Repositories") {
                    Label("fluhartyml.github.io", systemImage: "folder")
                    Label("Git-Blogger", systemImage: "folder")
                    Label("InkwellBinary", systemImage: "folder")
                    Label("NiteGard", systemImage: "folder")
                }
                
                Section("Blog Posts") {
                    Label("My First Post", systemImage: "doc.text")
                    Label("Another Post", systemImage: "doc.text")
                    Label("Draft Post", systemImage: "doc.text.fill")
                }
                
                Section("Wiki Pages") {
                    Label("Home", systemImage: "book")
                    Label("Project Identity", systemImage: "book")
                    Label("EULA", systemImage: "book")
                }
                
                Section("Portfolio") {
                    Label("Projects", systemImage: "square.grid.2x2")
                    Label("Timeline", systemImage: "clock")
                }
            }
            .navigationTitle("Git Blogger")
            .toolbar {
                ToolbarItem {
                    Button(action: {}) {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("New Post", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // MAIN CONTENT AREA - Editor and preview
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text("📝 Blog Post Editor")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Label("Preview", systemImage: "eye")
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // Editor area placeholder
                VStack {
                    Text("Rich Text Editor")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("WYSIWYG editor will go here")
                        .foregroundColor(.secondary)
                    
                    Text("With inline photo picker")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
                
                Divider()
                
                // Bottom toolbar
                HStack {
                    Button(action: {}) {
                        Label("Add Photo", systemImage: "photo")
                    }
                    
                    Button(action: {}) {
                        Label("Add Tag", systemImage: "tag")
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Label("Save Draft", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: {}) {
                        Label("Publish", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .frame(width: 1200, height: 800)
}
#endif

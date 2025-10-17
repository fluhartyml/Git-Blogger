//
//  EditorView[macOS].swift
//  Portable WYSIWYG Markdown Editor
//
//  Reusable rich text editor with image support and native macOS gestures
//  Last Updated: 2025 OCT 17 1612
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

#if os(macOS)
struct EditorView: View {
    @Binding var content: String
    var allowImages: Bool = true
    var onImageUpload: ((NSImage) -> String?)? = nil
    var onSave: ((String) -> Void)? = nil
    
    @State private var showingImagePicker = false
    @State private var attributedText: NSAttributedString
    @FocusState private var isFocused: Bool
    
    init(
        content: Binding<String>,
        allowImages: Bool = true,
        onImageUpload: ((NSImage) -> String?)? = nil,
        onSave: ((String) -> Void)? = nil
    ) {
        self._content = content
        self.allowImages = allowImages
        self.onImageUpload = onImageUpload
        self.onSave = onSave
        
        // Initialize attributed text from Markdown
        let parser = MarkdownParser()
        self._attributedText = State(initialValue: parser.parse(content.wrappedValue))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 16) {
                Button(action: { toggleBold() }) {
                    Image(systemName: "bold")
                }
                .help("Bold")
                
                Button(action: { toggleItalic() }) {
                    Image(systemName: "italic")
                }
                .help("Italic")
                
                Divider()
                    .frame(height: 20)
                
                Button(action: { insertHeading() }) {
                    Image(systemName: "textformat.size")
                }
                .help("Heading")
                
                Button(action: { insertBulletList() }) {
                    Image(systemName: "list.bullet")
                }
                .help("Bullet List")
                
                Button(action: { insertNumberedList() }) {
                    Image(systemName: "list.number")
                }
                .help("Numbered List")
                
                if allowImages {
                    Divider()
                        .frame(height: 20)
                    
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "photo")
                    }
                    .help("Insert Image")
                }
                
                Spacer()
                
                if let onSave = onSave {
                    Button(action: {
                        syncContentFromEditor()
                        onSave(content)
                    }) {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Editor
            RichTextEditor(
                attributedText: $attributedText,
                onTextChange: { syncContentFromEditor() }
            )
            .focused($isFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onInsert: { imageURL in
                insertImage(url: imageURL)
            }, onUpload: onImageUpload)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    // MARK: - Formatting Actions
    
    private func toggleBold() {
        // TODO: Implement bold toggle
    }
    
    private func toggleItalic() {
        // TODO: Implement italic toggle
    }
    
    private func insertHeading() {
        // TODO: Implement heading insertion
    }
    
    private func insertBulletList() {
        // TODO: Implement bullet list
    }
    
    private func insertNumberedList() {
        // TODO: Implement numbered list
    }
    
    private func insertImage(url: String) {
        // Insert image into editor
        let imageMarkdown = "![image](\(url))"
        content += "\n\(imageMarkdown)\n"
        
        // Re-parse and update attributed text
        let parser = MarkdownParser()
        attributedText = parser.parse(content)
    }
    
    private func syncContentFromEditor() {
        // Convert attributed text back to Markdown
        let converter = MarkdownConverter()
        content = converter.toMarkdown(attributedText)
    }
}

// MARK: - RichTextEditor (NSTextView Wrapper)

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var onTextChange: () -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsImageEditing = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        
        // Pinch-to-zoom works automatically on macOS with trackpad/Magic Mouse
        // No need to enable anything - it's built into the OS
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
            parent.onTextChange()
        }
    }
}

// MARK: - ImagePickerView

struct ImagePickerView: View {
    let onInsert: (String) -> Void
    let onUpload: ((NSImage) -> String?)?
    
    @State private var imageURL: String = ""
    @State private var selectedImage: NSImage?
    @State private var showingFilePicker = false
    @State private var isUploading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Insert Image")
                .font(.headline)
            
            TabView {
                // URL Tab
                VStack(spacing: 16) {
                    TextField("Paste image URL", text: $imageURL)
                        .textFieldStyle(.roundedBorder)
                    
                    if let url = URL(string: imageURL), !imageURL.isEmpty {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        
                        Button("Insert") {
                            onInsert(imageURL)
                            dismiss()
                        }
                        .disabled(imageURL.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .tabItem {
                    Label("URL", systemImage: "link")
                }
                
                // Upload Tab
                VStack(spacing: 16) {
                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Button("Choose Image") {
                                showingFilePicker = true
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    if isUploading {
                        ProgressView("Uploading...")
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        
                        Button("Upload & Insert") {
                            uploadAndInsert()
                        }
                        .disabled(selectedImage == nil || isUploading)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .tabItem {
                    Label("Upload", systemImage: "arrow.up.circle")
                }
                .disabled(onUpload == nil)
            }
        }
        .frame(width: 500, height: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first,
              let image = NSImage(contentsOf: url) else {
            return
        }
        selectedImage = image
    }
    
    private func uploadAndInsert() {
        guard let image = selectedImage,
              let onUpload = onUpload else { return }
        
        isUploading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let uploadedURL = onUpload(image) {
                DispatchQueue.main.async {
                    onInsert(uploadedURL)
                    dismiss()
                }
            }
            
            DispatchQueue.main.async {
                isUploading = false
            }
        }
    }
}

// MARK: - Markdown Parser & Converter

class MarkdownParser {
    func parse(_ markdown: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: markdown)
        
        // Basic font
        attributed.addAttribute(
            .font,
            value: NSFont.systemFont(ofSize: 14),
            range: NSRange(location: 0, length: attributed.length)
        )
        
        // Parse images: ![alt](url)
        let imagePattern = "!\\[([^\\]]*)\\]\\(([^\\)]*)\\)"
        if let regex = try? NSRegularExpression(pattern: imagePattern) {
            let matches = regex.matches(
                in: markdown,
                range: NSRange(location: 0, length: markdown.utf16.count)
            )
            
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    let urlRange = match.range(at: 2)
                    if let urlSwiftRange = Range(urlRange, in: markdown) {
                        let urlString = String(markdown[urlSwiftRange])
                        
                        // Create image attachment
                        if let url = URL(string: urlString),
                           let imageData = try? Data(contentsOf: url),
                           let image = NSImage(data: imageData) {
                            
                            let attachment = NSTextAttachment()
                            attachment.image = image
                            
                            // Scale image to fit
                            let maxWidth: CGFloat = 600
                            if image.size.width > maxWidth {
                                let scale = maxWidth / image.size.width
                                attachment.bounds = CGRect(
                                    x: 0,
                                    y: 0,
                                    width: image.size.width * scale,
                                    height: image.size.height * scale
                                )
                            }
                            
                            let imageString = NSAttributedString(attachment: attachment)
                            attributed.replaceCharacters(in: match.range, with: imageString)
                        }
                    }
                }
            }
        }
        
        return attributed
    }
}

class MarkdownConverter {
    func toMarkdown(_ attributed: NSAttributedString) -> String {
        var markdown = ""
        let string = attributed.string
        
        attributed.enumerateAttributes(
            in: NSRange(location: 0, length: attributed.length),
            options: []
        ) { attributes, range, _ in
            
            if let attachment = attributes[.attachment] as? NSTextAttachment,
               let _ = attachment.image {
                // Handle image attachments
                // For now, preserve existing markdown
                markdown += "![image](url)"
            } else {
                let substring = (string as NSString).substring(with: range)
                markdown += substring
            }
        }
        
        return markdown
    }
}

// MARK: - Preview

#Preview {
    EditorView(
        content: .constant("# Hello World\n\nThis is a **bold** test.\n\n![image](https://via.placeholder.com/300)"),
        allowImages: true,
        onImageUpload: { image in
            // Mock upload
            return "https://via.placeholder.com/300"
        },
        onSave: { markdown in
            print("Saved: \(markdown)")
        }
    )
    .frame(width: 800, height: 600)
}
#endif

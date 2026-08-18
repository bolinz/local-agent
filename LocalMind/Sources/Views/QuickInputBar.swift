import SwiftUI
import PhotosUI

struct QuickInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    var onAddAttachment: ((MessageAttachment) -> Void)? = nil
    @State private var pendingAttachments: [MessageAttachment] = []
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoadingAttachment = false

    var body: some View {
        VStack(spacing: 6) {
            if !pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(pendingAttachments) { att in
                            AttachmentPreviewChip(attachment: att) {
                                pendingAttachments.removeAll { $0.id == att.id }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            HStack(spacing: 8) {
                #if canImport(UIKit)
                Menu {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("图片", systemImage: "photo")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("文件", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.indigo)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.indigo.opacity(0.1)))
                }
                .accessibilityLabel("添加附件")
                #endif

                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: 34, maxHeight: 100)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    #if canImport(UIKit)
                    .scrollContentBackground(.hidden)
                    #endif
                    .background(Color.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityLabel("输入消息...")
                    .accessibilityIdentifier("输入消息...")

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Group {
                                if text.isEmpty && pendingAttachments.isEmpty {
                                    Circle().fill(Color.disabledGray)
                                } else {
                                    Circle().fill(LinearGradient(colors: [.indigo, .purple, .pink],
                                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                            }
                        )
                        .shadow(color: (text.isEmpty && pendingAttachments.isEmpty) ? .clear : Color.purple.opacity(0.4), radius: 6, y: 3)
                        .clipShape(Circle())
                }
                .accessibilityLabel("发送")
                .disabled(text.isEmpty && pendingAttachments.isEmpty || isLoadingAttachment)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        #if canImport(UIKit)
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .plainText, .image]) { result in
            handleFileImport(result)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            loadPhoto(newItem)
            selectedPhoto = nil
        }
        #endif
    }

    private func send() {
        guard !text.isEmpty || !pendingAttachments.isEmpty else { return }
        guard !isLoadingAttachment else { return }
        for att in pendingAttachments {
            onAddAttachment?(att)
        }
        pendingAttachments.removeAll()
        onSend()
    }

    #if canImport(UIKit)
    private func loadPhoto(_ item: PhotosPickerItem) {
        isLoadingAttachment = true
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let name = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
                if let savedURL = AttachmentStore.shared.save(data: data, name: name) {
                    pendingAttachments.append(MessageAttachment(type: .image, name: name, localURL: savedURL, mimeType: "image/jpeg"))
                }
            }
            isLoadingAttachment = false
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let name = url.lastPathComponent
        guard let savedURL = AttachmentStore.shared.save(data: data, name: name) else { return }
        pendingAttachments.append(MessageAttachment(type: .file, name: name, localURL: savedURL, mimeType: "application/octet-stream"))
    }
    #endif
}

struct AttachmentPreviewChip: View {
    let attachment: MessageAttachment
    let onRemove: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: attachment.type == .image ? "photo" : "doc")
                .font(.caption2)
            Text(attachment.name)
                .font(.caption2)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.secondary.opacity(0.12)))
    }
}

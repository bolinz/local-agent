import SwiftUI

struct AttachmentBubbleView: View {
    let attachment: MessageAttachment

    var body: some View {
        #if canImport(UIKit)
        UIKitBody()
        #else
        FileCard()
        #endif
    }

    #if canImport(UIKit)
    private func UIKitBody() -> some View {
        UIKitImageView(attachment: attachment)
    }
    #endif

    private func FileCard() -> some View {
        HStack(spacing: 8) {
            Image(systemName: attachment.type == .image ? "photo" : "doc.fill")
                .font(.title3)
                .foregroundColor(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(NSLocalizedString("attachment", comment: ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.1)))
    }
}

#if canImport(UIKit)
private struct UIKitImageView: View {
    let attachment: MessageAttachment
    @State private var image: UIImage?

    var body: some View {
        Group {
            if attachment.type == .image, let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                fileCard
            }
        }
        .onAppear { loadImage() }
    }

    private var fileCard: some View {
        HStack(spacing: 8) {
            Image(systemName: attachment.type == .image ? "photo" : "doc.fill")
                .font(.title3)
                .foregroundColor(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(NSLocalizedString("attachment", comment: ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.1)))
    }

    private func loadImage() {
        guard attachment.type == .image, let url = AttachmentStore.shared.fileURL(for: attachment.localURL) else { return }
        image = UIImage(contentsOfFile: url.path)
    }
}
#endif

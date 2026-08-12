import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                userBubble
            } else {
                assistantBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.leading, 60)
    }
    
    private var assistantBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "brain")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                if let speed = message.speed {
                    Text(String(format: "%.1f tok/s", speed))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.trailing, 60)
    }
}

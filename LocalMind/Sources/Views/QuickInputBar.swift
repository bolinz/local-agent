import SwiftUI

struct QuickInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14, weight: .medium))
                
                TextField("输入消息...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .submitLabel(.send)
                    .onSubmit { onSend() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(text.isEmpty ? Color.disabledGray : .white)
                    .frame(width: 32, height: 32)
                    .background(text.isEmpty ? Color.inputFieldBackground : Color.accentColor)
                    .clipShape(Circle())
            }
            .accessibilityLabel("发送")
            .disabled(text.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

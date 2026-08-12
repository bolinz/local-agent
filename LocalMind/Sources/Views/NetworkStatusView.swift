import SwiftUI

struct NetworkStatusView: View {
    @State private var isConnected = true
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "在线" : "离线")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
    }
}

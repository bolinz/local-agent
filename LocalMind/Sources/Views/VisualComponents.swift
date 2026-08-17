import SwiftUI

// MARK: - 渐变圆角图标（通用）

struct GradientIconView: View {
    let icon: String
    let gradient: [Color]
    let size: CGFloat

    init(icon: String, gradient: [Color] = [Color.indigo, Color.purple], size: CGFloat = 36) {
        self.icon = icon
        self.gradient = gradient
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 8, y: 4)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundColor(.white)
                .accessibilityHidden(true)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 发光状态胶囊

struct GlowPillView: View {
    let text: String
    var isActive = true
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: (isActive ? Color.green : Color.red).opacity(0.8), radius: 4)
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.green.opacity(isActive ? 0.12 : 0)))
        .foregroundColor(isActive ? Color.green : Color.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

// MARK: - 思考过程卡片

struct ThinkingCardView: View {
    let steps: [ThinkingStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [.indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 12, height: 12)
                Text("Agent 思考中")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
            }
            ForEach(steps) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step.state.backgroundColor)
                            .frame(width: 16, height: 16)
                        Text(step.state.symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(step.state.foregroundColor)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(step.state.accessibilityText)
                    Text(step.label)
                        .font(.caption)
                        .foregroundColor(step.state == .active ? .primary : .secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}

struct ThinkingStep: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let state: StepState

    enum StepState: Equatable {
        case done, active, pending
        var symbol: String {
            switch self {
            case .done: return "✓"
            case .active: return "●"
            case .pending: return ""
            }
        }
        var backgroundColor: Color {
            switch self {
            case .done: return Color.green.opacity(0.15)
            case .active: return Color.yellow.opacity(0.15)
            case .pending: return Color.secondary.opacity(0.1)
            }
        }
        var foregroundColor: Color {
            switch self {
            case .done: return .green
            case .active: return .yellow
            case .pending: return .clear
            }
        }
        var accessibilityText: String {
            switch self {
            case .done: return "完成"
            case .active: return "进行中"
            case .pending: return "等待中"
            }
        }
    }
}

// MARK: - 工具调用卡片

struct ToolCallCardView: View {
    let toolName: String
    let params: String
    let result: String
    var isSuccess = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption)
                    Text(toolName)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.indigo)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(params)
                .font(.caption2)
                .monospaced()
                .foregroundColor(.secondary)
            Label(result, systemImage: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption2)
                .foregroundColor(isSuccess ? .green : .red)
                .accessibilityLabel("\(result)，\(isSuccess ? "成功" : "失败")")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.indigo.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.indigo.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - 上下文记忆胶囊条

struct MemoryStripView: View {
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                            Text(item)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.indigo.opacity(0.12)))
                        .foregroundColor(.indigo)
                    }
                }
            }
        }
    }
}

// MARK: - 渐变对话气泡

struct UserBubbleView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LinearGradient(colors: [Color.indigo, Color(red: 0.44, green: 0.24, blue: 0.93)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.indigo.opacity(0.3), radius: 8, y: 4)
    }
}
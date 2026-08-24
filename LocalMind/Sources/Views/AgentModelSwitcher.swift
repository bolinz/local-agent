import SwiftUI

struct AgentModelSwitcher: View {
    @Binding var agentID: UUID?
    @Binding var modelSelection: ModelSelection?
    @State private var agents: [AgentProfile] = AgentStore.shared.loadAgents()
    @State private var showAgentPicker = false
    @State private var showModelPicker = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showAgentPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text(currentAgentName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.indigo.opacity(0.12)))
                .foregroundColor(.indigo)
            }
            .accessibilityLabel("切换 Agent")
            .sheet(isPresented: $showAgentPicker) {
                AgentPickerSheet(agents: agents, selectedID: agentID) { id in
                    agentID = id
                    AgentStore.shared.setCurrent(id)
                    let agent = agents.first { $0.id == id }
                    modelSelection = agent?.selectedModel
                }
            }

            Button {
                showModelPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text(modelSelection.map { ModelRouter().describe(selection: $0) } ?? "本地默认")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.indigo.opacity(0.12)))
                .foregroundColor(.indigo)
            }
            .accessibilityLabel("切换模型")
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheet(selection: $modelSelection)
            }
        }
    }

    private var currentAgentName: String {
        agents.first { $0.id == agentID }?.name ?? "通用助手"
    }
}

struct AgentPickerSheet: View {
    let agents: [AgentProfile]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(agents) { agent in
                Button {
                    onSelect(agent.id)
                    dismiss()
                } label: {
                    HStack {
                        Text(agent.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if agent.id == selectedID {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("选择 Agent")
        }
    }
}

struct ModelPickerSheet: View {
    @Binding var selection: ModelSelection?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("本地模型") {
                    ForEach(ModelType.allCases, id: \.rawValue) { model in
                        Button {
                            selection = .local(model)
                            dismiss()
                        } label: {
                            HStack {
                                Text(model.displayName)
                                Spacer()
                                if case .local(model) = selection {
                                    Image(systemName: "checkmark").foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                Section("外部 API") {
                    ForEach(ModelConfigStore.shared.loadProviders()) { provider in
                        Button {
                            selection = .remote(providerID: provider.id)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(provider.name) · \(provider.modelName)")
                                Spacer()
                                if case .remote(let pid) = selection, pid == provider.id {
                                    Image(systemName: "checkmark").foregroundColor(.green)
                                }
                            }
                        }
                    }
                    if ModelConfigStore.shared.loadProviders().isEmpty {
                        Text("尚无外部模型，请先在模型管理中添加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择模型")
        }
    }
}

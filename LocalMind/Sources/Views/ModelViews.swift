import SwiftUI

struct ModelListView: View {
    @State private var providers: [ModelProvider] = ModelConfigStore.shared.loadProviders()
    @State private var showAdd = false
    @State private var testResults: [UUID: Bool] = [:]
    @State private var testingID: UUID?

    var body: some View {
        List {
            Section("本地模型") {
                ForEach(ModelType.allCases, id: \.rawValue) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                                .font(.subheadline)
                            Text(String(format: "%.1f GB", model.sizeInGB))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("未下载")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section("外部 API") {
                ForEach(providers) { provider in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(provider.modelName) · \(provider.baseURL)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let result = testResults[provider.id] {
                                Text(result ? "连接成功" : "连接失败")
                                    .font(.caption2)
                                    .foregroundColor(result ? .green : .red)
                            }
                        }
                        Spacer()
                        if testingID == provider.id {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("测试") {
                                testingID = provider.id
                                Task {
                                    let ok = await ModelRouter().testConnection(provider)
                                    testResults[provider.id] = ok
                                    testingID = nil
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        ModelConfigStore.shared.deleteProvider(providers[index].id)
                    }
                    providers = ModelConfigStore.shared.loadProviders()
                }
            }
            Section {
                Button {
                    showAdd = true
                } label: {
                    Label("添加外部模型", systemImage: "plus")
                        .foregroundColor(.indigo)
                }
            }
        }
        .navigationTitle("模型管理")
        .sheet(isPresented: $showAdd) {
            ProviderFormView { provider in
                ModelConfigStore.shared.addProvider(provider)
                providers = ModelConfigStore.shared.loadProviders()
            }
        }
    }
}

struct ProviderFormView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ModelProvider) -> Void
    @State private var template: ProviderTemplate = .openAI
    @State private var name = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var modelName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    Picker("Provider", selection: $template) {
                        Text("OpenAI").tag(ProviderTemplate.openAI)
                        Text("Anthropic").tag(ProviderTemplate.anthropic)
                        Text("Gemini").tag(ProviderTemplate.gemini)
                        Text("DeepSeek").tag(ProviderTemplate.deepSeek)
                        Text("自定义").tag(ProviderTemplate.custom)
                    }
                    .onChange(of: template) { _, newValue in
                        if baseURL.isEmpty, let url = newValue.baseURL {
                            baseURL = url
                        }
                        if modelName.isEmpty {
                            modelName = newValue.defaultModelName
                        }
                    }
                }
                Section("配置") {
                    TextField("名称", text: $name)
                    TextField("Base URL", text: $baseURL)
                        #if canImport(UIKit)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                    SecureField("API Key", text: $apiKey)
                    TextField("模型名", text: $modelName)
                        #if canImport(UIKit)
                        .autocapitalization(.none)
                        #endif
                }
            }
            .navigationTitle("添加外部模型")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let finalName = name.isEmpty ? (template == .custom ? "自定义" : "\(templateName(template))") : name
                        onSave(ModelProvider(name: finalName, template: template,
                                             baseURL: baseURL, apiKey: apiKey, modelName: modelName))
                        dismiss()
                    }
                    .disabled(baseURL.isEmpty || modelName.isEmpty)
                }
            }
        }
    }

    func templateName(_ t: ProviderTemplate) -> String {
        switch t {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Gemini"
        case .deepSeek: return "DeepSeek"
        case .custom: return "自定义"
        }
    }
}

struct ModelPickerView: View {
    @Binding var selection: ModelSelection?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
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
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
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
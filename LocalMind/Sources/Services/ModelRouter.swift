import Foundation

struct ModelRouter {
    func describe(selection: ModelSelection) -> String {
        switch selection {
        case .local(let model):
            return model.displayName
        case .remote(let providerID):
            let provider = ModelConfigStore.shared.loadProviders().first { $0.id == providerID }
            return provider.map { "\($0.name) · \($0.modelName)" } ?? "外部模型"
        }
    }

    func testConnection(_ provider: ModelProvider) async -> Bool {
        guard !provider.baseURL.isEmpty, !provider.apiKey.isEmpty else { return false }
        let url = URL(string: "\(provider.baseURL)/models")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
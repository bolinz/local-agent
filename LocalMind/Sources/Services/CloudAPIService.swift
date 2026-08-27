import Foundation

enum CloudAPIError: LocalizedError {
    case noProvider
    case invalidURL
    case requestFailed(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noProvider: return "未配置外部模型"
        case .invalidURL: return "API 地址无效"
        case .requestFailed(let error): return "请求失败：\(error.localizedDescription)"
        case .invalidResponse: return "响应格式无效"
        }
    }
}

class CloudAPIService {
    static let shared = CloudAPIService()

    private let configStore: ModelConfigStore
    private let session: URLSession

    init(configStore: ModelConfigStore = .shared, session: URLSession = .shared) {
        self.configStore = configStore
        self.session = session
    }

    /// 调用外部 API 生成回复（OpenAI 兼容格式）
    func generateCompletion(
        messages: [(role: String, content: String)],
        providerID: UUID
    ) async throws -> String {
        let providers = configStore.loadProviders()
        guard let provider = providers.first(where: { $0.id == providerID }) else {
            throw CloudAPIError.noProvider
        }

        guard let baseURL = URL(string: provider.baseURL) else {
            throw CloudAPIError.invalidURL
        }

        let url = baseURL.appendingPathComponent("chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": provider.modelName,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": 2048,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CloudAPIError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw CloudAPIError.invalidResponse
        }

        return content
    }
}

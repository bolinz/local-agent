import XCTest
@testable import LocalMind

final class ModelConfigTests: XCTestCase {
    func testModelProviderCodable() throws {
        let provider = ModelProvider(
            id: UUID(),
            name: "OpenAI",
            template: .openAI,
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            modelName: "gpt-4o"
        )
        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(ModelProvider.self, from: data)
        XCTAssertEqual(decoded.name, "OpenAI")
        XCTAssertEqual(decoded.template, .openAI)
    }

    func testProviderTemplates() {
        XCTAssertEqual(ProviderTemplate.openAI.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(ProviderTemplate.anthropic.baseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(ProviderTemplate.deepSeek.baseURL, "https://api.deepseek.com/v1")
        XCTAssertNil(ProviderTemplate.custom.baseURL)
    }

    func testModelConfigStoreRoundTrip() {
        let store = ModelConfigStore()
        store.saveProviders([])
        store.addProvider(ModelProvider(id: UUID(), name: "测试", template: .custom,
                                        baseURL: "http://localhost:11434/v1", apiKey: "",
                                        modelName: "llama3"))
        let loaded = store.loadProviders()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.modelName, "llama3")
        store.saveProviders([])
    }

    func testModelRouterSelectsLocal() {
        let router = ModelRouter()
        let desc = router.describe(selection: .local(.qwen2_5_3b))
        XCTAssertTrue(desc.contains("Qwen"))
    }
}
import XCTest
@testable import LocalMind

final class CloudAPIServiceTests: XCTestCase {

    func testNoProviderThrowsError() async {
        let store = ModelConfigStore(storage: .shared)
        store.saveProviders([])
        let service = CloudAPIService(configStore: store)

        do {
            _ = try await service.generateCompletion(
                messages: [("user", "你好")],
                providerID: UUID()
            )
            XCTFail("应该抛出 noProvider 错误")
        } catch {
            guard case CloudAPIError.noProvider = error else {
                XCTFail("预期 noProvider 错误，实际: \(error)")
                return
            }
        }
    }

    func testInvalidURLThrowsError() async {
        let store = ModelConfigStore(storage: .shared)
        let provider = ModelProvider(
            id: UUID(),
            name: "测试",
            template: .custom,
            baseURL: "",
            apiKey: "test",
            modelName: "test"
        )
        store.saveProviders([provider])
        let service = CloudAPIService(configStore: store)

        do {
            _ = try await service.generateCompletion(
                messages: [("user", "你好")],
                providerID: provider.id
            )
            XCTFail("应该抛出错误")
        } catch {
            guard case CloudAPIError.invalidURL = error else {
                XCTFail("预期 invalidURL 错误，实际: \(error)")
                return
            }
        }

        store.saveProviders([])
    }
}

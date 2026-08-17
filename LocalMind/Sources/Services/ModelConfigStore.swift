import Foundation

class ModelConfigStore {
    static let shared = ModelConfigStore()
    private let storage: StorageService
    private let key = "model_providers"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadProviders() -> [ModelProvider] {
        storage.load([ModelProvider].self, forKey: key) ?? []
    }

    func saveProviders(_ providers: [ModelProvider]) {
        storage.save(providers, forKey: key)
    }

    func addProvider(_ provider: ModelProvider) {
        var providers = loadProviders()
        providers.append(provider)
        saveProviders(providers)
    }

    func updateProvider(_ provider: ModelProvider) {
        var providers = loadProviders()
        if let idx = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[idx] = provider
        }
        saveProviders(providers)
    }

    func deleteProvider(_ id: UUID) {
        var providers = loadProviders()
        providers.removeAll { $0.id == id }
        saveProviders(providers)
    }
}
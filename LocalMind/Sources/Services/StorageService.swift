import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - UserDefaults 操作
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(object) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - 文件操作
    
    func saveToFile<T: Codable>(_ object: T, filename: String) throws {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url)
    }
    
    func loadFromFile<T: Codable>(_ type: T.Type, filename: String) throws -> T {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func fileExists(_ filename: String) -> Bool {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }
    
    func deleteFile(_ filename: String) throws {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - 目录操作
    
    func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getCacheDirectory() -> URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func clearCache() throws {
        let cacheURL = getCacheDirectory()
        let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }
}

// MARK: - 存储键常量
extension StorageService {
    enum Keys {
        static let savedScenario = "saved_scenario"
        static let chatHistory = "chat_history"
        static let userSettings = "user_settings"
        static let workflows = "workflows"
    }
}

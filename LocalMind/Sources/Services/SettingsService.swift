import Foundation

class SettingsService {
    static let shared = SettingsService()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    var isOfflineMode: Bool {
        get { userDefaults.bool(forKey: Keys.offlineMode) }
        set { userDefaults.set(newValue, forKey: Keys.offlineMode) }
    }
    
    var temperature: Double {
        get { userDefaults.double(forKey: Keys.temperature) }
        set { userDefaults.set(newValue, forKey: Keys.temperature) }
    }
    
    var selectedModel: ModelType? {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.selectedModel) else {
                return nil
            }
            return ModelType(rawValue: rawValue)
        }
        set {
            userDefaults.set(newValue?.rawValue, forKey: Keys.selectedModel)
        }
    }
    
    var isFirstLaunch: Bool {
        get { !userDefaults.bool(forKey: Keys.hasLaunched) }
        set { userDefaults.set(!newValue, forKey: Keys.hasLaunched) }
    }
    
    func resetAllSettings() {
        userDefaults.removeObject(forKey: Keys.offlineMode)
        userDefaults.removeObject(forKey: Keys.temperature)
        userDefaults.removeObject(forKey: Keys.selectedModel)
    }
}

private extension SettingsService {
    enum Keys {
        static let offlineMode = "settings_offline_mode"
        static let temperature = "settings_temperature"
        static let selectedModel = "settings_selected_model"
        static let hasLaunched = "settings_has_launched"
    }
}

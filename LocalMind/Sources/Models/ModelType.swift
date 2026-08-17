import Foundation

enum ModelType: String, CaseIterable, Codable {
    case qwen2_5_3b = "qwen2.5-3b"
    case llama3_2_3b = "llama3.2-3b"
    case phi3_mini = "phi3-mini"
    case gemma2_2b = "gemma2-2b"
    
    var displayName: String {
        switch self {
        case .qwen2_5_3b: return "Qwen 2.5 (3B)"
        case .llama3_2_3b: return "Llama 3.2 (3B)"
        case .phi3_mini: return "Phi-3 Mini"
        case .gemma2_2b: return "Gemma 2 (2B)"
        }
    }
    
    var sizeInGB: Double {
        switch self {
        case .qwen2_5_3b: return 1.8
        case .llama3_2_3b: return 1.9
        case .phi3_mini: return 1.1
        case .gemma2_2b: return 1.5
        }
    }
}

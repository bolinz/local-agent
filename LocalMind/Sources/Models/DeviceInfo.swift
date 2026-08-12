import Foundation

struct DeviceInfo {
    let model: String
    let systemName: String
    let systemVersion: String
    let processorCount: Int
    let physicalMemory: UInt64
    
    var recommendedModel: ModelType {
        let memoryInGB = Double(physicalMemory) / 1_073_741_824.0
        
        if memoryInGB >= 8 {
            return .qwen2_5_3b
        } else if memoryInGB >= 6 {
            return .llama3_2_3b
        } else if memoryInGB >= 4 {
            return .phi3_mini
        } else {
            return .gemma2_2b
        }
    }
}

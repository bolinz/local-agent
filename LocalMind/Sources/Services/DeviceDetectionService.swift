import Foundation
import Darwin

class DeviceDetectionService {
    static let shared = DeviceDetectionService()
    
    private init() {}
    
    func getDeviceInfo() -> DeviceInfo {
        let device = ProcessInfo.processInfo
        
        return DeviceInfo(
            model: getDeviceModel(),
            systemName: device.processName,
            systemVersion: device.operatingSystemVersionString,
            processorCount: device.processorCount,
            physicalMemory: device.physicalMemory
        )
    }
    
    func getFriendlyDeviceName() -> String {
        let model = getDeviceModel()
        return parseDeviceModel(model)
    }
    
    private func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    private func parseDeviceModel(_ identifier: String) -> String {
        // iPhone
        if identifier.hasPrefix("iPhone") {
            return "iPhone"
        }
        // iPad
        else if identifier.hasPrefix("iPad") {
            return "iPad"
        }
        // Mac
        else if identifier.hasPrefix("Mac") {
            return "Mac"
        }
        // Simulator
        else if identifier.hasPrefix("x86_64") || identifier.hasPrefix("arm64") {
            return "Simulator"
        }
        else {
            return identifier
        }
    }
}

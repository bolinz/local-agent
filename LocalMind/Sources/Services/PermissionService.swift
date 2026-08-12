import Foundation
import EventKit

// MARK: - EKEventStore Extension for Async/Await
@available(macOS 14.0, iOS 17.0, *)
extension EKEventStore {
    func requestFullAccessToEvents() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            requestFullAccessToEvents { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func requestFullAccessToReminders() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            requestFullAccessToReminders { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

// MARK: - Permission Types
enum PermissionType: String, CaseIterable {
    case healthKit = "health_kit"
    case calendar = "calendar"
    case reminders = "reminders"
    case homeKit = "home_kit"
    case location = "location"
    
    var displayName: String {
        switch self {
        case .healthKit: return "健康数据"
        case .calendar: return "日历"
        case .reminders: return "提醒事项"
        case .homeKit: return "智能家居"
        case .location: return "定位服务"
        }
    }
}

enum PermissionStatus {
    case granted
    case denied
    case notDetermined
    case restricted
}

// MARK: - Permission Service
class PermissionService {
    static let shared = PermissionService()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - HealthKit Permission
    func requestHealthKitPermission() async throws {
        // TODO: 请求 HealthKit 权限
        print("TODO: Request HealthKit permission")
    }
    
    // MARK: - EventKit Permission
    func requestCalendarPermission() async throws -> Bool {
        if #available(macOS 14.0, iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func requestReminderPermission() async throws -> Bool {
        if #available(macOS 14.0, iOS 17.0, *) {
            return try await eventStore.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - HomeKit Permission
    func requestHomeKitPermission() {
        // TODO: 请求 HomeKit 权限
        print("TODO: Request HomeKit permission")
    }
    
    // MARK: - Location Permission
    func requestLocationPermission() {
        // TODO: 请求定位权限
        print("TODO: Request location permission")
    }
    
    // MARK: - Check Permissions
    func checkPermissionStatus() -> [PermissionType: PermissionStatus] {
        var statuses: [PermissionType: PermissionStatus] = [:]
        
        // TODO: 检查各个权限的状态
        statuses[.healthKit] = .notDetermined
        statuses[.calendar] = .notDetermined
        statuses[.reminders] = .notDetermined
        statuses[.homeKit] = .notDetermined
        statuses[.location] = .notDetermined
        
        return statuses
    }
}

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization(types: [HKObjectType]) async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: Set(types))
    }

    // MARK: - 今日步数

    func fetchTodayStepCount() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }
        try await requestAuthorization(types: [stepType])

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error { continuation.resume(throwing: error); return }
                let count = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            store.execute(query)
        }
        return steps
    }

    // MARK: - 最近心率

    func fetchLatestHeartRate() async throws -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAvailable
        }
        try await requestAuthorization(types: [hrType])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error { continuation.resume(throwing: error); return }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }

        guard let sample = samples.first as? HKQuantitySample else { return nil }
        return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    }

    // MARK: - 昨晚睡眠

    func fetchLastNightSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }
        try await requestAuthorization(types: [sleepType])

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error { continuation.resume(throwing: error); return }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }

        let asleep: [HKCategorySample] = samples.compactMap { $0 as? HKCategorySample }.filter {
            $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue
        }

        guard !asleep.isEmpty else { return nil }
        let totalSeconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return totalSeconds / 3600.0
    }
}

enum HealthKitError: LocalizedError {
    case typeNotAvailable
    var errorDescription: String? { "HealthKit 类型不可用" }
}

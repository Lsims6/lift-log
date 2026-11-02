import Foundation
import HealthKit

/// Apple Health for Lift Log. The page decides what belongs in Health and sends it here as plain samples,
/// each with a stable key ("w:2026-11-02", "f:2026-11-02:l", "wk:2026-11-02", "c:2026-11-02:post").
/// Every sample is saved with that key as its sync identifier, so re-sending a key replaces the old copy
/// and removing a key deletes it. Lift Log writes workouts, body weight and calories eaten, and reads body
/// weight that other apps (a smart scale, the Health app) saved.
enum HealthSync {
    static let store = HKHealthStore()
    static var available: Bool { HKHealthStore.isHealthDataAvailable() }

    private static let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    private static let energy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
    private static let workout = HKObjectType.workoutType()
    private static let prefix = "liftlog:"

    static func connect(_ done: @escaping ([String: Any]) -> Void) {
        guard available else { return done(["ok": false, "error": "Apple Health isn't available on this device."]) }
        store.requestAuthorization(toShare: [weight, energy, workout], read: [weight]) { ok, error in
            DispatchQueue.main.async { done(["ok": ok, "error": error?.localizedDescription ?? ""]) }
        }
    }

    /// Saves `put` (replacing any earlier copy of each key) and deletes `remove`. Reports which keys went through.
    static func sync(put: [[String: Any]], remove: [String], done: @escaping ([String: Any]) -> Void) {
        Task {
            var finished: [String] = [], errors: [String] = []
            for key in remove {
                await delete(key)
                finished.append(key)
            }
            for sample in put {
                guard let key = sample["key"] as? String else { continue }
                do {
                    await delete(key)
                    try await save(sample, key: key)
                    finished.append(key)
                } catch {
                    errors.append(error.localizedDescription)
                }
            }
            let result: [String: Any] = ["ok": errors.isEmpty, "done": finished, "error": errors.first ?? ""]
            await MainActor.run { done(result) }
        }
    }

    /// Body weights saved by other apps since `since`, oldest first.
    static func readWeights(since: Date, _ done: @escaping ([String: Any]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        let query = HKSampleQuery(sampleType: weight, predicate: predicate, limit: 1000, sortDescriptors: sort) { _, samples, error in
            let mine = Bundle.main.bundleIdentifier
            let list: [[String: Any]] = (samples as? [HKQuantitySample] ?? [])
                .filter { s in
                    s.sourceRevision.source.bundleIdentifier != mine
                        && (s.metadata?[HKMetadataKeySyncIdentifier] as? String)?.hasPrefix(prefix) != true
                }
                .map { ["t": $0.startDate.timeIntervalSince1970 * 1000, "lb": $0.quantity.doubleValue(for: .pound())] }
            DispatchQueue.main.async { done(["ok": error == nil, "weights": list, "error": error?.localizedDescription ?? ""]) }
        }
        store.execute(query)
    }

    private static func sampleType(for key: String) -> HKObjectType {
        key.hasPrefix("w:") ? weight : key.hasPrefix("f:") ? energy : workout
    }

    private static func metadata(_ key: String) -> [String: Any] {
        [HKMetadataKeySyncIdentifier: prefix + key, HKMetadataKeySyncVersion: Int(Date().timeIntervalSince1970 * 1000)]
    }

    /// Deletes whatever Lift Log saved under this key. Nothing there yet is fine.
    private static func delete(_ key: String) async {
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier, allowedValues: [prefix + key])
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            store.deleteObjects(of: sampleType(for: key), predicate: predicate) { _, _, _ in cont.resume() }
        }
    }

    private static func date(_ value: Any?) -> Date? {
        (value as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
    }

    private static func save(_ s: [String: Any], key: String) async throws {
        guard let start = date(s["start"]) else { throw HealthError.bad(key) }
        let end = date(s["end"]) ?? start
        var md = metadata(key)
        switch s["kind"] as? String {
        case "weight":
            guard let lb = s["lb"] as? Double else { throw HealthError.bad(key) }
            try await store.save(HKQuantitySample(type: weight, quantity: HKQuantity(unit: .pound(), doubleValue: lb),
                                                  start: start, end: end, metadata: md))
        case "food":
            guard let cal = s["cal"] as? Double else { throw HealthError.bad(key) }
            if let meal = s["meal"] as? String { md[HKMetadataKeyFoodType] = meal }
            try await store.save(HKQuantitySample(type: energy, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: cal),
                                                  start: start, end: end, metadata: md))
        case "workout":
            let config = HKWorkoutConfiguration()
            config.activityType = activity(s["activity"] as? String)
            config.locationType = s["activity"] as? String == "walk" || s["activity"] as? String == "run" ? .outdoor : .indoor
            let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
            try await builder.beginCollection(at: start)
            if let name = s["name"] as? String { md[HKMetadataKeyWorkoutBrandName] = name }
            try await builder.addMetadata(md)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        default:
            throw HealthError.bad(key)
        }
    }

    private static func activity(_ name: String?) -> HKWorkoutActivityType {
        switch name {
        case "strength": return .traditionalStrengthTraining
        case "stairs": return .stairClimbing
        case "walk": return .walking
        case "run", "treadmill": return .running
        case "bike": return .cycling
        case "elliptical": return .elliptical
        case "rower": return .rowing
        default: return .other
        }
    }

    enum HealthError: LocalizedError {
        case bad(String)
        var errorDescription: String? {
            if case .bad(let key) = self { return "Couldn't read \(key) for Apple Health." }
            return nil
        }
    }
}

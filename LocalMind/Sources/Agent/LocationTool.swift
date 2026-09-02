import Foundation
import CoreLocation

class LocationTool: Tool {
    static let id = "location"
    var id: String { Self.id }
    var name: String { "位置" }
    var description: String { "获取当前位置和地址信息" }
    var requiresPermission: Bool { true }

    private let locationManager = LocationManager.shared
    private let geocoder = CLGeocoder()

    func execute(arguments: [String: String]) async throws -> String {
        let coord = await locationManager.fetchCurrentLocation()

        guard let coordinate = coord else {
            return "❌ 无法获取位置，请检查定位权限"
        }

        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)

        let placemarks = try await geocoder.reverseGeocodeLocation(
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )

        guard let place = placemarks.first else {
            return "📍 位置：\(lat), \(lon)（无法解析地址）"
        }

        var parts: [String] = []
        if let name = place.name { parts.append(name) }
        if let locality = place.locality { parts.append(locality) }
        if let admin = place.administrativeArea { parts.append(admin) }
        if let country = place.country { parts.append(country) }

        let address = parts.isEmpty ? "\(lat), \(lon)" : parts.joined(separator: ", ")
        return "📍 位置：\(address)"
    }
}

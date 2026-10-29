import Foundation
import MapKit

@MainActor protocol JourneyEstimating {
    func estimate(from: Coordinate, to: Coordinate, mode: TravelMode) async throws -> JourneyEstimate
}

enum NearbyServiceError: LocalizedError {
    case unavailable, invalidResponse
    var errorDescription: String? {
        switch self { case .unavailable: "A route estimate is not available for this journey."; case .invalidResponse: "The online service returned an incomplete response." }
    }
}

@MainActor final class JourneyService: JourneyEstimating {
    private var cache: [String: JourneyEstimate] = [:]
    private static var nextCommunityRequest = Date.distantPast

    func estimate(from origin: Coordinate, to destination: Coordinate, mode: TravelMode) async throws -> JourneyEstimate {
        let key = "\(origin.latitude)|\(origin.longitude)|\(destination.latitude)|\(destination.longitude)|\(mode.rawValue)"
        if let cached = cache[key], Date.now.timeIntervalSince(cached.checkedAt) < 900 { return cached }
        try Task.checkCancellation()
        let value: JourneyEstimate
        do {
            value = try await appleJourney(from: origin, to: destination, mode: mode)
        } catch {
            try Task.checkCancellation()
            guard mode != .transit else { throw NearbyServiceError.unavailable }
            value = try await communityJourney(from: origin, to: destination, mode: mode)
        }
        guard value.minutes != nil, value.roundTripMeters.isFinite, value.roundTripMeters >= 0 else { throw NearbyServiceError.invalidResponse }
        cache[key] = value
        return value
    }
    private func appleJourney(from origin: Coordinate, to destination: Coordinate, mode: TravelMode) async throws -> JourneyEstimate {
        let outward = try await leg(from: origin, to: destination, mode: mode)
        try Task.checkCancellation()
        let inward = try await leg(from: destination, to: origin, mode: mode)
        let source = mode == .motorbike ? "Apple Maps driving-route estimate" : "Apple Maps route estimate"
        return JourneyEstimate(roundTripSeconds: outward.seconds + inward.seconds, roundTripMeters: outward.meters + inward.meters, source: source, checkedAt: .now)
    }
    private func leg(from origin: Coordinate, to destination: Coordinate, mode: TravelMode) async throws -> (seconds: Double, meters: Double) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.mapCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.mapCoordinate))
        request.transportType = mode == .walking ? .walking : mode == .transit ? .transit : .automobile
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        return try await withThrowingTaskGroup(of: (Double, Double).self) { group in
            group.addTask { @MainActor in
                try await withTaskCancellationHandler {
                    if mode == .transit {
                        let eta = try await directions.calculateETA()
                        return (eta.expectedTravelTime, eta.distance)
                    }
                    let response = try await directions.calculate()
                    guard let route = response.routes.first else { throw NearbyServiceError.unavailable }
                    return (route.expectedTravelTime, route.distance)
                } onCancel: { Task { @MainActor in directions.cancel() } }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(7))
                throw NearbyServiceError.unavailable
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw NearbyServiceError.unavailable }
            return first
        }
    }
    private func communityJourney(from origin: Coordinate, to destination: Coordinate, mode: TravelMode) async throws -> JourneyEstimate {
        // FOSSGIS requires <= 1 request per second. Reserve slots before suspending,
        // including when several plan rows need a route at the same time.
        let now = Date.now
        let slot = max(now, Self.nextCommunityRequest)
        Self.nextCommunityRequest = slot.addingTimeInterval(1.1)
        if slot > now { try await Task.sleep(for: .seconds(slot.timeIntervalSince(now))) }
        try Task.checkCancellation()
        let profile = mode == .walking ? "foot" : "car"
        let coordinates = "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude);\(origin.longitude),\(origin.latitude)"
        guard let url = URL(string: "https://routing.openstreetmap.de/routed-\(profile)/route/v1/driving/\(coordinates)?overview=false&steps=false") else { throw NearbyServiceError.invalidResponse }
        var request = URLRequest(url: url, timeoutInterval: 12)
        request.setValue("AdoYamu/1.0 (native iOS nearby trip planner)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw NearbyServiceError.unavailable }
        let result = try JSONDecoder().decode(OSRMResponse.self, from: data)
        guard result.code == "Ok", let route = result.routes.first,
              result.waypoints.count == 3, result.waypoints.allSatisfy({ $0.distance.isFinite && $0.distance <= 300 }) else { throw NearbyServiceError.unavailable }
        let source = mode == .walking ? "OpenStreetMap walking-route estimate · FOSSGIS/OSRM" : "OpenStreetMap driving-route estimate · FOSSGIS/OSRM · no live traffic"
        return JourneyEstimate(roundTripSeconds: route.duration, roundTripMeters: route.distance, source: source, checkedAt: .now)
    }
    private struct OSRMResponse: Decodable {
        struct Route: Decodable { let duration: Double; let distance: Double }
        struct Waypoint: Decodable { let distance: Double }
        let code: String
        let routes: [Route]
        let waypoints: [Waypoint]
    }
}

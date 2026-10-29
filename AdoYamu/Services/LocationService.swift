import CoreLocation
import Observation

@MainActor @Observable final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var coordinate: Coordinate?
    var isRequesting = false
    var message: String?
    override init() {
        super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    func request() {
        message = nil; isRequesting = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: denied()
        @unknown default: denied()
        }
    }
    private func denied() { isRequesting = false; message = "Location is unavailable. Choose a city below, or enable location in iOS Settings." }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRequesting else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: denied()
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isRequesting = false
        guard let location = locations.last else { message = "No location found. Please choose a city."; return }
        coordinate = .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequesting = false; message = "We couldn’t find your location. Your selected city still works."
    }
}

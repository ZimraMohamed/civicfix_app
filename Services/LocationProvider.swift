import CoreLocation
import Observation

/// One-shot "where am I?" helper. Requires `NSLocationWhenInUseUsageDescription` in Info.plist.
@MainActor @Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    enum Status { case idle, locating, ready, denied, failed }

    private(set) var status: Status = .idle
    private(set) var location: ReportLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// Asks for permission if needed, then fetches a single fix.
    func request() {
        guard status != .locating else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .locating
            manager.requestWhenInUseAuthorization()   // continues in locationManagerDidChangeAuthorization
        case .denied, .restricted:
            status = .denied
        default:
            status = .locating
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate (called off the main actor)

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let auth = manager.authorizationStatus
        Task { @MainActor in self.authorizationChanged(auth) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let fix = ReportLocation(latitude: last.coordinate.latitude,
                                 longitude: last.coordinate.longitude,
                                 accuracy: last.horizontalAccuracy)
        Task { @MainActor in
            self.location = fix
            self.status = .ready
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        Task { @MainActor in self.status = denied ? .denied : .failed }
    }

    // MARK: - Private

    private func authorizationChanged(_ auth: CLAuthorizationStatus) {
        guard status == .locating else { return }     // ignore the callback fired at start-up
        switch auth {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: status = .denied
        default: break
        }
    }
}

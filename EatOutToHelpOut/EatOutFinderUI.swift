import UIKit
import MapKit

class EatOutMapViewController: UIViewController {

    static let MapPinReuseIdentifier = "MKMapAnnotationViewIdentifier"
    @IBOutlet weak var mapView: MKMapView!
    var interactor: EatOutFinder!
    var items: [EatOutFinderItemUI] = [EatOutFinderItemUI]()

    override func viewDidLoad() {
        configureMap()
        interactor.load()
    }

    private func configureMap() {
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.MapPinReuseIdentifier)
        MapViewConfiguration.configure(mapView, center: MKCoordinateRegion.HW)
    }
    
}

extension EatOutFinderItemUI: MKAnnotation {
    var title: String? { return name }
}

extension EatOutMapViewController: EatOutFinderOutlet {

    func show(_ items : [EatOutFinderItemUI]) {
        self.items = items
        mapView(mapView, regionDidChangeAnimated: false)
    }

    func show(_ error: ErrorUI) {
        let alert = UIAlertController.init(title: error.title, message: error.message, preferredStyle: .alert)
        let action = UIAlertAction(title: error.defaultActionTitle, style: .default) { (action) in
            error.errorActionHandler?(action.title ?? "")
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

}

extension EatOutMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = Self.MapPinReuseIdentifier
        if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequedView.annotation = annotation
            return dequedView
        } else {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.displayPriority = .defaultLow
            return view
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.region.span.latitudeDelta < CLLocationDegrees.ZoomThreshold {
            showAnnotations(rect: mapView.visibleMapRect)
        } else  {
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    func showAnnotations(rect: MKMapRect) {

        // Cut Annotations No Longer Being Displayed

        let outsideRectAnnotations = mapView.annotations.filter { rect.contains( MKMapPoint($0.coordinate) ) == false }

        mapView.removeAnnotations(outsideRectAnnotations)


        // Find new items that match the current rect (not already visible)

        let alreadyVisibleAnnotations = mapView.annotations(in: rect)

        let missingAnnotations = items.filter {

            return alreadyVisibleAnnotations.contains($0) == false && rect.contains(MKMapPoint($0.coordinate))

        }

        mapView.addAnnotations(missingAnnotations)


    }

}

extension CLLocationDegrees {
    static let ZoomThreshold = 0.15
}
extension CLLocationCoordinate2D {
    static let UK = CLLocationCoordinate2D(latitude: 54.093409, longitude: -2.89479)
    static let HW = CLLocationCoordinate2D(latitude: 51.6267, longitude: -0.7435)
}

extension MKCoordinateSpan {
    static let UK = MKCoordinateSpan(latitudeDelta: 14.83, longitudeDelta: 12.22)
    static let HW = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
}

extension MKCoordinateRegion {
    static let UK = MKCoordinateRegion(center: CLLocationCoordinate2D.UK, span: MKCoordinateSpan.UK)
    static let HW = MKCoordinateRegion(center: CLLocationCoordinate2D.HW, span: MKCoordinateSpan.HW)
}

extension CLLocationDistance {
    static let UKZoomMin = CLLocationDistance(exactly: 0.5 * 1000)!
    static let UKZoomMax = CLLocationDistance(exactly: 2200 * 1000)!
}

class MapViewConfiguration {

    static func configure(_ map: MKMapView, center: MKCoordinateRegion) {
        Self.centerMap(map, region: center)
        Self.constrainMapBoundariesToUnitedKingdom(map)
        Self.filterOutPointsOfInterest(map)
    }

    static func filterOutPointsOfInterest(_ map: MKMapView) {
        map.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [ .restaurant, .cafe ])
    }

    static func centerMap(_ map: MKMapView, region: MKCoordinateRegion) {
        map.setRegion(region, animated: false)
    }

    static func constrainMapBoundariesToUnitedKingdom(_ map: MKMapView) {
        map.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: MKCoordinateRegion.UK)
        map.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance:  CLLocationDistance.UKZoomMin,
                                                        maxCenterCoordinateDistance: CLLocationDistance.UKZoomMax)
    }

}

import UIKit
import MapKit

class EatOutMapViewController: StoryboardSegueViewController {

    static let MapAnnotationReuseIdentifier = NSStringFromClass(EatOutFinderItemUI.self)

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!

    var interactor: EatOutFinder!
    var items: [EatOutFinderItemUI] = [EatOutFinderItemUI]()
    var webViewURL: URL?
    var searchTerm: String?

    override func viewDidLoad() {
        configureMap()
        interactor.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        interactor.updateUI()
    }

    // MARK: Actions

    @IBAction func locationButtonAction(_ sender: Any) {
        interactor.updateLocation()
    }

    private func configureMap() {
        mapView.showsUserLocation = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.MapAnnotationReuseIdentifier)
        MapViewConfiguration.configure(mapView, center: MKCoordinateRegion.HW)
    }

}

extension EatOutMapViewController: WebViewControllerDataSource {
}

extension EatOutMapViewController: EatOutFinderOutlet {


    func show(_ locationButtonUI : UserLocationButtonUI) {
        switch locationButtonUI {
        case .disabled:
            locationButton.tintColor = .systemGray
            locationButton.isEnabled = false
            locationButton.isSelected = false
        case .normal:
            locationButton.tintColor = .systemGray
            locationButton.isEnabled = true
            locationButton.isSelected = false
        case .hilighted:
            locationButton.tintColor = .systemBlue
            locationButton.isEnabled = true
            locationButton.isSelected = true
        }
    }

    func showUserCurrentLocationOnMap() {
        if let userLocationCoords = mapView.userLocation.location?.coordinate {
            let userMapPoint = MKMapPoint(userLocationCoords)
            let userLocationWithinBounds = mapView.cameraBoundary?.mapRect.contains(userMapPoint) ?? true
            if  userLocationWithinBounds {
                let region = MKCoordinateRegion(center: userLocationCoords, span: MKCoordinateSpan.LOW )
                mapView.setRegion(region, animated: true)
            }
        }
    }


    func show(_ url: URL, title: String) {
        self.webViewURL = url
        self.searchTerm = title
        performSegue(withIdentifier: SegueIdentifier.WebViewSegueIdentifier.rawValue, sender: self)
    }

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

    func show(_: EatOutFinderDownloadStateUI) {
        //MARK: TODO Handle loading start stop states
    }

}

extension EatOutFinderItemUI: MKAnnotation {
    var title: String? { return name }
}

extension EatOutMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Use default user location annotation view
        
        if mapView.userLocation == annotation as? MKUserLocation {
            return nil
        }

        let identifier = Self.MapAnnotationReuseIdentifier
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let dequedView = view as? MKMarkerAnnotationView {
            dequedView.displayPriority = .defaultLow // optimisation not sure?
            configureAnnotationCallout(dequedView)
        }
        return view
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.region.span.latitudeDelta < CLLocationDegrees.ZoomThreshold {
            showAnnotations(rect: mapView.visibleMapRect)
        } else  {
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        AppLogger.log(object: self, function: #function)
        guard let item = view.annotation as? EatOutFinderItemUI else  { return }
        interactor.didSelectItem(item: item)
    }
    
    private func configureAnnotationCallout(_ markerAnnotationView: MKMarkerAnnotationView) {
        markerAnnotationView.isEnabled = true
        markerAnnotationView.canShowCallout = true
        markerAnnotationView.animatesWhenAdded = true
        markerAnnotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }

    private func showAnnotations(rect: MKMapRect) {

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
    static let HIGH = MKCoordinateSpan(latitudeDelta: 14.83, longitudeDelta: 12.22)
    static let LOW = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
}

extension MKCoordinateRegion {
    static let UK = MKCoordinateRegion(center: CLLocationCoordinate2D.UK, span: MKCoordinateSpan.HIGH)
    static let HW = MKCoordinateRegion(center: CLLocationCoordinate2D.HW, span: MKCoordinateSpan.LOW)
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
        map.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance:  CLLocationDistance.UKZoomMin, maxCenterCoordinateDistance: CLLocationDistance.UKZoomMax)
    }

}


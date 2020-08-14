import UIKit
import MapKit

class EatOutMapViewController: StoryboardSegueViewController {

    static let MapAnnotationReuseIdentifier = NSStringFromClass(EatOutFinderItemUI.self)

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var enableUserTrackingButton: UIButton!
    @IBOutlet var mapUserTrackingButtonContainer: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var zoomNearerLabel: UIView! { didSet {zoomNearerLabel.alpha = 0.0}}
    @IBOutlet var zoomNearerBkgd: UIView! { didSet {zoomNearerBkgd.alpha = 0.0} }
    

    var interactor: EatOutFinder!
    var items: [EatOutFinderItemUI] = [EatOutFinderItemUI]()
    var userTrackingButton: MKUserTrackingButton?
    var shouldZoomOnUpdate = false
    var lastLatitudeDelta: CLLocationDegrees = CLLocationDegrees.zero

    //MARK: - WebViewDataSource

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

    @objc func userTrackingButtonTapped(sender: UIGestureRecognizer) {
        interactor.updateLocation()
    }

    @IBAction func exitToMap(segue : UIStoryboardSegue) {
        // Exit to here
    }

    // MARK: UI Configuration

    private func configureMap() {
        MapViewConfiguration.configure(mapView, center: MKCoordinateRegion.UK)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.MapAnnotationReuseIdentifier)
    }

    private func configureEnableUserTrackingButton(isEnabled: Bool) {
        enableUserTrackingButton.isHidden = false
        enableUserTrackingButton.isEnabled = isEnabled
        enableUserTrackingButton.tintColor = (isEnabled) ? .systemBlue : .systemGray
        removeSystemMapUserTrackingButton()
    }

    private var isLoadingActive: Bool  {
        return loadingIndicator.isAnimating
    }

    private func zoomToUserLocation() {
        if let userLocationCoords = mapView.userLocation.location?.coordinate {
            let userMapPoint = MKMapPoint(userLocationCoords)
            let userLocationWithinBounds = mapView.cameraBoundary?.mapRect.contains(userMapPoint) ?? true
            if  userLocationWithinBounds {
                let region = MKCoordinateRegion(center: userLocationCoords, span: MKCoordinateSpan.LOW )
                mapView.setRegion(region, animated: true)
            }
        }
    }

    private func showLoadingActivityUI(hidden: Bool = false) {
        if ( hidden ) { loadingIndicator.stopAnimating() } else { loadingIndicator.startAnimating() }
    }

    private func showSystemMapUserTracking() {
        enableUserTrackingButton.isHidden = true
        guard userTrackingButton == nil else { return }
        shouldZoomOnUpdate = true
        addSystemMapUserTrackingButton()
    }

    private func addSystemMapUserTrackingButton() {
        userTrackingButton = MKUserTrackingButton(mapView: self.mapView)
        mapUserTrackingButtonContainer.addSubview(userTrackingButton!)
        mapView.showsUserLocation = true
    }

    private func removeSystemMapUserTrackingButton() {
        userTrackingButton?.removeFromSuperview()
        userTrackingButton = nil
    }



}

extension EatOutMapViewController: WebViewControllerDataSource {
}

extension EatOutMapViewController: EatOutFinderOutlet {

    func show(_ status: EatOutFinderStatusUI) {
        switch status {
        case .loading:
            showLoadingActivityUI()
        case .userLocationOff:
            configureEnableUserTrackingButton(isEnabled:true)
        case .userLocationOn:
            showSystemMapUserTracking()
        case .userLocationDisabled:
            configureEnableUserTrackingButton(isEnabled:false)
        }

        if status != .loading {
            mapView.delegate = self
            showLoadingActivityUI(hidden: true)
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
}

extension EatOutFinderItemUI: MKAnnotation {
    var title: String? { return name }
}


//MARK:- MapViewDelegate

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
        let newLatitudeDelta = mapView.region.span.latitudeDelta.round(to: 2)
        let didZoomIn = newLatitudeDelta < lastLatitudeDelta
        if mapView.region.span.latitudeDelta <= CLLocationDegrees.ZoomThreshold {
            showAnnotations(rect: mapView.visibleMapRect)
        } else  {
            mapView.removeAnnotations(mapView.annotations)
            if ( didZoomIn && !animated ) { showZoomHint() }
        }
        lastLatitudeDelta = newLatitudeDelta
    }

    private func showZoomHint() {

        guard self.zoomNearerLabel.alpha == CGFloat.zero else {
            return
        }

        let animationDuration = 1.0
        let animationStageDuration = animationDuration / 2
        let animateIn = UIViewPropertyAnimator(duration: animationStageDuration, curve: .easeOut) {
            self.zoomNearerBkgd.alpha = 1.0
            self.zoomNearerLabel.alpha = 1.0
        }
        let animateOut = UIViewPropertyAnimator(duration: animationStageDuration, curve: .easeIn) {
            self.zoomNearerBkgd.alpha = CGFloat.zero
            self.zoomNearerLabel.alpha = CGFloat.zero
        }
        animateIn.addCompletion { (pos) in
            animateOut.startAnimation(afterDelay: 0.5)
        }

        animateIn.startAnimation()

    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        AppLogger.log(object: self, function: #function)
        guard let item = view.annotation as? EatOutFinderItemUI else  { return }
        interactor.didSelectItem(item: item)
    }

    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        AppLogger.log(object: self, function: #function)
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        AppLogger.log(object: self, function: #function, error: error)
        show(EatOutFinderStatusUI.userLocationDisabled)
        removeSystemMapUserTrackingButton()
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // ... we are tracking
        if shouldZoomOnUpdate {
            zoomToUserLocation()
            shouldZoomOnUpdate = false
        }
    }

    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        removeSystemMapUserTrackingButton()
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

//MARK: - MapView Extensions

extension CLLocationDegrees {
    static let ZoomThreshold = 0.05
}

extension CLLocationCoordinate2D {
    static let UK = CLLocationCoordinate2D(latitude: 54.093409, longitude: -2.89479)
}

extension MKCoordinateSpan {
    static let HIGH = MKCoordinateSpan(latitudeDelta: 14.83, longitudeDelta: 12.22)
    static let MIDDLE = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
    static let LOW = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
}

extension MKCoordinateRegion {
    static let UK = MKCoordinateRegion(center: CLLocationCoordinate2D.UK, span: MKCoordinateSpan.HIGH)
}

extension CLLocationDistance {
    static let UKZoomMin = CLLocationDistance(exactly: 0.25 * 1000)!
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

extension CLLocationDegrees {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

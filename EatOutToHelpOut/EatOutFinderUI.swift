import UIKit
import MapKit

class EatOutMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var interactor: EatOutFinder!

    override func viewDidLoad() {
        interactor.load()
    }
    
}

extension EatOutFinderItemUI: MKAnnotation {}

extension EatOutMapViewController: EatOutFinderOutlet {

    func show(_ items : [EatOutFinderItemUI]) {
        annotateMap(with: items)
    }

    func annotateMap(with items : [MKAnnotation]) {
        AppLogger.log(object: self, function: #function, message:"Annotating Map Items (\(items.count))")
        mapView?.addAnnotations(items)
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

//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        AppLogger.log(object: self, function: #function)
//        return nil
//    }

    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        AppLogger.log(object: self, function: #function)
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        AppLogger.log(object: self, function: #function)
    }
}



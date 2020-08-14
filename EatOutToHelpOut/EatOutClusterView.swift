//
//  EatOutClusterView.swift
//  EatOutToHelpOut
//
//  Created by Gerald Benischke on 14/08/2020.
//  Copyright © 2020 Equal Experts. All rights reserved.
//

import MapKit

//  MARK: Eat Out Cluster View
internal final class EatOutClusterView: MKAnnotationView {
    //  MARK: Properties
    internal override var annotation: MKAnnotation? { willSet { newValue.flatMap(configure(with:)) } }
    //  MARK: Initialization
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        centerOffset = CGPoint(x: 0.0, y: -10.0)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) not implemented.")
    }
}
//  MARK: Configuration
private extension EatOutClusterView {
    func configure(with annotation: MKAnnotation) {
        guard let annotation = annotation as? MKClusterAnnotation else { return }
        //    CONFIGURE
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40.0, height: 40.0))
        let count = annotation.memberAnnotations.count
        image = renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)).fill()
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)]
            let text = "\(count)"
            let size = text.size(withAttributes: attributes)
            let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
            text.draw(in: rect, withAttributes: attributes)
        }
    }
}

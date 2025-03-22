//
//  ViewController.swift
//  Labexe9
//
//  Created by kevin bhangu on 2025-03-21.
///

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var points: [CLLocationCoordinate2D] = []
    var overlays: [MKOverlay] = []
    var annotations: [MKPointAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(_ gestureReconizer: UITapGestureRecognizer) {
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        if let index = points.firstIndex(where: { distance(from: $0, to: coordinate) < 500 }) {
            mapView.removeAnnotation(annotations[index])
            points.remove(at: index)
            annotations.remove(at: index)
            redraw()
            return
        }

        if points.count < 3 {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "City \(points.count + 1)"
            mapView.addAnnotation(annotation)
            annotations.append(annotation)
            points.append(coordinate)

            if points.count == 3 {
                drawTriangle()
            }
        }
    }

    func drawTriangle() {
        mapView.removeOverlays(overlays)
        overlays.removeAll()

        for i in 0..<3 {
            let start = points[i]
            let end = points[(i + 1) % 3]

            let line = MKPolyline(coordinates: [start, end], count: 2)
            mapView.addOverlay(line)
            overlays.append(line)

            let midLat = (start.latitude + end.latitude) / 2
            let midLon = (start.longitude + end.longitude) / 2
            let dist = distance(from: start, to: end) / 1000.0
            let distAnnotation = MKPointAnnotation()
            distAnnotation.coordinate = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
            distAnnotation.title = String(format: "%.2f km", dist)
            mapView.addAnnotation(distAnnotation)
            annotations.append(distAnnotation)
        }

        let polygon = MKPolygon(coordinates: points, count: 3)
        mapView.addOverlay(polygon)
        overlays.append(polygon)
    }

    func redraw() {
        mapView.removeOverlays(overlays)
        overlays.removeAll()

        if points.count == 3 {
            drawTriangle()
        }
    }

    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let line = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: line)
            renderer.strokeColor = .green
            renderer.lineWidth = 3
            return renderer
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(overlay: polygon)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            return renderer
        }
        return MKOverlayRenderer()
    }

    @IBAction func routeButtonTapped(_ sender: UIButton) {
        guard points.count == 3 else { return }

        let routes = [(0,1), (1,2), (2,0)]

        for (startIndex, endIndex) in routes {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: points[startIndex]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: points[endIndex]))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    self.ovefrlays.append(route.polyline)
                }
            }
        }
    }
}





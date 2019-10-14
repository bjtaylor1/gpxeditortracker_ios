//
//  ViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 15/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import UIKit
import CoreData
import MapKit
class MapViewController: UIViewController, MKMapViewDelegate {
    var uploadedLocations : [CLLocationCoordinate2D] = []
    var uploadedLocationsPolyline : MKPolyline? = nil
    
    @IBOutlet weak var theMap: MKMapView!
    @IBAction func stopClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Stop tracking?", message: "Do you want to stop tracking?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler:
            {(uiAlertAction) in
                LocationManager.Instance.stop()
                self.dismiss(animated: true)
            }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        self.present(alert, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theMap.delegate = self
        
        NotificationCenter.default.addObserver(forName: .onLocationReceived, object: nil, queue: OperationQueue.main)
        {(notification) in self.handleOnLocationReceivedNotification(notification: notification)}
        
        NotificationCenter.default.addObserver(forName: .onLocationUploaded, object: nil, queue: OperationQueue.main)
        {(notification) in self.handleOnLocationUploadedNotification(notification: notification)}

        LocationManager.Instance.start()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline, polyline == uploadedLocationsPolyline {
            
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(displayP3Red: CGFloat(5)/255, green: CGFloat(124)/255, blue: 1, alpha: 1)
            renderer.lineWidth = 4
            return renderer
        }
        NSLog("WARN: Unrecognized overlay passed to rendererFor")
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func handleOnLocationReceivedNotification(notification: Notification) {
        if let location = notification.object as? CLLocation {
            refreshLocationEntity(location: location)
        }
    }
    
    func handleOnLocationUploadedNotification(notification: Notification) {
         if let location = notification.object as? CLLocation {
            uploadedLocations.append(location.coordinate)
            if let toRemove = uploadedLocationsPolyline {
                theMap.removeOverlay(toRemove)
            }
            let newPolyline = MKPolyline(coordinates: uploadedLocations, count: uploadedLocations.count)
            uploadedLocationsPolyline = newPolyline
            theMap.addOverlay(newPolyline)
         }
     }

    
    var currentPosReceived: MKPointAnnotation? = nil
    func refreshLocationEntity(location: CLLocation) {
        if viewIfLoaded?.window != nil {
            // viewController is visible
            
            NSLog("Received location: %@", location.description)
            if(currentPosReceived == nil) {
                currentPosReceived = MKPointAnnotation()
                theMap.addAnnotation(currentPosReceived!)
            }
            currentPosReceived?.coordinate = location.coordinate
            
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: CLLocationDistance(exactly: 3000)!,
                longitudinalMeters: CLLocationDistance(exactly: 3000)!)
            
            //theMap.setRegion(region, animated: true)
            theMap.setRegion(theMap.regionThatFits(region), animated: true)
        }
    }
    
}


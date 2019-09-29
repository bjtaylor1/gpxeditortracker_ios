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
class MapViewController: UIViewController {
    
    @IBOutlet weak var theMap: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
                
        NotificationCenter.default.addObserver(forName: .onLocationReceived, object: nil, queue: nil)
        {(notification) in self.handleOnLocationReceivedNotification(notification: notification)}
    }
    
    func handleOnLocationReceivedNotification(notification: Notification) {
        if let location = notification.object as? CLLocation {
            refreshLocationEntity(location: location)
        }
    }
    
    var currentPosReceived: MKPointAnnotation? = nil
    func refreshLocationEntity(location: CLLocation) {
        if viewIfLoaded?.window != nil {
            // viewController is visible
            
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


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
                
        NotificationCenter.default.addObserver(forName: .onLocationReceived, object: nil, queue: nil)
        {(notification) in self.handleOnLocationReceivedNotification(notification: notification)}
        
        LocationManager.Instance.start()
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


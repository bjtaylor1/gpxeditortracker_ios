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
class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil)
            {(notification) in self.handleDidBecomeActive(notification: notification) }
    }
    
    func handleDidBecomeActive(notification:Notification) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        do {
            if let records = try managedContext.fetch(fetchRequest) as? [NSManagedObject] {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let locationEntity = records.first {
                    refreshLocationEntity(locationEntity: locationEntity)
                }
            }
        } catch {
            NSLog("Failed to fetch LocationEntity records")
        }
    }
    
    func refreshLocationEntity(locationEntity : NSManagedObject) {
        if  let latitude = locationEntity.value(forKey: "latitude") as? Double,
            let longitude = locationEntity.value(forKey: "longitude") as? Double {
            if(currentPosReceived == nil) {
                currentPosReceived = MKPointAnnotation()
                theMap.addAnnotation(currentPosReceived!)
            }
            currentPosReceived?.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let region = MKCoordinateRegion(
                center: currentPosReceived!.coordinate,
                latitudinalMeters: CLLocationDistance(exactly: 3000)!,
                longitudinalMeters: CLLocationDistance(exactly: 3000)!)
            
            //theMap.setRegion(region, animated: true)
            theMap.setRegion(theMap.regionThatFits(region), animated: true)
        }
        
        if let time = locationEntity.value(forKey: "time") as? Date {
        }
    }
    
    var currentPosReceived : MKPointAnnotation?
    @IBOutlet weak var theMap: MKMapView!
    func refresh() {
        
    }

    override func viewDidAppear(_ animated: Bool) {
    }

}


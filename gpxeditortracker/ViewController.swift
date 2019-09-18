//
//  ViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 15/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBAction func refreshClicked(_ sender: Any) {
        refresh()
    }
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var lastReceivedLabel: UILabel!
    @IBOutlet weak var lastUploadedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil)
            {(notification) in self.handleNotification(notification: notification) }
    }
    
    func handleNotification(notification:Notification) {
        refresh()
    }
    
    func refresh() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        do {
            if let records = try managedContext.fetch(fetchRequest) as? [NSManagedObject] {
                let formatter = DateFormatter()
                if let locationEntity = records.first {
                    
                    if  let latitude = locationEntity.value(forKey: "latitude") as? Double,
                        let longitude = locationEntity.value(forKey: "longitude") as? Double {
                        
                        locationLabel.text = String(format: "%.5f, %.5f", latitude, longitude)
                    }
                    
                    if let time = locationEntity.value(forKey: "time") as? Date {
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        lastReceivedLabel.text = formatter.string(from: time)
                    }
                }
            }
        } catch {
            NSLog("Failed to fetch LocationEntity records")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
    }

}


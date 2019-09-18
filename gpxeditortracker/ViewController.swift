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

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var lastReceivedLabel: UILabel!
    @IBOutlet weak var lastUploadedLabel: UILabel!
    
    var container: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard container != nil else {
            fatalError("This view needs a persistent container.")
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil)
            {(notification) in self.handleNotification(notification: notification) }
    }
    
    func handleNotification(notification:Notification) {
        NSLog("didBecomeActiveNotification")
    }

    override func viewDidAppear(_ animated: Bool) {
        NSLog("viewDidAppear")
        locationLabel.text = "the last location"
        lastReceivedLabel.text = "the time it was received"
        lastUploadedLabel.text = "the time it was uploaded"
    }

}


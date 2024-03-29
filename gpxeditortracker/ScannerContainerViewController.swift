//
//  ScannerContainerViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 29/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
class ScannerContainerViewController : UIViewController {
    var notificationName: Notification.Name?

    var obs: NSObjectProtocol?
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelClick(_ sender: Any) {
        dismiss(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scannerViewContainerEmbedSegue" {
            if obs == nil {
                obs = NotificationCenter.default.addObserver(forName: .onCameraAccess, object: nil, queue: OperationQueue.main,
            using: {notification in self.cancelButton.isHidden = false})
            }
            guard let destination = segue.destination as? ScannerViewController else {
                NSLog("WARNING: expected destination to be ScannerViewController")
                return
            }
            if notificationName == nil {
                NSLog("WARNING: notificationName not set")
            }
            destination.notificationName = notificationName
        }
    }
}

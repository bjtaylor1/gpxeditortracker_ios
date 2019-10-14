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
    override func viewDidLoad() {
        /*
        var buttonFrame = cancelButton.frame
        buttonFrame.size = CGSize(width: 120, height: 50    )
        cancelButton.frame = buttonFrame
        cancelButton.alpha = 0.8
        cancelButton.backgroundColor = .white
        cancelButton.isOpaque = true
        cancelButton.layer.cornerRadius = 6
 */
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: .onCameraAccess, object: nil, queue: OperationQueue.main,
                                               using: {notification in self.cancelButton.isHidden = false})
    }
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelClick(_ sender: Any) {
        dismiss(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scannerViewContainerEmbedSegue" {
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

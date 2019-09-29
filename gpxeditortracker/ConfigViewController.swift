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
class ConfigViewController: UIViewController {
    @IBOutlet weak var trackingGroupUnsetLabel: UILabel!
    @IBOutlet weak var trackingGroupLabel: UILabel!
    @IBOutlet weak var trackingGroupSetButton: UIButton!
    @IBOutlet weak var nameTextBox: UITextField!
    var readyToLaunchMap: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .onSetTrackingGroupQrCodeReceived, object: nil, queue: nil)
        {(notification) in self.handleSetTrackingGroupQrCodeReceived(notification: notification)}
        
        NotificationCenter.default.addObserver(forName: .onLocationAuthorized, object: nil, queue: nil)
        { (notification) in self.onLocationAuthorizedReceived(notification: notification)}
    }
    
    func onLocationAuthorizedReceived(notification: Notification) {
        guard let authStatus = notification.object as? CLAuthorizationStatus else {return}
        NSLog("onLocationAuthorizedReceived, readyToLaunchMap = %i", readyToLaunchMap)
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            if readyToLaunchMap {
                performSegue(withIdentifier: "startTrackingSegue", sender: self)
            }
        }
        readyToLaunchMap = false;
    }
    
    func handleSetTrackingGroupQrCodeReceived(notification: Notification) {

        guard let qrCodeString = notification.object as? String else {
            NSLog("Error: QRCode data was not a string")
            return
        }
        guard let qrCodeData = qrCodeString.data(using: .utf8) else {
            NSLog("Error: QRCode string could not be converted to data: %@", qrCodeString)
            return
        }
        
        let jsonDecoder = JSONDecoder()
        do {
            let trackingGroupData = try jsonDecoder.decode(TrackingGroupData.self, from: qrCodeData)
            trackingGroupUnsetLabel?.isHidden = true
            trackingGroupLabel?.isHidden = false
            trackingGroupLabel?.text = trackingGroupData.Name
            trackingGroupSetButton?.setTitle("Change", for: .normal)

        } catch {
            NSLog("The QR code cold not be deserialized to a TrackingGroupData: %@", error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanTrackingGroupQrSegue" {
            guard let scannerViewController = segue.destination as? ScannerViewController else {return}
            scannerViewController.notificationName = .onSetTrackingGroupQrCodeReceived
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "startTrackingSegue" {
            readyToLaunchMap = true
            LocationManager.Instance.requestAuthorization()
            return false;
        }
        else {
            return true;
        }
    }
    
    

}


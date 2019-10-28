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
class ConfigViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var frequencyControlsContainer: UIView!
    let accuracies = [
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyThreeKilometers, title: "3km"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyKilometer, title: "1km"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyHundredMeters, title: "100m"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyNearestTenMeters, title: "10m"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyBest, title: "Best"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyBestForNavigation, title: "Best for navigation")
    ]
    
    let pickerData = ["One", "Two", "Three"]
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accuracies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return accuracies[row].Title
    }
    
    @IBAction func alwaysOnChanged(_ sender: Any) {
        let useFrequency = !alwaysOnSwitch.isOn
        
        UserDefaults.standard.set(useFrequency, forKey: "UseFrequency")
        showFrequencyControls(useFrequency: useFrequency)
    }
    
    @IBOutlet weak var alwaysOnSwitch: UISwitch!
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        UserDefaults.standard.set(row, forKey: "Accuracy")
    }
    
    @IBOutlet weak var trackingGroupUnsetLabel: UILabel!
    @IBOutlet weak var trackingGroupLabel: UILabel!
    @IBOutlet weak var trackingGroupSetButton: UIButton!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var nameTextBox: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    var readyToLaunchMap: Bool = false
    
    @IBOutlet weak var accuracyPicker: UIPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .onSetTrackingGroupQrCodeReceived, object: nil, queue: nil, using:
        {(notification) in self.handleSetTrackingGroupQrCodeReceived(notification: notification)})
        
        NotificationCenter.default.addObserver(forName: .onLocationAuthorized, object: nil, queue: nil, using:
        { (notification) in self.onLocationAuthorizedReceived(notification: notification)})
        
        accuracyPicker.delegate = self
        accuracyPicker.dataSource = self
        
        loadSettings()
    }
    
    @IBAction func nameEditingChange(_ sender: Any) {
        NSLog("nameEditingChange: %@", nameTextBox?.text ?? "(nil)")
        LocationManager.Instance.userName = nameTextBox.text
        UserDefaults.standard.set(nameTextBox?.text, forKey: "trackingName")
    }
    
    @IBAction func clickClearButton(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "trackingGroupJson")
        trackingGroupUnsetLabel.isHidden = false
        trackingGroupLabel.isHidden = true
        trackingGroupSetButton.setTitle("Scan QR code to set", for: .normal)
        clearButton.isHidden = true
    }
    
    func showFrequencyControls(useFrequency: Bool) {
        frequencyLabel.isHidden = !useFrequency
        frequencySlider.isHidden = !useFrequency
    }
    
    func loadSettings() {
        //setTrackingGroupData(trackingGroupJson: "{\"Name\": \"Challenge Ride\", \"Id\": \"791D5EAC-03B5-4055-A59D-C4164FC6A064\"}", save: true)
        
        if let trackingGroupJson = UserDefaults.standard.object(forKey: "trackingGroupJson") as? String {
            setTrackingGroupData(trackingGroupJson: trackingGroupJson, save: false)
        }
        if let name = UserDefaults.standard.string(forKey: "trackingName") {
            LocationManager.Instance.userName = name
            nameTextBox.text = name
        }
        
        let accuracy = UserDefaults.standard.integer(forKey: "Accuracy")
        accuracyPicker.selectRow(accuracy, inComponent: 0, animated: false)

        let useFrequency = UserDefaults.standard.bool(forKey: "UseFrequency")
        alwaysOnSwitch.isOn = !useFrequency
        showFrequencyControls(useFrequency: useFrequency)
    }
    
    func saveTrackingGroupData(trackingGroupJson: String) {
        UserDefaults.standard.set(trackingGroupJson, forKey: "trackingGroupJson")
    }
    
    func setTrackingGroupData(trackingGroupJson: String, save: Bool) {
        do {
            let jsonDecoder = JSONDecoder()
            guard let data = trackingGroupJson.data(using: .utf8) else {
                NSLog("Error: trackingGroupJson could not be converted to data: %@", trackingGroupJson)
                return
            }
            let trackingGroupData = try jsonDecoder.decode(TrackingGroupData.self, from: data)
            if save {
                UserDefaults.standard.set(trackingGroupJson, forKey: "trackingGroupJson")
            }
            LocationManager.Instance.trackingGroupData = trackingGroupData
            trackingGroupUnsetLabel?.isHidden = true
            trackingGroupLabel?.isHidden = false
            trackingGroupLabel?.text = trackingGroupData.Name
            trackingGroupSetButton?.setTitle("Change", for: .normal)
            clearButton.isHidden = false
        } catch {
            DispatchQueue.main.async {
                self.showError(title: "Invalid QR code", message: "The QR code scanned is not a valid GPXEditor tracking group.")
            }
        }
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)

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
        
        setTrackingGroupData(trackingGroupJson: qrCodeString, save: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scanTrackingGroupQrSegue" {
            guard let scannerContainerViewController = segue.destination as? ScannerContainerViewController else {
                NSLog("WARNING - expected destination to be ScannerContainerViewController")
                return
            }
            scannerContainerViewController.notificationName = .onSetTrackingGroupQrCodeReceived
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "startTrackingSegue" {
            if LocationManager.Instance.trackingGroupData == nil {
                showError(title: "Tracking group not set", message: "Please set a tracking group by clicking the button above and then scanning the tracking group's QR code on the GPXEditor site.")
                return false
            }
            else if LocationManager.Instance.userName == nil || LocationManager.Instance.userName?.count ?? 0 < 3 {
                showError(title: "Name not set", message: "Please enter a name of at least 3 characters.")
                return false
            }
        }
        return true
    }
    
}


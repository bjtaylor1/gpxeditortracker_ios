//
//  ConfigTableViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 26/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
class ConfigTableViewController : UITableViewController, ReloadSectionDelegate, RequestUserNameChangeDelegate {


    let trackingGroupSection : TrackingGroupSection
    let nameSection : NameSection
    let frequencySection : FrequencySection
    let accuracySection : AccuracySection
    let startTrackingSection : SettingsSection
    let sections : [SettingsSection]
    
    required init?(coder: NSCoder) {
        UserDefaults.standard.register(defaults:
        [
            "UpdateFrequencyMinutes": Float(15),
            "OnAllTheTime": false
        ])
        
        let trackingGroupJson = UserDefaults.standard.string(forKey: "trackingGroupJson")
        trackingGroupSection = TrackingGroupSection(trackingGroupJsonSetting: trackingGroupJson)
        
        let onAllTheTime = UserDefaults.standard.bool(forKey: "OnAllTheTime")
        let ufm = UserDefaults.standard.float(forKey: "UpdateFrequencyMinutes")
        frequencySection = FrequencySection(onAllTheTime: onAllTheTime, frequencyMinutes: ufm)
        
        let accuracy = UserDefaults.standard.string(forKey: "Accuracy") ?? "1km"
        accuracySection = AccuracySection(accuracyName: accuracy)
        
        let userName = UserDefaults.standard.string(forKey: "trackingName") ?? ""
        nameSection = NameSection(userName: userName)

        startTrackingSection = SettingsSection(name: "StartTracking", settings: ["StartTracking"])
        sections = [trackingGroupSection, nameSection, frequencySection, accuracySection, startTrackingSection]
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: .onSetTrackingGroupQrCodeReceived, object: nil, queue: OperationQueue.main, using:
         {(notification) in self.handleSetTrackingGroupQrCodeReceived(notification: notification)})
        
        theTableView.tableFooterView = UIView() // gets rid of extraneous lines at the bottom
    }
    
    func dismissKeyboard() {
        view.endEditing(true);
    }
    
    func handleSetTrackingGroupQrCodeReceived(notification: Notification) {

        guard let qrCodeString = notification.object as? String else {
            NSLog("Error: QRCode data was not a string")
            return
        }
        
        guard let trackingGroup = TrackingGroupData.parse(trackingGroupJson: qrCodeString) else {
            showError(title: "Invalid QR code", message: "The QR code scanned is not a valid GPXEditor tracking group.")
            return
        }
        
        UserDefaults.standard.set(qrCodeString, forKey: "trackingGroupJson")
        trackingGroupSection.trackingGroup = trackingGroup
        reloadSection(vm: trackingGroupSection)
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)

    }
    
    @IBOutlet var theTableView: UITableView!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].getSettings().count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let setting = section.getSettings()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: setting)!
        
        if let theCell = cell as? UpdateSettingsSection {
            theCell.updateSection(section: section, delegateTarget: self)
        }
        
        if let theCell = cell as? NameCellView {
            theCell.requestUserNameChangeDelegate = self
        }
        return cell
    }
    
    func reloadSection(vm: SettingsSection) {
        guard let sectionIndex = sections.firstIndex(of: vm) else {
            NSLog("WARN: Could not find section to update")
            return
        }
        theTableView.reloadSections(IndexSet([sectionIndex]), with: .automatic)
    }
    
    func requestUserNameChange(sender: NameCellView) {
        let alert = UIAlertController(title: "Name", message: "Please enter your name as it will appear on the map", preferredStyle: .alert)
        alert.addTextField(configurationHandler:
            {textField in textField.text = self.nameSection.userName})
        alert.addAction(UIAlertAction(title:"Cancel", style: .cancel, handler: {action in NSLog("alert cancelled")}))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
            guard let newUserName = alert.textFields?.first?.text else {
                NSLog("WARN: newUserName null")
                return
            }
            self.nameSection.userName = newUserName
            UserDefaults.standard.set(newUserName, forKey: "trackingName")
            sender.updateView()
        }))
        present(alert, animated: true)
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
            
            if trackingGroupSection.trackingGroup == nil {
                showError(title: "Tracking group not set", message: "Please set a tracking group by clicking the button above and then scanning the tracking group's QR code on the GPXEditor site.")
                return false
            }
            else if nameSection.userName?.count ?? 0 < 3 {
                showError(title: "Name not set", message: "Please enter a name of at least 3 characters.")
                return false
            }
        }
        return true
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        if identifier == "startTrackingSegue" {
            LocationManager.Instance.trackingGroupData = trackingGroupSection.trackingGroup
            LocationManager.Instance.userName = nameSection.userName
            LocationManager.Instance.updateFrequencyMinutes = frequencySection.frequencyMinutes
        }
    }
}









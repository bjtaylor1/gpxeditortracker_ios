//
//  ConfigTableViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 26/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
class ConfigTableViewController : UITableViewController, ReloadSectionDelegate {


    let trackingGroupSection : TrackingGroupSection
    let frequencySection : FrequencySection
    let sections : [SettingsSection]
    
    required init?(coder: NSCoder) {
        UserDefaults.standard.register(defaults:
        [
            "UpdateFrequencyMinutes": Float(15),
            "OnAllTheTime": false
        ])
        
        trackingGroupSection = TrackingGroupSection(trackingGroupJsonSetting: UserDefaults.standard.string(forKey: "trackingGroupJson"))
        let onAllTheTime = UserDefaults.standard.bool(forKey: "OnAllTheTime")
        let ufm = UserDefaults.standard.float(forKey: "UpdateFrequencyMinutes")
        frequencySection = FrequencySection(onAllTheTime: onAllTheTime, frequencyMinutes: ufm)
        sections = [trackingGroupSection, frequencySection]
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: .onSetTrackingGroupQrCodeReceived, object: nil, queue: OperationQueue.main, using:
         {(notification) in self.handleSetTrackingGroupQrCodeReceived(notification: notification)})
        
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
        return cell
    }
    
    func reloadSection(vm: SettingsSection) {
        guard let sectionIndex = sections.firstIndex(of: vm) else {
            NSLog("WARN: Could not find section to update")
            return
        }
        theTableView.reloadSections(IndexSet([sectionIndex]), with: .automatic)
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
}

class SettingsSection : Equatable {
    static func == (lhs: SettingsSection, rhs: SettingsSection) -> Bool {
        return lhs.Name == rhs.Name
    }
    
    private let settings : [String]
    let Name : String
    init(name: String, settings: [String]) {
        Name = name
        self.settings = settings
    }
    
    func getSettings() -> [String] {
        return settings.filter({setting in showSetting(setting: setting)});
    }
    func showSetting(setting: String) -> Bool {
        return true
    }
}

class TrackingGroupSection : SettingsSection {
    var trackingGroup: TrackingGroupData?
    
    init(trackingGroupJsonSetting : String?) {
        if let trackingGroupJson = trackingGroupJsonSetting {
            trackingGroup = TrackingGroupData.parse(trackingGroupJson: trackingGroupJson)
        }
        super.init(name: "TrackingGroup", settings: ["TrackingGroupTitle", "TrackingGroupSet", "TrackingGroupUnset"])
    }
    
    override func showSetting(setting: String) -> Bool {
        if setting == "TrackingGroupSet" {
            return (trackingGroup != nil)
        } else if setting == "TrackingGroupUnset" {
            return (trackingGroup == nil)
        } else {
            return super.showSetting(setting: setting)
        }
    }
    
}

class FrequencySection : SettingsSection {
    var onAllTheTime : Bool
    var frequencyMinutes: Float
    init(onAllTheTime: Bool, frequencyMinutes: Float) {
        self.onAllTheTime = onAllTheTime
        self.frequencyMinutes = frequencyMinutes
        super.init(name: "Frequency", settings: ["SwitchSetting", "FrequencySetting"])
    }
    override func showSetting(setting: String) -> Bool {
        if setting == "FrequencySetting" {
            return !onAllTheTime
        }
        return super.showSetting(setting: setting)
    }
}

protocol ReloadSectionDelegate : class {
    func reloadSection(vm : SettingsSection)
}

protocol UpdateSettingsSection {
    func updateSection(section: SettingsSection, delegateTarget: ReloadSectionDelegate)
}

class ConfigUITableViewCell<T : SettingsSection> : UITableViewCell, UpdateSettingsSection {
    var viewModel : T? = nil
    weak var delegate : ReloadSectionDelegate?
    func updateSection(section: SettingsSection, delegateTarget: ReloadSectionDelegate) {
        guard let specificSection = section as? T else {
            NSLog("WARN: passed wrong type of section (%@) to %@", String(describing: T.self), String(describing: self))
            return
        }
        viewModel = specificSection
        delegate = delegateTarget
        updateView()
    }
    
    func updateView() {
    }
}

class TrackingGroupUnsetTableViewCell : ConfigUITableViewCell<TrackingGroupSection> {
}

class TrackingGroupSetTableViewCell : ConfigUITableViewCell<TrackingGroupSection> {
    @IBOutlet weak var trackingGroupNameLabel: UILabel!
    override func updateView() {
        guard let trackingGroupName = viewModel?.trackingGroup?.Name else {
            NSLog("WARN: trackingGroup.Name not set when it should be")
            return
        }
        trackingGroupNameLabel.text = trackingGroupName
    }
    @IBAction func clearTrackingGroup(_ sender: Any) {
        guard let vm = viewModel else {
            NSLog("WARN: viewModel not set in clearTrackingGroup")
            return
        }
        UserDefaults.standard.removeObject(forKey: "trackingGroupJson")
        vm.trackingGroup = nil
        delegate?.reloadSection(vm: vm)
    }
}

class SwitchCellView : ConfigUITableViewCell<FrequencySection> {
    @IBOutlet weak var theSwitch: UISwitch!

    @IBAction func onAllTheTimeSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "OnAllTheTime")
        viewModel!.onAllTheTime = sender.isOn
        delegate?.reloadSection(vm: viewModel!)
    }
    
    override func updateView() {
        theSwitch.isOn = viewModel!.onAllTheTime
    }
}

class FrequencyCellView : ConfigUITableViewCell<FrequencySection> {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let actualVal = powf( sender.value, 4)
        UserDefaults.standard.set(actualVal, forKey: "UpdateFrequencyMinutes")
        viewModel!.frequencyMinutes = actualVal
        updateLabel(val: actualVal)
    }
    
    override func updateView() {
        slider.minimumValue = 1
        slider.maximumValue = powf(60, 0.25)
        slider.value = powf(viewModel!.frequencyMinutes, 0.25)
        updateLabel(val: viewModel!.frequencyMinutes)
    }
    
    func updateLabel(val: Float) {
        frequencyLabel.text = String(Int(val.rounded()))
    }
}

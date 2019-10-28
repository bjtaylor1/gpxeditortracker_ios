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

class NoSeparatorCellView : UITableViewCell {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
    }
}

class NameSection : SettingsSection {
    var userName : String?
    init(userName:String) {
        self.userName = userName
        super.init(name: "Name", settings: ["Name"])
    }
}

class AccuracySection : SettingsSection {
    var expanded : Bool = false
    var accuracyName : String?
    init(accuracyName : String) {
        self.accuracyName = accuracyName
        super.init(name: "Accuracy", settings: ["AccuracyHeader", "Accuracy"])
    }
    
    override func showSetting(setting: String) -> Bool {
        if setting == "Accuracy" {
            return expanded
        } else {
            return super.showSetting(setting: setting)
        }
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


protocol RequestUserNameChangeDelegate : class {
    func requestUserNameChange(sender: NameCellView)
}

class NameCellView : ConfigUITableViewCell<NameSection> {

    weak var requestUserNameChangeDelegate : RequestUserNameChangeDelegate?
    
    @IBOutlet weak var nameLabel: UILabel!
    override func updateView() {
        guard let userName = viewModel?.userName else {
            NSLog("WARN: userName not set")
            return
        }
        nameLabel.text = userName
    }
    @IBAction func clickChange(_ sender: Any) {
        requestUserNameChangeDelegate?.requestUserNameChange(sender: self)
    }
    @IBAction func nameEditingChanged(_ sender: UITextField) {
        guard let vm = viewModel else {
            NSLog("WARN: viewModel was null in nameValueChanged")
            return
        }
        vm.userName = sender.text
        UserDefaults.standard.set(sender.text, forKey: "trackingName")
        //don't need to trigger the delegate, but would if anything changed as a result of it
    }
}

class AccuracyHeaderCellView : ConfigUITableViewCell<AccuracySection> {
    @IBOutlet weak var expand: UIButton!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBAction func expand(_ sender: Any) {
        guard let vm = viewModel else {
            NSLog("WARN: viewModel not set in AccuracyHeaderCellView")
            return
        }
        vm.expanded = true
        delegate?.reloadSection(vm: vm)
    }
    

    override func updateView() {
        accuracyLabel.text = viewModel?.accuracyName
    }
}

class AccuracyCellView : ConfigUITableViewCell<AccuracySection>,
UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var accuracyPicker: UIPickerView!
    let accuracies = [
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyThreeKilometers, title: "3km"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyKilometer, title: "1km"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyHundredMeters, title: "100m"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyNearestTenMeters, title: "10m"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyBest, title: "Best"),
        LocationAccuracyChoice(accuracy: kCLLocationAccuracyBestForNavigation, title: "Best for navigation")
    ]
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accuracies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return accuracies[row].Title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let accuracy = accuracies[row]
        UserDefaults.standard.set(accuracy.Title, forKey: "Accuracy")
        guard let vm = viewModel else {
            NSLog("WARN: viewModel not set in AccuracyCellView")
            return
        }
        vm.accuracyName = accuracy.Title
        vm.expanded = false
        delegate?.reloadSection(vm: vm)
    }
    
    @IBOutlet weak var picker: UIPickerView!
    override func updateView() {
        picker.delegate = self
        picker.dataSource = self
        
        if let accuracyValue = viewModel?.accuracyName,
            let index = accuracies.firstIndex(where: {a in a.Title == accuracyValue}) {
            accuracyPicker.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    @IBAction func collapse(_ sender: Any) {
        guard let vm = viewModel else {
            NSLog("WARN: viewModel null in AccuracyCellView")
            return
        }
        vm.expanded = false
        delegate?.reloadSection(vm: vm)
    }
}

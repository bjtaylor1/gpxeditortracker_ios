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

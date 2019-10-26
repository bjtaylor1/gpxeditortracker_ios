//
//  ConfigTableViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 26/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
class ConfigTableViewController : UITableViewController, SwitchCellViewDelegate {

    
    let frequencySection = FrequencySection(
        onAllTheTime: UserDefaults.standard.bool(forKey: "OnAllTheTime"),
        frequencyMinutesRoot: UserDefaults.standard.float(forKey: "UpdateFrequencyMinutesRoot")
    )
    let sections : [SettingsSection]
    
    required init?(coder: NSCoder) {
        sections = [frequencySection]
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
        
        /*
        if let switchCell = cell as? SwitchCellView {
            switchCell.delegate = self
            switchCell.theSwitch.isOn = frequencySection.onAllTheTime
        }
        */
        
        if let theCell = cell as? ConfigUITableViewCell {
            theCell.update(section: section)
        }
        return cell
    }
    
    func onAllTheTimeSettingChanged(newVal: Bool) {
        guard let frequencySectionIndex = sections.firstIndex(of: frequencySection) else {
            NSLog("WARN: frequencySectionIndex null")
            return
        }
        frequencySection.onAllTheTime = newVal
        theTableView.reloadSections(IndexSet([frequencySectionIndex]), with: .automatic)
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

class FrequencySection : SettingsSection {
    var onAllTheTime : Bool
    var frequencyMinutesRoot: Float
    init(onAllTheTime: Bool, frequencyMinutesRoot: Float) {
        self.onAllTheTime = onAllTheTime
        self.frequencyMinutesRoot = frequencyMinutesRoot
        super.init(name: "Frequency", settings: ["SwitchSetting", "FrequencySetting"])
    }
    override func showSetting(setting: String) -> Bool {
        if setting == "FrequencySetting" {
            return !onAllTheTime
        }
        return super.showSetting(setting: setting)
    }
}


protocol SwitchCellViewDelegate : class {
    func onAllTheTimeSettingChanged(newVal: Bool)
}


class ConfigUITableViewCell : UITableViewCell {
    func update(section: SettingsSection) {
    }
}

class SwitchCellView : ConfigUITableViewCell {
    weak var delegate : SwitchCellViewDelegate?
    @IBOutlet weak var theSwitch: UISwitch!

    @IBAction func onAllTheTimeSwitchChanged(_ sender: Any) {
        delegate?.onAllTheTimeSettingChanged(newVal: theSwitch.isOn)
    }
    
    override func update(section: SettingsSection) {
        guard let frequencySection = section as? FrequencySection else {
            NSLog("WARN: SwitchCellView.update passed wrong type of section")
            return
        }
        theSwitch.isOn = frequencySection.onAllTheTime
    }
}

class FrequencyCellView : ConfigUITableViewCell {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        updateLabel(val: sender.value)
    }
    
    override func update(section: SettingsSection) {
        guard let frequencySection = section as? FrequencySection else {
            NSLog("WARN: FrequencyCellView.update passed wrong type of section");
            return
        }
        slider.minimumValue = 1
        slider.maximumValue = Float(60).squareRoot()
        slider.value = frequencySection.frequencyMinutesRoot
        updateLabel(val: frequencySection.frequencyMinutesRoot)
    }
    
    func updateLabel(val: Float) {
        let roundedVal = (val*val).rounded()
        frequencyLabel.text = String(Int(roundedVal))
    }
}

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

    let frequencySection = FrequencySection(onAllTheTime: UserDefaults.standard.bool(forKey: "OnAllTheTime"))
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
        let setting = sections[indexPath.section].getSettings()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: setting)!
        if let switchCell = cell as? SwitchCellView {
            switchCell.delegate = self
            switchCell.theSwitch.isOn = frequencySection.onAllTheTime
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
    init(onAllTheTime: Bool) {
        self.onAllTheTime = onAllTheTime
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

class SwitchCellView : UITableViewCell {
    weak var delegate : SwitchCellViewDelegate?
    @IBOutlet weak var theSwitch: UISwitch!

    @IBAction func onAllTheTimeSwitchChanged(_ sender: Any) {
        delegate?.onAllTheTimeSettingChanged(newVal: theSwitch.isOn)
    }
}


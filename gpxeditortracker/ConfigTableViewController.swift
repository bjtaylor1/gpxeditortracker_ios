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

    var onAllTheTime: Bool = true
    
    @IBOutlet weak var labelCell: UITableViewCell!
    @IBOutlet weak var frequencyCell: UITableViewCell!
    
    let allSettings = [[
        "SwitchSetting",
        "FrequencySetting"
    ]];
    var settings : [[String]] = [[]]
    
    func includeSetting(setting : String) -> Bool {
        if setting == "FrequencySetting" {
            return !onAllTheTime
        }
        else {
            return true
        }
    }
    
    func refresh() {
        settings = allSettings.map(
            {(sectionStrings) in return sectionStrings.filter(
                {s in includeSetting(setting: s)})})
    }
    
    @IBOutlet var theTableView: UITableView!
    @IBAction func switchChanged(_ sender: Any) {
        
    }
    override func viewDidLoad() {
        theTableView.rowHeight = UITableView.automaticDimension
        refresh()
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: setting)!
        
        if let switchCell = cell as? SwitchCellView {
            switchCell.delegate = self
        }
        return cell
    }
    
    func onAllTheTimeSettingChanged(newVal: Bool) {
        onAllTheTime = newVal
        refresh()
        theTableView.reloadData()
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


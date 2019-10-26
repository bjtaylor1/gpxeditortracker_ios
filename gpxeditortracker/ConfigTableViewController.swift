//
//  ConfigTableViewController.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 26/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
class ConfigTableViewController : UITableViewController {

    @IBOutlet weak var labelCell: UITableViewCell!
    @IBOutlet weak var frequencyCell: UITableViewCell!
    
    let settings = [[
        "SwitchSetting",
        "FrequencySetting"
    ]];
    
    @IBOutlet var theTableView: UITableView!
    @IBAction func switchChanged(_ sender: Any) {
        
    }
    override func viewDidLoad() {
        theTableView.rowHeight = UITableView.automaticDimension
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
        return cell
    }
}

class SwitchCellView : UITableViewCell {
    @IBOutlet weak var theSwitch: UISwitch!
    
}


//
//  SettingsSection.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 28/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit

protocol UpdateSettingsSection {
    func updateSection(section: SettingsSection, delegateTarget: ReloadSectionDelegate)
}

protocol RequestUserNameChangeDelegate : class {
    func requestUserNameChange(sender: NameCellView)
}


protocol ReloadSectionDelegate : class {
    func reloadSection(vm : SettingsSection)
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

class NoSeparatorCellView : UITableViewCell {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
    }
}

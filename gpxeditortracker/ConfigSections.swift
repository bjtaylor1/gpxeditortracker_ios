//
//  TrackingGroupSection.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 28/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation

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

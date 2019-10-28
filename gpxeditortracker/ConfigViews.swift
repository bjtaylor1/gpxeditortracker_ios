//
//  ConfigViews.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 28/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

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

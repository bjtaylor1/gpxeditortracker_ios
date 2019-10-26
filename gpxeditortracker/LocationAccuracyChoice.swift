//
//  LocationAccuracyChoice.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 26/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import CoreLocation
class LocationAccuracyChoice {
    let Accuracy: CLLocationAccuracy
    let Title: String
    init(accuracy: CLLocationAccuracy, title: String) {
        Accuracy = accuracy
        Title = title
    }
}

//
//  LocationManager.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 29/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager : NSObject, CLLocationManagerDelegate {
    static let Instance = LocationManager()
    let locationManager = CLLocationManager()
    var lastLocationReceived: Date? = nil
    var trackingGroupData: TrackingGroupData? = nil
    var name: String? = nil
    
    override init() {
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.fff"
    }
    
    #if DEBUG
    let minSecondsBetweenUpdates = TimeInterval(integerLiteral: 2)
    #else
    let minSecondsBetweenUpdates = TimeInterval(integerLiteral: 600)
    #endif
    
    func start() {
        NSLog("starting LocationManager...")
        
        locationManager.distanceFilter = 100
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    let dateFormatter = DateFormatter()
    func shouldNotifyLocationReceivedAt(time: Date) -> Bool {
        
        guard let lastLocationReceivedValue = lastLocationReceived else {return true}
        let earliestTimeToNotify = lastLocationReceivedValue.addingTimeInterval(minSecondsBetweenUpdates)
        let shouldNotify: (Bool) = (time >= earliestTimeToNotify)
        return shouldNotify;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            if lastLocationReceived == nil || shouldNotifyLocationReceivedAt(time: lastLocation.timestamp) {
                NSLog("Received location: %.5f, %.5f", lastLocation.coordinate.latitude, lastLocation.coordinate.longitude)
                NotificationCenter.default.post(name: .onLocationReceived, object: lastLocation)
                lastLocationReceived = lastLocation.timestamp
            }
        }
    }
}

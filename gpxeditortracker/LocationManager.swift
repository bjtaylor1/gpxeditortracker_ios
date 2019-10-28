//
//  LocationManager.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 29/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
class LocationManager : NSObject, CLLocationManagerDelegate {
    static let Instance = LocationManager()
    let locationManager = CLLocationManager()
    var lastAccurateLocationReceived: CLLocation? = nil
    var lastLocationUpdated: CLLocation? = nil
    var trackingGroupData: TrackingGroupData? = nil
    var userName: String? = nil
    let userId: UUID
    var updateFrequencyMinutes: Float = 15
    

    override init() {
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.fff"
        
        if let savedUserId = UserDefaults.standard.string(forKey: "userId"), let saveUserIdUuid = UUID(uuidString: savedUserId) {
            userId = saveUserIdUuid
        } else {
            userId = UUID()
            UserDefaults.standard.set(userId.uuidString, forKey: "userId")
        }
    }
    
    #if DEBUG
    let minSecondsBetweenUpdates = TimeInterval(integerLiteral: 10)
    #else
    let minSecondsBetweenUpdates = TimeInterval(integerLiteral: 120)
    #endif
    
    func start() {
        NSLog("starting LocationManager...")
        
        locationManager.distanceFilter = 100
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    func stop() {
        NSLog("stopping LocationManager")
        locationManager.stopUpdatingLocation()
        lastLocationUpdated = nil
        lastAccurateLocationReceived = nil
        sendRemoveUserData()
    }
    
    func sendRemoveUserData() {
        guard let trackingGroupDataValue = trackingGroupData else {
            NSLog("WARN: trackingGroupData not set")
            return
        }
        
        let removeUserData = RemoveTrackingUserData(trackingGroup: trackingGroupDataValue.Id, userId: userId)
        NSLog("Creating the updateLocationData")
        do {
            NSLog("Creating the json encoder")
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonData = try jsonEncoder.encode(removeUserData)
            let url = URL(string: "https://gpxeditor.azurewebsites.net/api/tracking")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let errorVal = error {
                    NSLog("DELETE ERROR: %@", errorVal.localizedDescription)
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200, httpResponse.statusCode < 300 {
                        NSLog("Successfully removed user data")
                    }
                    else {
                        NSLog("DELETE returned %i", httpResponse.statusCode)
                    }
                }
                if let dataValue = data, let dataString = String(data: dataValue, encoding: .utf8) {
                    if dataString != "" {
                        NSLog("DELETE data: %@", dataString)
                    }
                }
            }
            task.resume()
        } catch {
            NSLog("ERROR: %@", error.localizedDescription)
        }
    }
    
    let dateFormatter = DateFormatter()
    func shouldNotifyLocationReceivedAt(location: CLLocation) -> Bool {
        guard let lastAccurateLocationReceivedValue = lastLocationUpdated else {
            NSLog("lastLocationReceived is nil - returning true")
            return true
        }
        let earliestTimeToNotify = lastAccurateLocationReceivedValue.timestamp.addingTimeInterval(minSecondsBetweenUpdates)
        let shouldNotify: (Bool) = (location.timestamp >= earliestTimeToNotify || location.distance(from: lastAccurateLocationReceivedValue) > 150)
        return shouldNotify;
    }
    
    func needAccurateLocation(currentTime: Date) -> Bool {
        if let lastAccurateLocationReceivedValue = lastAccurateLocationReceived  {
            guard let timeInterval = TimeInterval(exactly: updateFrequencyMinutes) else {
                NSLog("WARN: timeInterval init returned null")
                return true
            }
            let timeNeeded = lastAccurateLocationReceivedValue.timestamp.addingTimeInterval(timeInterval)
            return currentTime > timeNeeded
        } else {
            return true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
             if lastLocation.horizontalAccuracy < 100 {
                accurateLocationReceived(lastLocation: lastLocation)
             } else {
                //do we need an accurate one?
                if needAccurateLocation(currentTime: lastLocation.timestamp) {
                    upgradeAccuracyRequirement()
                }
            }
        }
    }
    
    func upgradeAccuracyRequirement() {
        NSLog("Upgrade Accuracy Requirement")
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func downgradeAccuracyRequirement() {
        NSLog("Downgrade Accuracy Requirement")
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    func accurateLocationReceived(lastLocation: CLLocation) {
        lastAccurateLocationReceived = lastLocation
        downgradeAccuracyRequirement()
        let shouldUpdate = shouldNotifyLocationReceivedAt(location: lastLocation)
        NSLog("Received location: %.5f, %.5f, %.5f, shouldUpdate = %i, thread = %@", lastLocation.coordinate.latitude, lastLocation.coordinate.longitude, lastLocation.horizontalAccuracy, shouldUpdate, Thread.current.description)
            if shouldUpdate {
                NotificationCenter.default.post(name: .onLocationReceived, object: lastLocation)
                uploadLocation(location: lastLocation)
                lastLocationUpdated = lastLocation
            }
    }
    
    func uploadLocation(location: CLLocation) {
        guard let trackingGroupDataValue = self.trackingGroupData else {
            NSLog("WARNING: trackingGroupData nil")
            return
        }
        guard let nameValue = userName else {
            NSLog("WARNING: name not set")
            return
        }
        
        let updateLocationData = UpdateLocationData(trackingGroup: trackingGroupDataValue.Id, userId: userId, userName: nameValue, lat: location.coordinate.latitude, lon: location.coordinate.longitude, time: location.timestamp)
        NSLog("Creating the updateLocationData")
        do {
            NSLog("Creating the json encoder")
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonData = try jsonEncoder.encode(updateLocationData)
            let url = URL(string: "https://gpxeditor.azurewebsites.net/api/tracking")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let errorVal = error {
                    NSLog("POST ERROR: %@", errorVal.localizedDescription)
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200, httpResponse.statusCode < 300 {
                        NotificationCenter.default.post(name: .onLocationUploaded, object: location)
                    }
                    else {
                        NSLog("POST returned %i", httpResponse.statusCode)
                    }
                }
                if let dataValue = data, let dataString = String(data: dataValue, encoding: .utf8) {
                    if dataString != "" {
                        NSLog("POST data: %@", dataString)
                    }
                }
            }
            task.resume()
        } catch {
            NSLog("ERROR: %@", error.localizedDescription)
        }
    }
}

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
    let userId: UUID
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
                uploadLocation(location: lastLocation)
                lastLocationReceived = lastLocation.timestamp
            }
        }
    }
    
    func uploadLocation(location: CLLocation) {
        guard let trackingGroupDataValue = self.trackingGroupData else {
            NSLog("WARNING: trackingGroupData nil")
            return
        }
        guard let nameValue = name else {
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
                    if httpResponse.statusCode >= 300 {
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

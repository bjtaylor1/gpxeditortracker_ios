//
//  TrackingGroupData.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 23/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
struct TrackingGroupData : Codable {
    var Id: UUID;
    var Name:String
    
    static func parse(trackingGroupJson: String) -> TrackingGroupData? {
        let jsonDecoder = JSONDecoder()
        guard let data = trackingGroupJson.data(using: .utf8) else {
            NSLog("ERROR: trackingGroupJson could not be converted to data: %@", trackingGroupJson)
            return nil
        }
        do {
            let trackingGroupData = try jsonDecoder.decode(TrackingGroupData.self, from: data)
            return trackingGroupData
        } catch {
            NSLog("ERROR: %@", error.localizedDescription)
            return nil
        }
    }
}

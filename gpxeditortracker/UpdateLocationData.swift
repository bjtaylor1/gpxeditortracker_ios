//
//  UpdateLocationData.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 30/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation

class UpdateLocationData : Codable {
    init(trackingGroup: UUID, userId: UUID, userName: String, lat: Double, lon: Double, time:Date) {
        TrackingGroup = trackingGroup
        UserId = userId;
        UserName = userName;
        Lat = lat;
        Lon = lon;
        Time = time;
    }
    let TrackingGroup : UUID;
    let UserId: UUID;
    let UserName: String;
    let Lat: Double;
    let Lon: Double;
    let Time: Date;
}


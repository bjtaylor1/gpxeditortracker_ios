//
//  RemoveTrackingUserData.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 20/10/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation
class RemoveTrackingUserData : Codable {
    init(trackingGroup: UUID, userId: UUID) {
        TrackingGroup = trackingGroup;
        UserId = userId;
    }
    let TrackingGroup : UUID;
    let UserId: UUID;
}

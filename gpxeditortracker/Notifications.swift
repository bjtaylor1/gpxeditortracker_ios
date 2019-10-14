//
//  Notifications.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 21/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let onLocationReceived = Notification.Name("onLocationReceived")
    static let onSetTrackingGroupQrCodeReceived = Notification.Name("onSetTrackingGroupQrCodeReceived")
    static let onLocationAuthorized = Notification.Name("onLocationAuthorized")
    static let onCameraAccess = Notification.Name("onCameraAccess")
}

//
//  NATOperation.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-26.
//  Copyright © 2015 Nick Toumpelis. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation

/// Provides a base class for all the operations that the app can perform.
class NATOperation: NSObject, CLLocationManagerDelegate
{
    /// An instance of CLLocationManager to provide monitoring and ranging facilities.
    lazy var locationManager = CLLocationManager()

    /// The beacon region that will be used as the reference for monitoring and ranging.
    let beaconRegion: CLBeaconRegion = {
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: "416C0120-5960-4280-A67C-A2A9BB166D0F")!, identifier: "Identifier")
        region.notifyEntryStateOnDisplay = true
        return region
    }()

    /**
     Sets the location manager delegate to self. It is called when an instance is ready to process location
     manager delegate calls.
     */
    func activateLocationManagerNotifications() {
        locationManager.delegate = self
    }
}

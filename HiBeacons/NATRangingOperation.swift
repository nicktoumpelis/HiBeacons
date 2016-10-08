//
//  NATRangingOperation.swift
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

/// Lists the methods that a ranging delegate should implement to be notified for all ranging operation events.
protocol NATRangingOperationDelegate
{
    /// Triggered when the ranging operation has started successfully.
    func rangingOperationDidStartSuccessfully()

    /// Triggered when the ranging operation has failed to start.
    func rangingOperationDidFailToStart()

    /// Triggered when the ranging operation has failed to start due to the last authorization denial.
    func rangingOperationDidFailToStartDueToAuthorization()

    /// Triggered when the ranging operation has stopped successfully.
    func rangingOperationDidStopSuccessfully()

    /**
     Triggered when the ranging operation has detected beacons belonging to a specific given beacon region.
     :param: beacons An array of provided beacons that the ranging operation detected.
     :param: region A provided region whose beacons the operation is trying to range.
     */
    func rangingOperationDidRangeBeacons(_ beacons: [AnyObject]!, inRegion region: CLBeaconRegion!)
}

/**
 Contains all the process logic required to successfully monitor for events related to ranging beacons belonging to a 
 specific beacon region.
 */
final class NATRangingOperation: NATOperation
{
    /// The delegate for a ranging operation.
    var delegate: NATRangingOperationDelegate?

    /// Starts the beacon ranging process.
    func startRangingForBeacons() {
        activateLocationManagerNotifications()

        print("Turning on ranging...")

        if !CLLocationManager.locationServicesEnabled() {
            print("Couldn't turn on ranging: Location services are not enabled.")
            delegate?.rangingOperationDidFailToStart()
            return
        }

        if !CLLocationManager.isRangingAvailable() {
            print("Couldn't turn on ranging: Ranging is not available.")
            delegate?.rangingOperationDidFailToStart()
            return
        }

        if !locationManager.rangedRegions.isEmpty {
            print("Didn't turn on ranging: Ranging already on.")
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            turnOnRanging()
        case .denied, .restricted:
            print("Couldn't turn on ranging: Required Location Access (When In Use) missing.")
            delegate?.rangingOperationDidFailToStartDueToAuthorization()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Turns on ranging (after all the checks have been passed).
    func turnOnRanging() {
        locationManager.startRangingBeacons(in: beaconRegion)
        print("Ranging turned on for beacons in region: \(beaconRegion)")
        delegate?.rangingOperationDidStartSuccessfully()
    }

    /// Stops the ranging process.
    func stopRangingForBeacons() {
        if locationManager.rangedRegions.isEmpty {
            print("Didn't turn off ranging: Ranging already off.")
            return
        }

        locationManager.stopRangingBeacons(in: beaconRegion)

        delegate?.rangingOperationDidStopSuccessfully()
        
        print("Turned off ranging.")
    }
}

// MARK: Location manager delegate methods
extension NATRangingOperation
{
    /// This method is triggered when there is a change in the authorization status for the location manager.
    func locationManager(_ manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("Location Access (Always) granted!")
            delegate?.rangingOperationDidStartSuccessfully()
            turnOnRanging()
        } else if status == .authorizedWhenInUse {
            print("Location Access (When In Use) granted!")
            delegate?.rangingOperationDidStartSuccessfully()
            turnOnRanging()
        } else if status == .denied || status == .restricted {
            print("Location Access (When In Use) denied!")
            delegate?.rangingOperationDidFailToStart()
        }
    }

    /// This method gets triggered when the location manager is ranging beacons.
    func locationManager(_ manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        delegate?.rangingOperationDidRangeBeacons(beacons, inRegion: region)
    }
}

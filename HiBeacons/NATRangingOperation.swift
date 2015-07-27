//
//  NATRanging.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-26.
//  Copyright (c) 2015 Nick Toumpelis.
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
    /**
        Triggered when the ranging operation has started successfully.
     */
    func rangingOperationDidStartSuccessfully()

    /**
        Triggered when the ranging operation has failed to start.
     */
    func rangingOperationDidFailToStart()

    /**
        Triggered when the ranging operation has failed to start due to the last authorization denial.
     */
    func rangingOperationDidFailToStartDueToAuthorization()

    /**
        Triggered when the ranging operation has stopped successfully.
     */
    func rangingOperationDidStopSuccessfully()

    /**
        Triggered when the ranging operation has detected beacons belonging to a specific given beacon region.
        
        :param: beacons An array of provided beacons that the ranging operation detected.
        :param: region A provided region whose beacons the operation is trying to range.
     */
    func rangingOperationDidRangeBeacons(beacons: [AnyObject]!, inRegion region: CLBeaconRegion!)
}

/// NATRangingOperation contains all the process logic required to successfully monitor for events related to
/// ranging beacons belonging to a specific beacon region.
class NATRangingOperation: NATOperation
{
    /// The delegate for a ranging operation.
    var delegate: NATRangingOperationDelegate?

    /**
        Starts the beacon ranging process.
     */
    func startRangingForBeacons() {
        activateLocationManagerNotifications()

        NSLog("Turning on ranging...")

        if !CLLocationManager.locationServicesEnabled() {
            NSLog("Couldn't turn on ranging: Location services are not enabled.")
            if delegate != nil {
                delegate!.rangingOperationDidFailToStart()
            }
            return
        }

        if !CLLocationManager.isRangingAvailable() {
            NSLog("Couldn't turn on ranging: Ranging is not available.")
            if delegate != nil {
                delegate!.rangingOperationDidFailToStart()
            }
            return
        }

        if locationManager.rangedRegions.count > 0 {
            NSLog("Didn't turn on ranging: Ranging already on.")
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            turnOnRanging()
        case .Denied, .Restricted:
            NSLog("Couldn't turn on ranging: Required Location Access (When In Use) missing.")
            if delegate != nil {
                delegate!.rangingOperationDidFailToStartDueToAuthorization()
            }
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /**
        Turns on ranging (after all the checks have been passed).
     */
    func turnOnRanging() {
        locationManager.startRangingBeaconsInRegion(beaconRegion)

        NSLog("Ranging turned on for beacons in region: \(beaconRegion)")

        if delegate != nil {
            delegate!.rangingOperationDidStartSuccessfully()
        }
    }

    /**
        Stops the ranging process.
     */
    func stopRangingForBeacons() {
        if locationManager.rangedRegions.count == 0 {
            NSLog("Didn't turn off ranging: Ranging already off.")
            return
        }

        locationManager.stopRangingBeaconsInRegion(beaconRegion)

        if delegate != nil {
            delegate!.rangingOperationDidStopSuccessfully()
        }
        
        NSLog("Turned off ranging.")
    }
}

// MARK: Location manager delegate methods
extension NATRangingOperation
{
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            NSLog("Location Access (Always) granted!")
            if delegate != nil {
                delegate!.rangingOperationDidStartSuccessfully()
            }
            turnOnRanging()
        } else if status == .AuthorizedWhenInUse {
            NSLog("Location Access (When In Use) granted!")
            if delegate != nil {
                delegate!.rangingOperationDidStartSuccessfully()
            }
            turnOnRanging()
        } else if status == .Denied || status == .Restricted {
            NSLog("Location Access (When In Use) denied!")
            if delegate != nil {
                delegate!.rangingOperationDidFailToStart()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        if delegate != nil {
            delegate!.rangingOperationDidRangeBeacons(beacons, inRegion: region)
        }
    }
}

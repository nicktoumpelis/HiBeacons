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

protocol NATRangingDelegate {
    func rangingOperationDidStartSuccessfully()
    func rangingOperationDidFailToStart()
    func rangingOperationDidFailToStartDueToAuthorization()
    func rangingOperationDidStopSuccessfully()
    func rangingOperationDidRangeBeacons(beacons: [AnyObject]!, inRegion region: CLBeaconRegion!)
}

class NATRanging: NATOperation
{
    var delegate: NATRangingDelegate?
    
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

    func turnOnRanging() {
        locationManager.startRangingBeaconsInRegion(beaconRegion)

        NSLog("Ranging turned on for region: \(beaconRegion)")

        if delegate != nil {
            delegate!.rangingOperationDidStartSuccessfully()
        }
    }

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
extension NATRanging
{
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            NSLog("Location Access (Always) granted!")
            if delegate != nil {
                delegate!.rangingOperationDidStartSuccessfully()
            }
            turnOnRanging()
        } else if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            NSLog("Location Access (When In Use) granted!")
            if delegate != nil {
                delegate!.rangingOperationDidStartSuccessfully()
            }
            turnOnRanging()
        } else if CLLocationManager.authorizationStatus() == .Denied || CLLocationManager.authorizationStatus() == .Restricted {
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

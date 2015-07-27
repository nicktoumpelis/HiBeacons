//
//  NATMonitoring.swift
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
import UIKit
import CoreLocation

/// Lists the methods that a monitoring delegate should implement to be notified for all monitoring operation events.
protocol NATMonitoringOperationDelegate
{
    /** 
        Triggered when the monitoring operation has started successfully.
     */
    func monitoringOperationDidStartSuccessfully()

    /** 
        Triggered when the monitoring operation has failed to start.
     */
    func monitoringOperationDidFailToStart()

    /**
        Triggered when the monitoring operation has failed to start due to the last authorization denial.
     */
    func monitoringOperationDidFailToStartDueToAuthorization()

    /**
        Triggered when the monitoring operation has detected entering the given region.

        :param: region The region that the monitoring operation detected.
     */
    func monitoringOperationDidDetectEnteringRegion(region: CLBeaconRegion)
}

/// NATMonitoringOperation contains all the process logic required to successfully monitor for events related to
/// detecting a specific beacon region.
class NATMonitoringOperation: NATOperation
{
    /// The delegate for a monitoring operation.
    var delegate: NATMonitoringOperationDelegate?

    /**
        Starts the beacon region monitoring process.
     */
    func startMonitoringForBeacons() {
        activateLocationManagerNotifications()

        NSLog("Turning on monitoring...")

        if !CLLocationManager.locationServicesEnabled() {
            NSLog("Couldn't turn on monitoring: Location services are not enabled.")
            if delegate != nil {
                delegate!.monitoringOperationDidFailToStart()
            }
            return
        }

        if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.Type) {
            NSLog("Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
            if delegate != nil {
                delegate!.monitoringOperationDidFailToStart()
            }
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            turnOnMonitoring()
        case .AuthorizedWhenInUse, .Denied, .Restricted:
            NSLog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
            if delegate != nil {
                delegate!.monitoringOperationDidFailToStartDueToAuthorization()
            }
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
        }
    }

    /**
        Turns on monitoring (after all the checks have been passed).
     */
    func turnOnMonitoring() {
        locationManager.startMonitoringForRegion(beaconRegion)

        NSLog("Monitoring turned on for region: \(beaconRegion)")

        if delegate != nil {
            delegate!.monitoringOperationDidStartSuccessfully()
        }
    }

    /**
        Stops the monitoring process.
     */
    func stopMonitoringForBeacons() {
        locationManager.stopMonitoringForRegion(beaconRegion)
        
        NSLog("Turned off monitoring")
    }
}

// MARK: - Location manager delegate methods
extension NATMonitoringOperation
{
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            NSLog("Location Access (Always) granted!")
            if delegate != nil {
                delegate!.monitoringOperationDidStartSuccessfully()
            }
            turnOnMonitoring()
        } else if status == .AuthorizedWhenInUse || status == .Denied || status == .Restricted {
            NSLog("Location Access (Always) denied!")
            if delegate != nil {
                delegate!.monitoringOperationDidFailToStart()
            }
        }
    }

    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        NSLog("Entered region: \(region)")

        if delegate != nil {
            delegate!.monitoringOperationDidDetectEnteringRegion(region as! CLBeaconRegion)
        }
    }

    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NSLog("Exited region: \(region)")
    }

    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        var stateString: String

        switch state {
        case .Inside:
            stateString = "inside"
        case .Outside:
            stateString = "outside"
        case .Unknown:
            stateString = "unknown"
        }

        NSLog("State changed to " + stateString + " for region \(region).")
    }
}

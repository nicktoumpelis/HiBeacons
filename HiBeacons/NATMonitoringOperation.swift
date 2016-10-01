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
        Triggered by the monitoring operation when it has stopped successfully.
     */
    func monitoringOperationDidStopSuccessfully()

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
    func monitoringOperationDidDetectEnteringRegion(_ region: CLBeaconRegion)
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

        print("Turning on monitoring...")

        if !CLLocationManager.locationServicesEnabled() {
            print("Couldn't turn on monitoring: Location services are not enabled.")
            delegate?.monitoringOperationDidFailToStart()
            return
        }

        if !(CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)) {
            print("Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
            delegate?.monitoringOperationDidFailToStart()
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            turnOnMonitoring()
        case .authorizedWhenInUse, .denied, .restricted:
            print("Couldn't turn on monitoring: Required Location Access (Always) missing.")
            delegate?.monitoringOperationDidFailToStartDueToAuthorization()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        }
    }

    /**
        Turns on monitoring (after all the checks have been passed).
     */
    func turnOnMonitoring() {
        locationManager.startMonitoring(for: beaconRegion)
        print("Monitoring turned on for region: \(beaconRegion)")
        delegate?.monitoringOperationDidStartSuccessfully()
    }

    /**
        Stops the monitoring process.
     */
    func stopMonitoringForBeacons() {
        locationManager.stopMonitoring(for: beaconRegion)
        print("Turned off monitoring")
        delegate?.monitoringOperationDidStopSuccessfully()
    }
}

// MARK: - Location manager delegate methods
extension NATMonitoringOperation
{
    func locationManager(_ manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("Location Access (Always) granted!")
            delegate?.monitoringOperationDidStartSuccessfully()
            turnOnMonitoring()
        } else if status == .authorizedWhenInUse || status == .denied || status == .restricted {
            print("Location Access (Always) denied!")
            delegate?.monitoringOperationDidFailToStart()
        }
    }

    func locationManager(_ manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        print("Entered region: \(region)")
        delegate?.monitoringOperationDidDetectEnteringRegion(region as! CLBeaconRegion)
    }

    func locationManager(_ manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        print("Exited region: \(region)")
    }

    func locationManager(_ manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        var stateString: String

        switch state {
        case .inside:
            stateString = "inside"
        case .outside:
            stateString = "outside"
        case .unknown:
            stateString = "unknown"
        }

        print("State changed to " + stateString + " for region \(region).")
    }
}

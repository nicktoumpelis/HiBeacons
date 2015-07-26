//
//  NATViewController.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-22.
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
import CoreBluetooth

class NATViewController: UIViewController
{
    // Outlets
    @IBOutlet weak var beaconTableView: UITableView?

    // Constants
    let kOperationCellIdentifier = "OperationCell"
    let kBeaconCellIdentifier = "BeaconCell"

    let kMonitoringOperationTitle = "Monitoring"
    let kAdvertisingOperationTitle = "Advertising"
    let kRangingOperationTitle = "Ranging"

    let kNumberOfSections = 2
    let kNumberOfAvailableOperations = 3
    let kOperationCellHeight: CGFloat = 44.0
    let kBeaconCellHeight: CGFloat = 52.0
    let kBeaconSectionTitle = "Looking for beacons..."
    let kActivityIndicatorPosition = CGPoint(x: 205, y: 12)
    let kBeaconsHeaderViewIdentifier = "BeaconsHeader"

    let kMonitoringOperationContext = "MonitoringOperationContext"
    let kRangingOperationContext = "RangingOperationContext"

    enum NTSectionType: Int {
        case Operations = 0
        case DetectedBeacons
    }

    enum NTOperationsRow: Int {
        case Monitoring = 0
        case Advertising
        case Ranging
    }

    lazy var locationManager: CLLocationManager = CLLocationManager()

    let beaconRegion: CLBeaconRegion = {
        let region = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "416C0120-5960-4280-A67C-A2A9BB166D0F"), identifier: "Identifier")
        region.notifyEntryStateOnDisplay = true
        return region
    }()

    var peripheralManager: CBPeripheralManager?
    var detectedBeacons: Array<CLBeacon> = []
    var monitoringSwitch, advertisingSwitch, rangingSwitch: UISwitch?
    var operationContext: String = ""

    func activateLocationManagerNotifications() {
        locationManager.delegate = self
    }
}

// MARK: - Index path management
extension NATViewController
{
    func indexPathsOfRemovedBeacons(beacons: Array<CLBeacon>) -> Array<NSIndexPath>? {
        var indexPaths: Array<NSIndexPath>?

        var row = 0
        for existingBeacon in detectedBeacons {
            var stillExists = false
            for beacon in beacons {
                if existingBeacon.major?.integerValue == beacon.major?.integerValue && existingBeacon.minor?.integerValue == beacon.minor?.integerValue {
                    stillExists = true
                    break
                }
            }

            if stillExists == false {
                if indexPaths == nil {
                    indexPaths = []
                }
                indexPaths?.append(NSIndexPath(forRow: row, inSection: NTSectionType.DetectedBeacons.rawValue))
            }
            row++
        }

        return indexPaths
    }

    func indexPathsOfInsertedBeacons(beacons: Array<CLBeacon>) -> Array<NSIndexPath>? {
        var indexPaths: Array<NSIndexPath>?

        var row = 0
        for beacon in beacons {
            var isNewBeacon = true
            for existingBeacon in detectedBeacons {
                if existingBeacon.major?.integerValue == beacon.major?.integerValue && existingBeacon.minor?.integerValue == beacon.minor?.integerValue {
                    isNewBeacon = false
                    break
                }
            }

            if isNewBeacon == true {
                if indexPaths == nil {
                    indexPaths = []
                }
                indexPaths!.append(NSIndexPath(forRow: row, inSection: NTSectionType.DetectedBeacons.rawValue))
            }
            row++
        }

        return indexPaths
    }

    func indexPathsForBeacons(beacons: Array<CLBeacon>) -> Array<NSIndexPath> {
        var indexPaths: Array<NSIndexPath> = []

        for row in 0..<beacons.count {
            indexPaths.append(NSIndexPath(forRow: row, inSection: NTSectionType.DetectedBeacons.rawValue))
        }

        return indexPaths
    }

    func insertedSections() -> NSIndexSet? {
        if rangingSwitch?.on == true && beaconTableView?.numberOfSections() == kNumberOfSections - 1 {
            return NSIndexSet(index: 1)
        } else {
            return nil
        }
    }

    func deletedSections() -> NSIndexSet? {
        if rangingSwitch?.on == false && beaconTableView?.numberOfSections() == kNumberOfSections {
            return NSIndexSet(index: 1)
        } else {
            return nil
        }
    }

    func filteredBeacons(beacons: Array<CLBeacon>) -> Array<CLBeacon> {
        // This method filters duplicate beacons out; this may happen temporarily if the originating device 
        // changes its Bluetooth id

        var filteredBeacons = beacons // Arrays are value types in Swift!

        var lookup: Set<String> = []
        for index in 0..<beacons.count {
            var currentBeacon = beacons[index]
            var identifier = "\(currentBeacon.major)/\(currentBeacon.minor)"

            if lookup.contains(identifier) {
                filteredBeacons.removeAtIndex(index)
            } else {
                lookup.insert(identifier)
            }
        }

        return filteredBeacons
    }
}

// MARK: - Table view functionality
extension NATViewController: UITableViewDataSource, UITableViewDelegate
{
    func detailsStringForBeacon(beacon: CLBeacon) -> String {
        var proximity: String

        switch beacon.proximity {
        case .Near:
            proximity = "Near"
        case .Immediate:
            proximity = "Immediate"
        case .Far:
            proximity = "Far"
        case .Unknown:
            proximity = "Unknown"
        }

        return "\(beacon.major), \(beacon.minor) • \(proximity) • \(beacon.accuracy) • \(beacon.rssi)"
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        switch indexPath.section {
        case NTSectionType.Operations.rawValue:
            cell = tableView.dequeueReusableCellWithIdentifier(kOperationCellIdentifier) as? UITableViewCell
            switch indexPath.row {
            case NTOperationsRow.Monitoring.rawValue:
                cell?.textLabel?.text = kMonitoringOperationTitle
                monitoringSwitch = cell?.accessoryView as? UISwitch
                monitoringSwitch?.addTarget(self, action: "changeMonitoringState:", forControlEvents: UIControlEvents.ValueChanged)
            case NTOperationsRow.Advertising.rawValue:
                cell?.textLabel?.text = kAdvertisingOperationTitle
                advertisingSwitch = cell?.accessoryView as? UISwitch
                advertisingSwitch?.addTarget(self, action: "changeAdvertisingState:", forControlEvents: UIControlEvents.ValueChanged)
            default:    // NTOperationsRow.Ranging.rawValue
                cell?.textLabel?.text = kRangingOperationTitle
                rangingSwitch = cell?.accessoryView as? UISwitch
                rangingSwitch?.addTarget(self, action: "changeRangingState:", forControlEvents: UIControlEvents.ValueChanged)
            }
        default:        // NTSectionType.DetectedBeacons.rawValue
            var beacon = detectedBeacons[indexPath.row]

            cell = tableView.dequeueReusableCellWithIdentifier(kBeaconCellIdentifier) as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kBeaconCellIdentifier)
            }
            cell?.textLabel?.text = beacon.proximityUUID.UUIDString
            cell?.detailTextLabel?.text = detailsStringForBeacon(beacon)
            cell?.detailTextLabel?.textColor = UIColor.grayColor()
        }

        cell?.updateConstraintsIfNeeded()

        return cell!
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if rangingSwitch?.on == true {
            return kNumberOfSections  // All sections visible
        } else {
            return kNumberOfSections - 1  // Beacons section not visible
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case NTSectionType.Operations.rawValue:
            return kNumberOfAvailableOperations
        default:        // NTSectionType.DetectedBeacons.rawValue
            return self.detectedBeacons.count
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case NTSectionType.Operations.rawValue:
            return nil
        default:        // NTSectionType.DetectedBeacons.rawValue
            return kBeaconSectionTitle
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
        case NTSectionType.Operations.rawValue:
            return kOperationCellHeight
        default:        // NTSectionType.DetectedBeacons.rawValue
            return kBeaconCellHeight
        }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView(reuseIdentifier: kBeaconsHeaderViewIdentifier)

        // Adds an activity indicator view to the section header
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        headerView.addSubview(indicatorView)

        indicatorView.frame = CGRect(origin: kActivityIndicatorPosition, size: indicatorView.frame.size)

        indicatorView.startAnimating()

        return headerView
    }
}

// MARK: - Beacon ranging
extension NATViewController
{
    func changeRangingState(theSwitch: UISwitch) {
        if theSwitch.on {
            startRangingForBeacons()
        } else {
            stopRangingForBeacons()
        }
    }

    func startRangingForBeacons() {
        operationContext = kRangingOperationContext

        activateLocationManagerNotifications()
        checkLocationAccessForRanging()

        detectedBeacons = []
        turnOnRanging()
    }

    func turnOnRanging() {
        NSLog("Turing on ranging...")

        if !CLLocationManager.isRangingAvailable() {
            NSLog("Couldn't turn on ranging: Ranging is not available.")
            rangingSwitch?.on = false
            return
        }

        if locationManager.rangedRegions.count > 0 {
            NSLog("Didn't turn on ranging: Ranging already on.")
            return
        }

        locationManager.startRangingBeaconsInRegion(beaconRegion)

        NSLog("Ranging turned on for region: \(beaconRegion)")
    }

    func stopRangingForBeacons() {
        if locationManager.rangedRegions.count == 0 {
            NSLog("Didn't turn off ranging: Ranging already off.")
            return
        }

        locationManager.stopRangingBeaconsInRegion(beaconRegion)

        var deletedSections = self.deletedSections()
        detectedBeacons = []

        beaconTableView?.beginUpdates()
        if deletedSections != nil {
            beaconTableView?.deleteSections(deletedSections!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        beaconTableView?.endUpdates()

        NSLog("Turned off ranging.")
    }
}

// MARK: - Beacon region monitoring
extension NATViewController
{
    func changeMonitoringState(theSwitch: UISwitch) {
        if theSwitch.on {
            startMonitoringForBeacons()
        } else {
            stopMonitoringForBeacons()
        }
    }

    func startMonitoringForBeacons() {
        operationContext = kMonitoringOperationContext

        activateLocationManagerNotifications()
        checkLocationAccessForMonitoring()

        turnOnMonitoring()
    }

    func turnOnMonitoring() {
        NSLog("Turning on monitoring...")

        if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.Type) {
            NSLog("Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
            monitoringSwitch?.on = false
            return
        }

        locationManager.startMonitoringForRegion(beaconRegion)

        NSLog("Monitoring turned on for region: \(beaconRegion)")
    }

    func stopMonitoringForBeacons() {
        locationManager.stopMonitoringForRegion(beaconRegion)
        NSLog("Turned off monitoring")
    }
}

// MARK: - CLLocationManagerDelegate methods
extension NATViewController: CLLocationManagerDelegate
{
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if !CLLocationManager.locationServicesEnabled() {
            if operationContext == kMonitoringOperationContext {
                NSLog("Couldn't turn on monitoring: Location services are not enabled.")
                monitoringSwitch?.on = false
            } else {
                NSLog("Couldn't turn on ranging: Location services are not enabled.")
                rangingSwitch?.on = false
            }
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case CLAuthorizationStatus.AuthorizedAlways:
            NSLog("Location Access (Always) granted!")
            if operationContext == kMonitoringOperationContext {
                monitoringSwitch?.on = true
            } else {
                rangingSwitch?.on = true
            }

        case CLAuthorizationStatus.AuthorizedWhenInUse:
            if operationContext == kMonitoringOperationContext {
                NSLog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
                monitoringSwitch?.on = false
            } else {
                NSLog("Location Access (When In Use) granted!")
                rangingSwitch?.on = true
            }

        case CLAuthorizationStatus.Denied, CLAuthorizationStatus.Restricted, CLAuthorizationStatus.NotDetermined:
            if operationContext == kMonitoringOperationContext {
                NSLog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
                monitoringSwitch?.on = false
            } else {
                NSLog("Couldn't turn on monitoring: Required Location Access (When In Use) missing.")
                rangingSwitch?.on = false
            }
        }
    }

    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        let filteredBeacons: Array<CLBeacon> = self.filteredBeacons(beacons as! Array<CLBeacon>)

        if filteredBeacons.count == 0 {
            NSLog("No beacons found nearby.")
        } else {
            var beaconsString: String

            if filteredBeacons.count > 1 {
                beaconsString = "beacons"
            } else {
                beaconsString = "beacon"
            }
            NSLog("Found \(filteredBeacons.count) " + beaconsString + ".")
        }

        var insertedRows: Array<NSIndexPath>? = indexPathsOfInsertedBeacons(filteredBeacons)
        var deletedRows: Array<NSIndexPath>? = indexPathsOfRemovedBeacons(filteredBeacons)
        var reloadedRows: Array<NSIndexPath>?
        if deletedRows == nil && insertedRows == nil {
            reloadedRows = indexPathsForBeacons(filteredBeacons)
        }

        detectedBeacons = filteredBeacons

        beaconTableView?.beginUpdates()
        if insertedSections() != nil {
            beaconTableView?.insertSections(insertedSections()!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        if deletedSections() != nil {
            beaconTableView?.deleteSections(deletedSections()!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        if insertedRows != nil {
            beaconTableView?.insertRowsAtIndexPaths(insertedRows!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        if deletedRows != nil {
            beaconTableView?.deleteRowsAtIndexPaths(deletedRows!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        if reloadedRows != nil {
            beaconTableView?.reloadRowsAtIndexPaths(reloadedRows!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        beaconTableView?.endUpdates()
    }

    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        NSLog("Entered region: \(region)")

        sendLocalNotificationForBeaconRegion(region as! CLBeaconRegion)
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

// MARK: - Local notifications
extension NATViewController
{
    func sendLocalNotificationForBeaconRegion(region: CLBeaconRegion) {
        let notification: UILocalNotification = UILocalNotification()

        // Major and minor are not available at the monitoring stage
        notification.alertBody = "Entered beacon region for UUID: " + region.proximityUUID.UUIDString
        notification.alertAction = "View Details"
        notification.soundName = UILocalNotificationDefaultSoundName

        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
}

// MARK: - Beacon advertising and CBPeripheralManagerDelegate methods
extension NATViewController: CBPeripheralManagerDelegate
{
    func changeAdvertisingState(theSwitch: UISwitch) {
        if theSwitch.on {
            startAdvertisingBeacon()
        } else {
            stopAdvertisingBeacon()
        }
    }

    func startAdvertisingBeacon() {
        NSLog("Turning on advertising...")

        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        }

        turnOnAdvertising()
    }

    func turnOnAdvertising() {
        if peripheralManager?.state != CBPeripheralManagerState.PoweredOn {
            NSLog("Peripheral manager is off.")
            advertisingSwitch?.on = false
            return
        }

        let major: CLBeaconMajorValue = CLBeaconMajorValue(arc4random_uniform(5000))
        let minor: CLBeaconMinorValue = CLBeaconMajorValue(arc4random_uniform(5000))
        var region: CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconRegion.proximityUUID, major: major, minor: minor, identifier: beaconRegion.identifier)
        var beaconPeripheralData: NSMutableDictionary = region.peripheralDataWithMeasuredPower(nil)

        peripheralManager?.startAdvertising(beaconPeripheralData as [NSObject : AnyObject])

        NSLog("Turning on advertising for region: \(region).")
    }

    func stopAdvertisingBeacon() {
        peripheralManager?.stopAdvertising()

        NSLog("Turned off advertising.")
    }

    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error != nil {
            NSLog("Couldn't turn on advertising: \(error)")
            advertisingSwitch?.on = false
        }

        if peripheralManager!.isAdvertising {
            NSLog("Turned on advertising.")
            advertisingSwitch?.on = true
        }
    }

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheralManager?.state != CBPeripheralManagerState.PoweredOn {
            NSLog("Peripheral manager is off.")
            advertisingSwitch?.on = false
            return
        }

        NSLog("Peripheral manager is on.")
        turnOnAdvertising()
    }
}

// MARK: - Location access methods (iOS 8 / Xcode 6)
extension NATViewController
{
    func checkLocationAccessForRanging() {
        if locationManager.respondsToSelector("requestWhenInUseAuthorization") == true {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func checkLocationAccessForMonitoring() {
        if locationManager.respondsToSelector("requestAlwaysAuthorization") == true {
            let authorizationStatus = CLLocationManager.authorizationStatus()
            if authorizationStatus == .Denied || authorizationStatus == .AuthorizedWhenInUse {
                let title = "Missing Location Access"
                let message = "Location Access (Always) is required. Click Settings to update the location access settings."
                let cancelButtonTitle = "Cancel"
                let settingsButtonTitle = "Settings"
                let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: settingsButtonTitle)
                alert.show()
                monitoringSwitch?.on = false
                return
            }

            locationManager.requestAlwaysAuthorization()
        }
    }
}

extension NATViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
}

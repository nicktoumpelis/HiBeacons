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

class NATViewController: UIViewController, CLLocationManagerDelegate
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

    var monitoringOperation: NATMonitoring = NATMonitoring()
    var rangingOperation: NATRanging = NATRanging()
    var advertisingOperation: NATAdvertising = NATAdvertising()

    var detectedBeacons: Array<CLBeacon> = []
    
    var monitoringSwitch, advertisingSwitch, rangingSwitch: UISwitch?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        monitoringOperation.delegate = self
        rangingOperation.delegate = self
        advertisingOperation.delegate = self
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

// MARK: - Operation methods
extension NATViewController
{
    func changeRangingState(theSwitch: UISwitch) {
        if theSwitch.on {
            rangingOperation.startRangingForBeacons()
        } else {
            rangingOperation.stopRangingForBeacons()
        }
    }
    
    func changeMonitoringState(theSwitch: UISwitch) {
        if theSwitch.on {
            monitoringOperation.startMonitoringForBeacons()
        } else {
            monitoringOperation.stopMonitoringForBeacons()
        }
    }

    func changeAdvertisingState(theSwitch: UISwitch) {
        if theSwitch.on {
            advertisingOperation.startAdvertisingBeacon()
        } else {
            advertisingOperation.stopAdvertisingBeacon()
        }
    }
}

// MARK: - Monitoring delegate methods and helpers
extension NATViewController: NATMonitoringDelegate, UIAlertViewDelegate
{
    func monitoringOperationDidStartSuccessfully() {
        monitoringSwitch?.on = true
    }
    
    func monitoringOperationDidFailToStart() {
        monitoringSwitch?.on = false
    }

    func monitoringOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (Always) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"
        let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: settingsButtonTitle)
        alert.show()
        monitoringSwitch?.on = false
    }

    func monitoringOperationDidStopSuccessfully() {

    }

    func monitoringOperationDidDetectEnteringRegion(region: CLBeaconRegion) {
        sendLocalNotificationForBeaconRegion(region)
    }

    func sendLocalNotificationForBeaconRegion(region: CLBeaconRegion) {
        let notification: UILocalNotification = UILocalNotification()

        // Major and minor are not available at the monitoring stage
        notification.alertBody = "Entered beacon region for UUID: " + region.proximityUUID.UUIDString
        notification.alertAction = "View Details"
        notification.soundName = UILocalNotificationDefaultSoundName

        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }

    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
}

// MARK: - Ranging delegate methods
extension NATViewController: NATRangingDelegate
{
    func rangingOperationDidStartSuccessfully() {
        detectedBeacons = []
        rangingSwitch?.on = true
    }

    func rangingOperationDidFailToStart() {
        rangingSwitch?.on = false
    }

    func rangingOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (When In Use) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"
        let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: settingsButtonTitle)
        alert.show()
        rangingSwitch?.on = false
    }

    func rangingOperationDidStopSuccessfully() {
        var deletedSections = self.deletedSections()
        detectedBeacons = []

        beaconTableView?.beginUpdates()
        if deletedSections != nil {
            beaconTableView?.deleteSections(deletedSections!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        beaconTableView?.endUpdates()
    }

    func rangingOperationDidRangeBeacons(beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
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
}

// MARK: - Advertising delegate methods
extension NATViewController: NATAdvertisingDelegate
{
    func advertisingOperationDidStartSuccessfully() {
        advertisingSwitch?.on = true
    }

    func advertisingOperationDidFailToStart() {
        advertisingSwitch?.on = false
    }

    func advertisingOperationDidStopSuccessfully() {
        
    }
}

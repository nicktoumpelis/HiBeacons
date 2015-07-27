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

/// The main view controller, which basically manages the UI, triggers operations and updates its views.
class NATViewController: UIViewController
{
    // Outlets

    /// The main table view containing the operation cells, and optionally the ranged beacons.
    @IBOutlet weak var beaconTableView: UITableView?


    // Constants

    /// The operation table view cell identifier.
    private let kOperationCellIdentifier = "OperationCell"
    /// The beacon table view cell identifier.
    private let kBeaconCellIdentifier = "BeaconCell"

    /// The monitoring table view cell title.
    private let kMonitoringCellTitle = "Monitoring"
    /// The advertising table view cell title.
    private let kAdvertisingCellTitle = "Advertising"
    /// The ranging table view cell title.
    private let kRangingCellTitle = "Ranging"

    /// The maximum number of table view sections (when ranged beacons are included).
    private let kMaxNumberOfSections = 2
    /// The number of possible operations.
    private let kNumberOfAvailableOperations = 3
    /// The standard height of the operation table view cell.
    private let kOperationCellHeight: CGFloat = 44.0
    /// The standard height of the beacon table view cell.
    private let kBeaconCellHeight: CGFloat = 52.0

    /// The title for the beacon ranging table view section.
    private let kBeaconSectionTitle = "Looking for beacons..."
    /// The position of the activity indicator in the ranging table view header.
    private let kActivityIndicatorPosition = CGPoint(x: 205, y: 12)
    /// The identifier for the beacon ranging table view header.
    private let kBeaconsHeaderViewIdentifier = "BeaconsHeader"


    // Enumerations

    /**
        The type of the table view section.
        
        - Operations: The first section contains the cells that can perform operations, and have switches.
        - DetectedBeacons: The second section lists cells, each with a ranged beacon.
     */
    private enum NTSectionType: Int {
        case Operations = 0
        case DetectedBeacons
    }

    /**
        The rows contained in the operations table view section.
    
        - Monitoring: The monitoring cell row.
        - Advertising: The advertising cell row.
        - Ranging: The ranging cell row.
     */
    private enum NTOperationsRow: Int {
        case Monitoring = 0
        case Advertising
        case Ranging
    }


    // The Operation objects

    /// The monitoring operation object.
    private var monitoringOperation = NATMonitoringOperation()
    /// The advertising operation object.
    private var advertisingOperation = NATAdvertisingOperation()
    /// The ranging operation object.
    private var rangingOperation = NATRangingOperation()


    // Other

    /// An array of CLBeacon objects, typically those detected through ranging.
    private var detectedBeacons = [CLBeacon]()

    /// The UISwitch instance associated with the monitoring cell.
    private var monitoringSwitch: UISwitch?
    /// The UISwitch instance associated with the advertising cell.
    private var advertisingSwitch: UISwitch?
    /// The UISwitch instance associated with the ranging cell.
    private var rangingSwitch: UISwitch?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // We need to assign self as a delegate here.
        monitoringOperation.delegate = self
        advertisingOperation.delegate = self
        rangingOperation.delegate = self
    }
}

// MARK: - Index path management
extension NATViewController
{
    /**
        Returns an array of NSIndexPath instances for the given beacons, which are to be removed from the table view.

        Not all of the given beacons will actually be removed. It will be determined by comparing with the currently
        detected beacons.

        :param: beacons An array of CLBeacon objects.
        :returns: An array of NSIndexPaths corresponding to positions in the table view where these beacons are.
     */
    func indexPathsOfRemovedBeacons(beacons: [CLBeacon]) -> [NSIndexPath]? {
        var indexPaths: [NSIndexPath]?

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

    /**
        Returns an array of NSIndexPath instances for the given beacons, which are to be inserted in the table view.

        Not all of the given beacons will actually be inserted. It will be determined by comparing with all the 
        currently detected beacons.

        :param: beacons An array of CLBeacon objects.
        :returns: An array of NSIndexPaths corresponding to positions in the table view where these beacons are.
     */
    func indexPathsOfInsertedBeacons(beacons: [CLBeacon]) -> [NSIndexPath]? {
        var indexPaths: [NSIndexPath]?

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

    /**
        Returns an array of NSIndexPath instances for the given beacons.

        :param: beacons An array of CLBeacon objects.
        :returns: An array of NSIndexPaths corresponding to positions in the table view.
     */
    func indexPathsForBeacons(beacons: [CLBeacon]) -> [NSIndexPath] {
        var indexPaths = [NSIndexPath]()

        for row in 0..<beacons.count {
            indexPaths.append(NSIndexPath(forRow: row, inSection: NTSectionType.DetectedBeacons.rawValue))
        }

        return indexPaths
    }

    /**
        Returns an NSIndexSet instance of the inserted sections in the table view or nil.

        :returns: An NSIndexSet instance or nil.
     */
    func insertedSections() -> NSIndexSet? {
        if rangingSwitch?.on == true && beaconTableView?.numberOfSections() == kMaxNumberOfSections - 1 {
            return NSIndexSet(index: 1)
        } else {
            return nil
        }
    }

    /**
        Returns an NSIndexSet instance of the deleted sections in the table view or nil.

        :returns: An NSIndexSet instance or nil.
     */
    func deletedSections() -> NSIndexSet? {
        if rangingSwitch?.on == false && beaconTableView?.numberOfSections() == kMaxNumberOfSections {
            return NSIndexSet(index: 1)
        } else {
            return nil
        }
    }

    /**
        Returns an array of CLBeacon instances that has been all its duplicates filtered out.
    
        Duplicates may appear during ranging; this may happen temporarily if the originating device changes its 
        Bluetooth ID.

        :param: beacons An array of CLBeacon objects.
        :returns: An array of CLBeacon objects.
     */
    func filteredBeacons(beacons: [CLBeacon]) -> [CLBeacon] {
        var filteredBeacons = beacons   // Copy

        var lookup = Set<String>()
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
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        switch indexPath.section {
        case NTSectionType.Operations.rawValue:
            cell = tableView.dequeueReusableCellWithIdentifier(kOperationCellIdentifier) as? UITableViewCell
            switch indexPath.row {
            case NTOperationsRow.Monitoring.rawValue:
                cell?.textLabel?.text = kMonitoringCellTitle
                monitoringSwitch = cell?.accessoryView as? UISwitch
                monitoringSwitch?.addTarget(self, action: "changeMonitoringState:", forControlEvents: UIControlEvents.ValueChanged)
            case NTOperationsRow.Advertising.rawValue:
                cell?.textLabel?.text = kAdvertisingCellTitle
                advertisingSwitch = cell?.accessoryView as? UISwitch
                advertisingSwitch?.addTarget(self, action: "changeAdvertisingState:", forControlEvents: UIControlEvents.ValueChanged)
            case NTOperationsRow.Ranging.rawValue:
                cell?.textLabel?.text = kRangingCellTitle
                rangingSwitch = cell?.accessoryView as? UISwitch
                rangingSwitch?.addTarget(self, action: "changeRangingState:", forControlEvents: UIControlEvents.ValueChanged)
            default:
                break
            }
        case NTSectionType.DetectedBeacons.rawValue:
            var beacon = detectedBeacons[indexPath.row]

            cell = tableView.dequeueReusableCellWithIdentifier(kBeaconCellIdentifier) as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kBeaconCellIdentifier)
            }
            cell?.textLabel?.text = beacon.proximityUUID.UUIDString
            cell?.detailTextLabel?.text = beacon.fullDetails()
            cell?.detailTextLabel?.textColor = UIColor.grayColor()
        default:
            break
        }

        // We wouldn't normally need this, since constraints can be set in Interface Builder. However, there seems
        // to be a bug that removes all constraints from our cells upon dequeueing, so we need to trigger re-adding
        // them here. (See also NATOperationCell.swift).
        cell?.updateConstraintsIfNeeded()

        return cell!
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if rangingSwitch?.on == true {
            return kMaxNumberOfSections            // All sections visible
        } else {
            return kMaxNumberOfSections - 1        // Beacons section not visible
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case NTSectionType.Operations.rawValue:
            return kNumberOfAvailableOperations
        case NTSectionType.DetectedBeacons.rawValue:
            return self.detectedBeacons.count
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case NTSectionType.Operations.rawValue:
            return nil
        case NTSectionType.DetectedBeacons.rawValue:
            return kBeaconSectionTitle
        default:
            return nil
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
        case NTSectionType.Operations.rawValue:
            return kOperationCellHeight
        case NTSectionType.DetectedBeacons.rawValue:
            return kBeaconCellHeight
        default:
            return 0.0
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
    /**
        Starts/stops the monitoring operation, depending on the state of the given switch.

        :param: monitoringSwitch The monitoring UISwitch instance.
     */
    func changeMonitoringState(monitoringSwitch: UISwitch) {
        if monitoringSwitch.on {
            monitoringOperation.startMonitoringForBeacons()
        } else {
            monitoringOperation.stopMonitoringForBeacons()
        }
    }

    /**
        Starts/stops the advertising operation, depending on the state of the given switch.

        :param: advertisingSwitch The advertising UISwitch instance.
     */
    func changeAdvertisingState(advertisingSwitch: UISwitch) {
        if advertisingSwitch.on {
            advertisingOperation.startAdvertisingBeacon()
        } else {
            advertisingOperation.stopAdvertisingBeacon()
        }
    }

    /**
        Starts/stops the ranging operation, depending on the state of the given switch.

        :param: rangingSwitch The ranging UISwitch instance.
     */
    func changeRangingState(rangingSwitch: UISwitch) {
        if rangingSwitch.on {
            rangingOperation.startRangingForBeacons()
        } else {
            rangingOperation.stopRangingForBeacons()
        }
    }
}

// MARK: - Monitoring delegate methods and helpers
extension NATViewController: NATMonitoringOperationDelegate
{
    /**
        Triggered by the monitoring operation when it has started successfully and turns the monitoring switch on.
     */
    func monitoringOperationDidStartSuccessfully() {
        monitoringSwitch?.on = true
    }

    /**
        Triggered by the monitoring operation whe it has failed to start and turns the monitoring switch off.
     */
    func monitoringOperationDidFailToStart() {
        monitoringSwitch?.on = false
    }

    /**
        Triggered by the monitoring operation when it has failed to start due to the last authorization denial.
    
        It turns the monitoring switch off and presents a UIAlertView to prompt the user to change their location 
        access settings.
     */
    func monitoringOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (Always) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"

        let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: settingsButtonTitle)
        alert.show()

        monitoringSwitch?.on = false
    }

    /**
        Triggered by the monitoring operation when it has detected entering the provided region. It emits 
        a local notification.
        
        :param: region The provided region that the monitoring operation detected.
     */
    func monitoringOperationDidDetectEnteringRegion(region: CLBeaconRegion) {
        sendLocalNotificationForBeaconRegion(region)
    }

    /**
        Emits a UILocalNotification with information about the given region.
    
        Note that major and minor are not available at the monitoring stage.
    
        :param: region The given CLBeaconRegion instance.
     */
    func sendLocalNotificationForBeaconRegion(region: CLBeaconRegion) {
        let notification = UILocalNotification()

        notification.alertBody = "Entered beacon region for UUID: " + region.proximityUUID.UUIDString
        notification.alertAction = "View Details"
        notification.soundName = UILocalNotificationDefaultSoundName

        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
}

// MARK: - Advertising delegate methods
extension NATViewController: NATAdvertisingOperationDelegate
{
    /**
        Triggered by the advertising operation when it has started successfully and turns the advertising switch on.
     */
    func advertisingOperationDidStartSuccessfully() {
        advertisingSwitch?.on = true
    }

    /**
        Triggered by the advertising operation when ithas failed to start and turns the advertising switch off.
     */
    func advertisingOperationDidFailToStart() {
        advertisingSwitch?.on = false
    }
}

// MARK: - Ranging delegate methods
extension NATViewController: NATRangingOperationDelegate
{
    /**
        Triggered by the ranging operation when it has started successfully. It turns the ranging switch on 
        and resets the detectedBeacons array.
     */
    func rangingOperationDidStartSuccessfully() {
        detectedBeacons = []
        rangingSwitch?.on = true
    }

    /**
        Triggered by the ranging operation when it has failed to start and turns the ranging switch off.
     */
    func rangingOperationDidFailToStart() {
        rangingSwitch?.on = false
    }

    /**
        Triggered by the ranging operation when it has failed to start due to the last authorization denial.

        It turns the ranging switch off and presents a UIAlertView to prompt the user to change their location
        access settings.
     */
    func rangingOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (When In Use) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"

        let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: settingsButtonTitle)
        alert.show()

        rangingSwitch?.on = false
    }

    /**
        Triggered by the ranging operation when it has stopped successfully. It updates the beacon table view to reflect
        that the ranging has stopped.
     */
    func rangingOperationDidStopSuccessfully() {
        var deletedSections = self.deletedSections()
        detectedBeacons = []

        beaconTableView?.beginUpdates()
        if deletedSections != nil {
            beaconTableView?.deleteSections(deletedSections!, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        beaconTableView?.endUpdates()
    }

    /**
        Triggered by the ranging operation when it has detected beacons belonging to a specific given beacon region.
        
        It updates the table view to show the newly-found beacons.

        :param: beacons An array of provided beacons that the ranging operation detected.
        :param: region A provided region whose beacons the operation is trying to range.
     */
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

// MARK: - Alert view delegate methods
extension NATViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
}

// MARK: - CLBeacon extension
extension CLBeacon
{
    /**
        Returns a specially-formatted description of the beacon's characteristics.
    
        :returns: The beacon's description.
     */
    func fullDetails() -> String {
        let proximityText: String

        switch proximity {
        case .Near:
            proximityText = "Near"
        case .Immediate:
            proximityText = "Immediate"
        case .Far:
            proximityText = "Far"
        case .Unknown:
            proximityText = "Unknown"
        }

        return "\(major), \(minor) •  \(proximityText) • \(accuracy) • \(rssi)"
    }
}

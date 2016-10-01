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
    @IBOutlet weak var beaconTableView: UITableView!


    // Constants

    /// The maximum number of table view sections (when ranged beacons are included).
    fileprivate let kMaxNumberOfSections = 2
    /// The number of possible operations.
    fileprivate let kNumberOfAvailableOperations = 3

    /// The title for the beacon ranging table view section.
    fileprivate let kBeaconSectionTitle = "Ranging for beacons..."
    /// The position of the activity indicator in the ranging table view header.
    fileprivate let kActivityIndicatorPosition = CGPoint(x: 205, y: 12)
    /// The identifier for the beacon ranging table view header.
    fileprivate let kBeaconsHeaderViewIdentifier = "BeaconsHeader"


    // Enumerations

    /**
        The type of the table view section.
        
        - Operations: The first section contains the cells that can perform operations, and have switches.
        - DetectedBeacons: The second section lists cells, each with a ranged beacon.
     */
    fileprivate enum NTSectionType: Int {
        case operations = 0
        case detectedBeacons

        /**
            Returns the table view cell identifier that corresponds to the section type.
        
            :returns: The table view cell identifier.
         */
        func cellIdentifier() -> String {
            switch self {
            case .operations:
                return "OperationCell"
            case .detectedBeacons:
                return "BeaconCell"
            }
        }

        /**
            Returns the table view cell height that corresponds to the section type.
        
            :returns: The table view cell height.
         */
        func tableViewCellHeight() -> CGFloat {
            switch self {
            case .operations:
                return 44.0
            case .detectedBeacons:
                return 52.0
            }
        }
    }

    /**
        The rows contained in the operations table view section.
    
        - Monitoring: The monitoring cell row.
        - Advertising: The advertising cell row.
        - Ranging: The ranging cell row.
     */
    fileprivate enum NTOperationsRow: Int {
        case monitoring = 0
        case advertising
        case ranging

        /**
            Returns the table view cell title that corresponds to the specific operations row.
            
            :returns: A title for the table view cell label.
         */
        func tableViewCellTitle() -> String {
            switch self {
            case .monitoring:
                return "Monitoring"
            case .advertising:
                return "Advertising"
            case .ranging:
                return "Ranging"
            }
        }
    }


    // The Operation objects

    /// The monitoring operation object.
    fileprivate var monitoringOperation = NATMonitoringOperation()
    /// The advertising operation object.
    fileprivate var advertisingOperation = NATAdvertisingOperation()
    /// The ranging operation object.
    fileprivate var rangingOperation = NATRangingOperation()


    // Other

    /// An array of CLBeacon objects, typically those detected through ranging.
    fileprivate var detectedBeacons = [CLBeacon]()

    /// The UISwitch instance associated with the monitoring cell.
    fileprivate var monitoringSwitch: UISwitch!
    /// The UISwitch instance associated with the advertising cell.
    fileprivate var advertisingSwitch: UISwitch!
    /// The UISwitch instance associated with the ranging cell.
    fileprivate var rangingSwitch: UISwitch!

    /// The UIActivityIndicatorView that shows whether monitoring is active.
    fileprivate var monitoringActivityIndicator: UIActivityIndicatorView!
    /// The UIActivityIndicatorView that shows whether advertising is active.
    fileprivate var advertisingActivityIndicator: UIActivityIndicatorView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(performWatchAction(_:)), name: NSNotification.Name(rawValue: NATHiBeaconsDelegate.NATHiBeaconsWatchNotificationName), object: nil)

        // We need to assign self as a delegate here.
        monitoringOperation.delegate = self
        advertisingOperation.delegate = self
        rangingOperation.delegate = self
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
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
    func indexPathsOfRemovedBeacons(_ beacons: [CLBeacon]) -> [IndexPath]? {
        var indexPaths: [IndexPath]?

        var row = 0
        for existingBeacon in detectedBeacons {
            var stillExists = false
            for beacon in beacons {
                if existingBeacon.major.intValue == beacon.major.intValue && existingBeacon.minor.intValue == beacon.minor.intValue {
                    stillExists = true
                    break
                }
            }

            if stillExists == false {
                indexPaths = indexPaths ?? []
                indexPaths!.append(IndexPath(row: row, section: NTSectionType.detectedBeacons.rawValue))
            }
            row += 1
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
    func indexPathsOfInsertedBeacons(_ beacons: [CLBeacon]) -> [IndexPath]? {
        var indexPaths: [IndexPath]?

        var row = 0
        for beacon in beacons {
            var isNewBeacon = true
            for existingBeacon in detectedBeacons {
                if existingBeacon.major.intValue == beacon.major.intValue && existingBeacon.minor.intValue == beacon.minor.intValue {
                    isNewBeacon = false
                    break
                }
            }

            if isNewBeacon == true {
                indexPaths = indexPaths ?? []
                indexPaths!.append(IndexPath(row: row, section: NTSectionType.detectedBeacons.rawValue))
            }
            row += 1
        }

        return indexPaths
    }

    /**
        Returns an array of NSIndexPath instances for the given beacons.

        :param: beacons An array of CLBeacon objects.
        :returns: An array of NSIndexPaths corresponding to positions in the table view.
     */
    func indexPathsForBeacons(_ beacons: [CLBeacon]) -> [IndexPath] {
        var indexPaths = [IndexPath]()

        for row in 0..<beacons.count {
            indexPaths.append(IndexPath(row: row, section: NTSectionType.detectedBeacons.rawValue))
        }

        return indexPaths
    }

    /**
        Returns an NSIndexSet instance of the inserted sections in the table view or nil.

        :returns: An NSIndexSet instance or nil.
     */
    func insertedSections() -> IndexSet? {
        if rangingSwitch.isOn == true && beaconTableView.numberOfSections == kMaxNumberOfSections - 1 {
            return IndexSet(integer: 1)
        } else {
            return nil
        }
    }

    /**
        Returns an NSIndexSet instance of the deleted sections in the table view or nil.

        :returns: An NSIndexSet instance or nil.
     */
    func deletedSections() -> IndexSet? {
        if rangingSwitch.isOn == false && beaconTableView.numberOfSections == kMaxNumberOfSections {
            return IndexSet(integer: 1)
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
    func filteredBeacons(_ beacons: [CLBeacon]) -> [CLBeacon] {
        var filteredBeacons = beacons   // Copy

        var lookup = Set<String>()
        for index in 0..<beacons.count {
            let currentBeacon = beacons[index]
            let identifier = "\(currentBeacon.major)/\(currentBeacon.minor)"

            if lookup.contains(identifier) {
                filteredBeacons.remove(at: index)
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
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = NTSectionType(rawValue: (indexPath as NSIndexPath).section)?.cellIdentifier()
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!)

        switch (indexPath as NSIndexPath).section {
        case NTSectionType.operations.rawValue:
            let operationCell = cell as! NATOperationCell
            cell?.textLabel?.text = NTOperationsRow(rawValue: (indexPath as NSIndexPath).row)?.tableViewCellTitle()

            switch (indexPath as NSIndexPath).row {
            case NTOperationsRow.monitoring.rawValue:
                monitoringSwitch = operationCell.accessoryView as? UISwitch
                monitoringActivityIndicator = operationCell.activityIndicator
                monitoringSwitch.addTarget(self, action: #selector(changeMonitoringState(_:)), for: UIControlEvents.valueChanged)
                monitoringSwitch.isOn ? monitoringActivityIndicator.startAnimating() : monitoringActivityIndicator.stopAnimating()
            case NTOperationsRow.advertising.rawValue:
                advertisingSwitch = operationCell.accessoryView as? UISwitch
                advertisingActivityIndicator = operationCell.activityIndicator
                advertisingSwitch.addTarget(self, action: #selector(changeAdvertisingState(_:)), for: UIControlEvents.valueChanged)
                advertisingSwitch.isOn ? advertisingActivityIndicator.startAnimating() : advertisingActivityIndicator.stopAnimating()
            case NTOperationsRow.ranging.rawValue:
                rangingSwitch = cell?.accessoryView as? UISwitch
                rangingSwitch.addTarget(self, action: #selector(changeRangingState(_:)), for: UIControlEvents.valueChanged)
            default:
                break
            }
        case NTSectionType.detectedBeacons.rawValue:
            let beacon = detectedBeacons[(indexPath as NSIndexPath).row]

            cell = cell ?? UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellIdentifier)

            cell!.textLabel?.text = beacon.proximityUUID.uuidString
            cell!.detailTextLabel?.text = beacon.fullDetails()
            cell!.detailTextLabel?.textColor = UIColor.gray
        default:
            break
        }

        // We wouldn't normally need this, since constraints can be set in Interface Builder. However, there seems
        // to be a bug that removes all constraints from our cells upon dequeueing, so we need to trigger re-adding
        // them here. (See also NATOperationCell.swift).
        cell?.updateConstraintsIfNeeded()

        return cell!
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if rangingSwitch?.isOn == true {
            return kMaxNumberOfSections            // All sections visible
        } else {
            return kMaxNumberOfSections - 1        // Beacons section not visible
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case NTSectionType.operations.rawValue:
            return kNumberOfAvailableOperations
        case NTSectionType.detectedBeacons.rawValue:
            return self.detectedBeacons.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case NTSectionType.operations.rawValue:
            return nil
        case NTSectionType.detectedBeacons.rawValue:
            return kBeaconSectionTitle
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NTSectionType(rawValue: (indexPath as NSIndexPath).section)!.tableViewCellHeight()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView(reuseIdentifier: kBeaconsHeaderViewIdentifier)

        // Adds an activity indicator view to the section header
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
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
    func changeMonitoringState(_ monitoringSwitch: UISwitch) {
        monitoringSwitch.isOn ? monitoringOperation.startMonitoringForBeacons() : monitoringOperation.stopMonitoringForBeacons()
    }

    /**
        Starts/stops the advertising operation, depending on the state of the given switch.

        :param: advertisingSwitch The advertising UISwitch instance.
     */
    func changeAdvertisingState(_ advertisingSwitch: UISwitch) {
        advertisingSwitch.isOn ? advertisingOperation.startAdvertisingBeacon() : advertisingOperation.stopAdvertisingBeacon()
    }

    /**
        Starts/stops the ranging operation, depending on the state of the given switch.

        :param: rangingSwitch The ranging UISwitch instance.
     */
    func changeRangingState(_ rangingSwitch: UISwitch) {
        rangingSwitch.isOn ? rangingOperation.startRangingForBeacons() : rangingOperation.stopRangingForBeacons()
    }
}

// MARK: - Monitoring delegate methods and helpers
extension NATViewController: NATMonitoringOperationDelegate
{
    /**
        Triggered by the monitoring operation when it has started successfully and turns the monitoring switch and
        activity indicator on.
     */
    func monitoringOperationDidStartSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringSwitch.isOn = true
            self.monitoringActivityIndicator.startAnimating()
        }
    }

    /**
        Triggered by the monitoring operation when it has stopped successfully and turns the activity indicator off.
     */
    func monitoringOperationDidStopSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringActivityIndicator.stopAnimating()
        }
    }

    /**
        Triggered by the monitoring operation whe it has failed to start and turns the monitoring switch off.
     */
    func monitoringOperationDidFailToStart() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringSwitch.isOn = false
        }
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

        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        let settingsAction = UIAlertAction.init(title: settingsButtonTitle, style: UIAlertActionStyle.default) {
                (action: UIAlertAction) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alertController.addAction(cancelAction);
        alertController.addAction(settingsAction);
        self.present(alertController, animated: true, completion: nil)

        DispatchQueue.main.async { () -> Void in
            self.monitoringSwitch.isOn = false
        }
    }

    /**
        Triggered by the monitoring operation when it has detected entering the provided region. It emits 
        a local notification.
        
        :param: region The provided region that the monitoring operation detected.
     */
    func monitoringOperationDidDetectEnteringRegion(_ region: CLBeaconRegion) {
        sendLocalNotificationForBeaconRegion(region)
    }

    /**
        Emits a UILocalNotification with information about the given region.
    
        Note that major and minor are not available at the monitoring stage.
    
        :param: region The given CLBeaconRegion instance.
     */
    func sendLocalNotificationForBeaconRegion(_ region: CLBeaconRegion) {
        let notification = UILocalNotification()

        notification.alertBody = "Entered beacon region for UUID: " + region.proximityUUID.uuidString
        notification.alertAction = "View Details"
        notification.soundName = UILocalNotificationDefaultSoundName

        UIApplication.shared.presentLocalNotificationNow(notification)
    }
}

// MARK: - Advertising delegate methods
extension NATViewController: NATAdvertisingOperationDelegate
{
    /**
        Triggered by the advertising operation when it has started successfully and turns the advertising switch and the
        activity indicator on.
     */
    func advertisingOperationDidStartSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.advertisingSwitch.isOn = true
            self.advertisingActivityIndicator.startAnimating()
        }
    }

    /**
        Triggered by the advertising operation when it has stopped successfully and turns the activity indicator off.
     */
    func advertisingOperationDidStopSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.advertisingActivityIndicator.stopAnimating()
        }
    }

    /**
        Triggered by the advertising operation when ithas failed to start and turns the advertising switch off.
     */
    func advertisingOperationDidFailToStart() {
        let title = "Bluetooth is off"
        let message = "It seems that Bluetooth is off. For advertising to work, please turn Bluetooth on."
        let cancelButtonTitle = "OK"

        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(cancelAction);
        self.present(alertController, animated: true, completion: nil)

        DispatchQueue.main.async { () -> Void in
            self.advertisingSwitch.isOn = false
        }
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

        DispatchQueue.main.async { () -> Void in
            self.rangingSwitch.isOn = true
        }
    }

    /**
        Triggered by the ranging operation when it has failed to start and turns the ranging switch off.
     */
    func rangingOperationDidFailToStart() {
        DispatchQueue.main.async { () -> Void in
            self.rangingSwitch.isOn = false
        }
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

        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        let settingsAction = UIAlertAction.init(title: settingsButtonTitle, style: UIAlertActionStyle.default) {
            (action: UIAlertAction) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alertController.addAction(cancelAction);
        alertController.addAction(settingsAction);
        self.present(alertController, animated: true, completion: nil)

        DispatchQueue.main.async { () -> Void in
            self.rangingSwitch.isOn = false
        }
    }

    /**
        Triggered by the ranging operation when it has stopped successfully. It updates the beacon table view to reflect
        that the ranging has stopped.
     */
    func rangingOperationDidStopSuccessfully() {
        detectedBeacons = []

        DispatchQueue.main.async { () -> Void in
            self.beaconTableView.beginUpdates()
            if let deletedSections = self.deletedSections() {
                self.beaconTableView.deleteSections(deletedSections, with: UITableViewRowAnimation.fade)
            }
            self.beaconTableView.endUpdates()
        }
    }

    /**
        Triggered by the ranging operation when it has detected beacons belonging to a specific given beacon region.
        
        It updates the table view to show the newly-found beacons.

        :param: beacons An array of provided beacons that the ranging operation detected.
        :param: region A provided region whose beacons the operation is trying to range.
     */
    func rangingOperationDidRangeBeacons(_ beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        DispatchQueue.main.async { () -> Void in
            let filteredBeacons = self.filteredBeacons(beacons as! [CLBeacon])

            if filteredBeacons.isEmpty {
                print("No beacons found nearby.")
            } else {
                let beaconsString: String

                if filteredBeacons.count > 1 {
                    beaconsString = "beacons"
                } else {
                    beaconsString = "beacon"
                }
                print("Found \(filteredBeacons.count) \(beaconsString).")
            }

            let insertedRows = self.indexPathsOfInsertedBeacons(filteredBeacons)
            let deletedRows = self.indexPathsOfRemovedBeacons(filteredBeacons)
            var reloadedRows: [IndexPath]?
            if deletedRows == nil && insertedRows == nil {
                reloadedRows = self.indexPathsForBeacons(filteredBeacons)
            }

            self.detectedBeacons = filteredBeacons

            self.beaconTableView.beginUpdates()
            if self.insertedSections() != nil {
                self.beaconTableView.insertSections(self.insertedSections()!, with: UITableViewRowAnimation.fade)
            }
            if self.deletedSections() != nil {
                self.beaconTableView.deleteSections(self.deletedSections()!, with: UITableViewRowAnimation.fade)
            }
            if insertedRows != nil {
                self.beaconTableView.insertRows(at: insertedRows!, with: UITableViewRowAnimation.fade)
            }
            if deletedRows != nil {
                self.beaconTableView.deleteRows(at: deletedRows!, with: UITableViewRowAnimation.fade)
            }
            if reloadedRows != nil {
                self.beaconTableView.reloadRows(at: reloadedRows!, with: UITableViewRowAnimation.fade)
            }
            self.beaconTableView.endUpdates()
        }
    }
}

// MARK: - Notifications
extension NATViewController
{
    /**
        Triggers any of the three operations in the app. It effectively reflects the actions taken on the watch
        by updating the action UI and triggering the operations, based on the updated UI.
    
        :param: notification The notification object that caused this method to be called.
     */
    func performWatchAction(_ notification: Notification) {
        var payload = (notification as NSNotification).userInfo as! [String : NSNumber]

        if let monitoringState = payload["Monitoring"] {
            DispatchQueue.main.async(execute: { () -> Void in
                self.monitoringSwitch.setOn(monitoringState.boolValue, animated: true)
            })
            changeMonitoringState(monitoringSwitch)
        } else if let advertisingState = payload["Advertising"] {
            DispatchQueue.main.async(execute: { () -> Void in
                self.advertisingSwitch.setOn(advertisingState.boolValue, animated: true)
            })
            changeAdvertisingState(advertisingSwitch)
        } else if let rangingState = payload["Ranging"] {
            DispatchQueue.main.async(execute: { () -> Void in
                self.rangingSwitch.setOn(rangingState.boolValue, animated: true)
                self.changeRangingState(self.rangingSwitch)
            })
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
        case .near:
            proximityText = "Near"
        case .immediate:
            proximityText = "Immediate"
        case .far:
            proximityText = "Far"
        case .unknown:
            proximityText = "Unknown"
        }

        return "\(major), \(minor) •  \(proximityText) • \(accuracy) • \(rssi)"
    }
}

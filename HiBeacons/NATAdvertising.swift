//
//  NATAdvertising.swift
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
import CoreBluetooth

protocol NATAdvertisingDelegate {
    func advertisingOperationDidStartSuccessfully()
    func advertisingOperationDidFailToStart()
    func advertisingOperationDidStopSuccessfully()
}

class NATAdvertising: NATOperation, CBPeripheralManagerDelegate
{
    var delegate: NATAdvertisingDelegate?
    var peripheralManager: CBPeripheralManager?
    
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
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
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

        if delegate != nil {
            delegate!.advertisingOperationDidStopSuccessfully()
        }

        NSLog("Turned off advertising.")
    }

    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error != nil {
            NSLog("Couldn't turn on advertising: \(error)")
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
        }

        if peripheralManager!.isAdvertising {
            NSLog("Turned on advertising.")
            if delegate != nil {
                delegate!.advertisingOperationDidStartSuccessfully()
            }
        }
    }

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheralManager?.state != CBPeripheralManagerState.PoweredOn {
            NSLog("Peripheral manager is off.")
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
            return
        }

        NSLog("Peripheral manager is on.")
        turnOnAdvertising()
    }
}

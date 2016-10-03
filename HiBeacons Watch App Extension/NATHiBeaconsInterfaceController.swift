//
//  NATHiBeaconsInterfaceController.swift
//  HiBeacons Watch App Extension
//
//  Created by Nick Toumpelis on 2015-08-06.
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

import WatchKit
import WatchConnectivity
import Foundation

class NATHiBeaconsInterfaceController: WKInterfaceController
{
    @IBOutlet weak var monitoringButton: WKInterfaceButton?
    @IBOutlet weak var advertisingButton: WKInterfaceButton?
    @IBOutlet weak var rangingButton: WKInterfaceButton?

    var monitoringActive = false
    var advertisingActive = false
    var rangingActive = false

    var defaultSession: WCSession?

    let activeBackgroundColor = UIColor(red: 0.34, green: 0.7, blue: 0.36, alpha: 1.0)
    let inactiveBackgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        monitoringButton?.setBackgroundColor(inactiveBackgroundColor)
        advertisingButton?.setBackgroundColor(inactiveBackgroundColor)
        rangingButton?.setBackgroundColor(inactiveBackgroundColor)

        if WCSession.isSupported() {
            defaultSession = WCSession.default()
            defaultSession!.delegate = self
            defaultSession!.activate()
        }
    }
    
    @IBAction func toggleMonitoring() {
        setMonitoringActive(to: !monitoringActive)

        let payload = ["Monitoring": monitoringActive]
        defaultSession!.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    func setMonitoringActive(to value: Bool) {
        if defaultSession!.isReachable != true {
            return
        }

        monitoringActive = value

        let backgroundColor = monitoringActive ? activeBackgroundColor : inactiveBackgroundColor
        monitoringButton?.setBackgroundColor(backgroundColor)
    }

    @IBAction func toggleAdvertising() {
        setAdvertisingActive(to: !advertisingActive)

        let payload = ["Advertising": advertisingActive]
        defaultSession!.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    func setAdvertisingActive(to value: Bool) {
        if defaultSession!.isReachable != true {
            return
        }

        advertisingActive = value

        let backgroundColor = advertisingActive ? activeBackgroundColor : inactiveBackgroundColor
        advertisingButton?.setBackgroundColor(backgroundColor)
    }

    @IBAction func toggleRanging() {
        setRangingActive(to: !rangingActive)

        let payload = ["Ranging": rangingActive]
        defaultSession!.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    func setRangingActive(to value: Bool) {
        if defaultSession!.isReachable != true {
            return
        }

        rangingActive = value

        let backgroundColor = rangingActive ? activeBackgroundColor : inactiveBackgroundColor
        rangingButton?.setBackgroundColor(backgroundColor)
    }
}

extension NATHiBeaconsInterfaceController: WCSessionDelegate
{
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        if error != nil {
            print("Session failed to activate with error: \(error.debugDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let value = message["Monitoring"] as? Bool {
            setMonitoringActive(to: value)
        } else if let value = message["Advertising"] as? Bool {
            setAdvertisingActive(to: value)
        } else if let value = message["Ranging"] as? Bool {
            setRangingActive(to: value)
        }
    }
}

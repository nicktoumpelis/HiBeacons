//
//  NATHiBeaconsInterfaceController.swift
//  HiBeacons Watch App Extension
//
//  Created by Nick Toumpelis on 2015-08-06.
//  Copyright © 2015 Nick Toumpelis. All rights reserved.
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

    /// MARK: Operation (nested enumeration)

    /**
        `NATHiBeaconsOperation` encapsulates the three kinds of operations possible to perform in HiBeacons.
     */
    enum NATHiBeaconsOperation: String {
        case monitoring         /// The monitoring operation.
        case advertising        /// The advertising operation.
        case ranging            /// The ranging operation.
    }

    /**
        Helper method that returns the WKInterfaceButton instance associated with a given operation.
        
        :param: operation A given operation.
        :returns: An instance of a WKInterfaceButton.
     */
    func buttonFor(operation: NATHiBeaconsOperation) -> WKInterfaceButton? {
        switch operation {
        case .monitoring:
            return monitoringButton
        case .advertising:
            return advertisingButton
        case .ranging:
            return rangingButton
        }
    }

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

    /**
        Changes the local state to a given value for the given operation. (The local state should always reflect
        the "reality" of the operations happening on the phone.)

        :param: value The new value of the active state for the given operation.
        :param: operation The operation for which the active state should be changed.
     */
    func setActiveState(_ value: Bool, forOperation operation: NATHiBeaconsOperation) {
        if defaultSession!.isReachable != true {
            return
        }

        switch operation {
        case .monitoring:
            monitoringActive = value
        case .advertising:
            advertisingActive = value
        case .ranging:
            rangingActive = value
        }

        let backgroundColor = value ? activeBackgroundColor : inactiveBackgroundColor
        buttonFor(operation: operation)?.setBackgroundColor(backgroundColor)
    }

    /**
        Prepares and sends a message to trigger a change to a given state of the given operation
        on the phone.
     
        :param: operation The operation for which the state should be changed.
        :param: state The new state for the given operation.
     */
    func sendMessageFor(operation: NATHiBeaconsOperation, withState state: Bool) {
        let payload = [operation.rawValue: state]
        defaultSession!.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    /**
        Toggles the state of the monitoring operation.
     */
    @IBAction func toggleMonitoring() {
        setActiveState(!monitoringActive, forOperation: NATHiBeaconsOperation.monitoring)
        sendMessageFor(operation: NATHiBeaconsOperation.monitoring, withState: monitoringActive)
    }

    /**
        Toggles the state of the advertising operation.
     */
    @IBAction func toggleAdvertising() {
        setActiveState(!advertisingActive, forOperation: NATHiBeaconsOperation.advertising)
        sendMessageFor(operation: NATHiBeaconsOperation.advertising, withState: advertisingActive)
    }

    /**
        Toggles the state of the ranging operation.
     */
    @IBAction func toggleRanging() {
        setActiveState(!rangingActive, forOperation: NATHiBeaconsOperation.ranging)
        sendMessageFor(operation: NATHiBeaconsOperation.ranging, withState: rangingActive)
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

    /**
        Called immediately when a message arrives. In this case, it processes each message to change
        the active state of an operation to reflect the state on the phone.
     */
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let state = message[NATHiBeaconsOperation.monitoring.rawValue] as? Bool {
            setActiveState(state, forOperation: NATHiBeaconsOperation.monitoring)
        } else if let state = message[NATHiBeaconsOperation.advertising.rawValue] as? Bool {
            setActiveState(state, forOperation: NATHiBeaconsOperation.advertising)
        } else if let state = message[NATHiBeaconsOperation.ranging.rawValue] as? Bool {
            setActiveState(state, forOperation: NATHiBeaconsOperation.ranging)
        }
    }
}

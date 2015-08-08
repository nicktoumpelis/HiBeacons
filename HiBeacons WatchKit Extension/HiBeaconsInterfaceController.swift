//
//  HiBeaconsInterfaceController.swift
//  HiBeacons WatchKit Extension
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
import Foundation

class HiBeaconsInterfaceController: WKInterfaceController
{
    @IBOutlet weak var monitoringButton: WKInterfaceButton?
    @IBOutlet weak var advertisingButton: WKInterfaceButton?
    @IBOutlet weak var rangingButton: WKInterfaceButton?

    private var monitoringActive = false
    private var advertisingActive = false
    private var rangingActive = false

    let activeBackgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
    let inactiveBackgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    @IBAction func toggleMonitoring() {
        monitoringActive = !monitoringActive

        var backgroundColor = monitoringActive ? activeBackgroundColor : inactiveBackgroundColor
        monitoringButton?.setBackgroundColor(backgroundColor)

        let payload = ["Monitoring": NSNumber(bool: monitoringActive)]
        WKInterfaceController.openParentApplication(payload, reply: nil)
    }

    @IBAction func toggleAdvertising() {
        advertisingActive = !advertisingActive

        var backgroundColor = advertisingActive ? activeBackgroundColor : inactiveBackgroundColor
        advertisingButton?.setBackgroundColor(backgroundColor)

        let payload = ["Advertising": NSNumber(bool: advertisingActive)]
        WKInterfaceController.openParentApplication(payload, reply: nil)
    }

    @IBAction func toggleRanging() {
        rangingActive = !rangingActive

        var backgroundColor = rangingActive ? activeBackgroundColor : inactiveBackgroundColor
        rangingButton?.setBackgroundColor(backgroundColor)

        let payload = ["Ranging": NSNumber(bool: rangingActive)]
        WKInterfaceController.openParentApplication(payload, reply: nil)
    }
}

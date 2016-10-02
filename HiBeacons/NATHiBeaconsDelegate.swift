//
//  NATHiBeaconsDelegate.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-21.
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
import WatchConnectivity

///  The app delegate
@UIApplicationMain class NATHiBeaconsDelegate: UIResponder, UIApplicationDelegate
{
    /// The notification name for any watch-originating operation
    static let NATHiBeaconsWatchNotificationName = "NATHiBeaconsWatchNotificationName"

    /// The main window
    var window: UIWindow?
    var mainSession: WCSession!

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if WCSession.isSupported() {
            mainSession = WCSession.default()
            mainSession.delegate = self
            mainSession.activate()
        }
        
        return true
    }
}

// MARK: WCSessionDelegate methods
extension NATHiBeaconsDelegate: WCSessionDelegate
{
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        if error != nil {
            print("Session failed to activate with error: \(error.debugDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Notification.Name(rawValue: NATHiBeaconsDelegate.NATHiBeaconsWatchNotificationName), object: self, userInfo: message)
    }

    public func sessionDidDeactivate(_ session: WCSession) { }

    public func sessionDidBecomeInactive(_ session: WCSession) { }
}

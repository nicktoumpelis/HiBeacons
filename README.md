HiBeacons
=========
**A Swift demo app for the iBeacons API in iOS 9, with Apple Watch support**

HiBeacons is a fully functional demo app for the iBeacons API in iOS 9, updated for Swift 2.1. The app can be used to demonstrate beacon region monitoring, advertising and ranging, simply by toggling on/off three switches in the UI. 

The app also supports the Apple Watch, and implements a basic interface for starting all the operations from a WatchKit app. (The watch app acts as a dumb* remote).

The source is easy to understand and modify. The structure of the app is based on a simple hierarchy of operation classes. There are three `NATOperation` subclasses, each responsible of a specific operation: `NATMonitoringOperation`, `NATAdvertisingOperation`, and `NATRangingOperation`. The app is easy to use with any given proximity UUID and identifier, which can be changed in `NATOperation`.

The app is fully documented, using the reStructuredText standard, which SourceKit can parse.

The main branch of the project is the *swift* branch, but you can still find the old Objective-C code at the *obj-c* branch. Note that the old branch has some bugs, that I have fixed in the new one.

*The app is fully documented, and should work well with Xcode 7.2, iOS 9, and watchOS 2.*

## Screenshots

![Phone-Screenshot](https://github.com/nicktoumpelis/HiBeacons/blob/swift/screenshot.png)

![Watch-Screenshot](https://github.com/nicktoumpelis/HiBeacons/blob/swift/watch-screenshot.png)

## Notes

- The UI shows only a small number of alerts, when major issues occur. To understand the process better, you can easily follow the Console logs.
- Monitoring works when the app is in the background. You will get a local notification when entering the specified beacon region.
- The app can only monitor and range a single beacon region. (It can easily be extended for multiple.)
- With advertising turned on, the app will show itself as a beacon on other instances of the app, running on other devices. It cannot range or monitor itself. (It's how the API works.)
- Major and minor integers are generated randomly every time a new advertising session starts.
- You can find and set the UUID and identifier for the region in `NATOperation.swift`.

\* The Watch app can trigger actions on the device, but cannot reflect the state of the device, yet.

## Contact

[Nick Toumpelis](http://github.com/nicktoumpelis) ([@nicktoumpelis](https://twitter.com/nicktoumpelis))

## Licence

HiBeacons is available under the MIT licence. See the LICENCE file for more info.

HiBeacons
=========
**A Swift demo app for the iBeacons API in iOS 8**

HiBeacons is a fully functional demo app for the iBeacons API in iOS 8 and is now written in Swift. The app can be used to demonstrate beacon monitoring, advertising and ranging, by toggling on/off three switches. After changing the proximity UUID in the source you can easily see any beacons in the vicinity, with all their info, under the 'Detected Beacons' section.

The main branch of the project is the *swift* branch, but you can still find the old Objective-C code at the *obj-c* branch. Note that the old branch has some bugs, that I have fixed in the new one.

**Current state:**
The current state of the app is that it has been converted to Swift, but there is a lot that needs to be done to truly take advantage of the freedom, safety and power of Swift.

*The app should compile with Xcode 6.4 and work correctly on iOS 8.*

## Screenshot
![Screenshot](https://raw.github.com/nicktoumpelis/HiBeacons/swift/screenshot.png)

## Notes

- Monitoring works when the app is in the background. You will get a local notification when entering a beacon region.
- The app can only monitor and range a single beacon region, but can easily be extended for multiple.
- You can find and set the UUID and identifier for the beacon (and the region) at the top of NTViewController.m. 
- Major and minor integers are generated randomly every time a new advertising session starts. 
- The app cannot list itself as a beacon, even if you toggle advertising on. (It's how the API works.) You need to run another instance of the app for that.
- The UI doesn't show any alerts; check the console for more details.

## Contact

[Nick Toumpelis](http://github.com/nicktoumpelis) ([@nicktoumpelis](https://twitter.com/nicktoumpelis))

## Licence

HiBeacons is available under the MIT licence. See the LICENCE file for more info.

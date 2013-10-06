HiBeacons
=========

HiBeacons is a fully functional demo app for the new iBeacons API in iOS 7. The app can be used to demonstrate both beacon advertising and ranging, by toggling on/off two switches. You can easily see any beacons in the vicinity, with all their info, under the 'Detected Beacons' section.

## Screenshot
![Screenshot](https://raw.github.com/nicktoumpelis/HiBeacons/master/screenshot.png)

## Notes

* The app can only monitor a single beacon region, but can easily be extended for multiple.
* You can find and set the UUID and identifier for the beacon (and the region) at the top of NTViewController.m. 
* Major and minor integers are generated randomly every time a new advertising session starts. 
* The app will not list itself as a beacon, even if you toggle advertising on. (It's how the API works.) You need to run another instance of the app for that.
* The UI doesn't show any alerts; check the console for more details.

## Contact

[Nick Toumpelis](http://github.com/nicktoumpelis) ([@nicktoumpelis](https://twitter.com/nicktoumpelis))

## License

HiBeacons is available under the MIT license. See the LICENSE file for more info.

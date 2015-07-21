//
//  NATViewController.m
//  HiBeacons
//
//  Created by Nick Toumpelis on 2013-10-06.
//  Copyright (c) 2013-2014 Nick Toumpelis.
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

#import "NATViewController.h"

static NSString * const kUUID = @"00000000-0000-0000-0000-000000000000";
static NSString * const kIdentifier = @"SomeIdentifier";

static NSString * const kOperationCellIdentifier = @"OperationCell";
static NSString * const kBeaconCellIdentifier = @"BeaconCell";

static NSString * const kMonitoringOperationTitle = @"Monitoring";
static NSString * const kAdvertisingOperationTitle = @"Advertising";
static NSString * const kRangingOperationTitle = @"Ranging";
static NSUInteger const kNumberOfSections = 2;
static NSUInteger const kNumberOfAvailableOperations = 3;
static CGFloat const kOperationCellHeight = 44;
static CGFloat const kBeaconCellHeight = 52;
static NSString * const kBeaconSectionTitle = @"Looking for beacons...";
static CGPoint const kActivityIndicatorPosition = (CGPoint){205, 12};
static NSString * const kBeaconsHeaderViewIdentifier = @"BeaconsHeader";

static void * const kMonitoringOperationContext = (void *)&kMonitoringOperationContext;
static void * const kRangingOperationContext = (void *)&kRangingOperationContext;

typedef NS_ENUM(NSUInteger, NTSectionType) {
    NTOperationsSection,
    NTDetectedBeaconsSection
};

typedef NS_ENUM(NSUInteger, NTOperationsRow) {
    NTMonitoringRow,
    NTAdvertisingRow,
    NTRangingRow
};

@interface NATOperationCell : UITableViewCell

@end

@implementation NATOperationCell

- (void)updateConstraints
{
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *rightMarginConstraint = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                                                             attribute:NSLayoutAttributeRight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self
                                                                             attribute:NSLayoutAttributeRight
                                                                            multiplier:1.0
                                                                              constant:-14];
    
    NSLayoutConstraint *topMarginConstraint = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0
                                                                            constant:7];
    [self addConstraints:@[rightMarginConstraint, topMarginConstraint]];
    
    [super updateConstraints];
}

@end

@interface NATViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, weak) UISwitch *monitoringSwitch;
@property (nonatomic, weak) UISwitch *advertisingSwitch;
@property (nonatomic, weak) UISwitch *rangingSwitch;
@property (nonatomic, unsafe_unretained) void *operationContext;

@end

@implementation NATViewController

#pragma mark - Index path management
- (NSArray *)indexPathsOfRemovedBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (CLBeacon *existingBeacon in self.detectedBeacons) {
        BOOL stillExists = NO;
        for (CLBeacon *beacon in beacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                stillExists = YES;
                break;
            }
        }
        if (!stillExists) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
        }
        row++;
    }
    
    return indexPaths;
}

- (NSArray *)indexPathsOfInsertedBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (CLBeacon *beacon in beacons) {
        BOOL isNewBeacon = YES;
        for (CLBeacon *existingBeacon in self.detectedBeacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                isNewBeacon = NO;
                break;
            }
        }
        if (isNewBeacon) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
        }
        row++;
    }
    
    return indexPaths;
}

- (NSArray *)indexPathsForBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger row = 0; row < beacons.count; row++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:NTDetectedBeaconsSection]];
    }
    
    return indexPaths;
}

- (NSIndexSet *)insertedSections
{
    if (self.rangingSwitch.on && [self.beaconTableView numberOfSections] == kNumberOfSections - 1) {
        return [NSIndexSet indexSetWithIndex:1];
    } else {
        return nil;
    }
}

- (NSIndexSet *)deletedSections
{
    if (!self.rangingSwitch.on && [self.beaconTableView numberOfSections] == kNumberOfSections) {
        return [NSIndexSet indexSetWithIndex:1];
    } else {
        return nil;
    }
}

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

#pragma mark - Table view functionality
- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"Unknown";
            break;
    }
    
    NSString *format = @"%@, %@ • %@ • %f • %li";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case NTOperationsSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:kOperationCellIdentifier];
            switch (indexPath.row) {
                case NTMonitoringRow:
                    cell.textLabel.text = kMonitoringOperationTitle;
                    self.monitoringSwitch = (UISwitch *)cell.accessoryView;
                    [self.monitoringSwitch addTarget:self
                                              action:@selector(changeMonitoringState:)
                                    forControlEvents:UIControlEventTouchUpInside];
                    break;
                case NTAdvertisingRow:
                    cell.textLabel.text = kAdvertisingOperationTitle;
                    self.advertisingSwitch = (UISwitch *)cell.accessoryView;
                    [self.advertisingSwitch addTarget:self
                                               action:@selector(changeAdvertisingState:)
                                     forControlEvents:UIControlEventValueChanged];
                    break;
                case NTRangingRow:
                default:
                    cell.textLabel.text = kRangingOperationTitle;
                    self.rangingSwitch = (UISwitch *)cell.accessoryView;
                    [self.rangingSwitch addTarget:self
                                           action:@selector(changeRangingState:)
                                 forControlEvents:UIControlEventValueChanged];
                    break;
            }
        }
            break;
        case NTDetectedBeaconsSection:
        default: {
            CLBeacon *beacon = self.detectedBeacons[indexPath.row];
            
            cell = [tableView dequeueReusableCellWithIdentifier:kBeaconCellIdentifier];
            
            if (!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:kBeaconCellIdentifier];
            
            cell.textLabel.text = beacon.proximityUUID.UUIDString;
            cell.detailTextLabel.text = [self detailsStringForBeacon:beacon];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
            break;
    }

    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.rangingSwitch.on) {
        return kNumberOfSections;       // All sections visible
    } else {
        return kNumberOfSections - 1;   // Beacons section not visible
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case NTOperationsSection:
            return kNumberOfAvailableOperations;
        case NTDetectedBeaconsSection:
        default:
            return self.detectedBeacons.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case NTOperationsSection:
            return nil;
        case NTDetectedBeaconsSection:
        default:
            return kBeaconSectionTitle;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case NTOperationsSection:
            return kOperationCellHeight;
        case NTDetectedBeaconsSection:
        default:
            return kBeaconCellHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView =
    [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:kBeaconsHeaderViewIdentifier];
    
    // Adds an activity indicator view to the section header
    UIActivityIndicatorView *indicatorView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [headerView addSubview:indicatorView];
    
    indicatorView.frame = (CGRect){kActivityIndicatorPosition, indicatorView.frame.size};
    
    [indicatorView startAnimating];
    
    return headerView;
}

#pragma mark - Common
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

#pragma mark - Beacon ranging
- (void)changeRangingState:sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startRangingForBeacons];
    } else {
        [self stopRangingForBeacons];
    }
}

- (void)startRangingForBeacons
{
    self.operationContext = kRangingOperationContext;
    
    [self createLocationManager];

    [self checkLocationAccessForRanging];
    
    self.detectedBeacons = [NSArray array];
    [self turnOnRanging];
}

- (void)turnOnRanging
{
    NSLog(@"Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        self.rangingSwitch.on = NO;
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    NSIndexSet *deletedSections = [self deletedSections];
    self.detectedBeacons = [NSArray array];
    
    [self.beaconTableView beginUpdates];
    if (deletedSections)
        [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
    [self.beaconTableView endUpdates];
    
    NSLog(@"Turned off ranging.");
}

#pragma mark - Beacon region monitoring
- (void)changeMonitoringState:sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startMonitoringForBeacons];
    } else {
        [self stopMonitoringForBeacons];
    }
}

- (void)startMonitoringForBeacons
{
    self.operationContext = kMonitoringOperationContext;
    
    [self createLocationManager];

    [self checkLocationAccessForMonitoring];
    
    [self turnOnMonitoring];
}

- (void)turnOnMonitoring
{
    NSLog(@"Turning on monitoring...");
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
        self.monitoringSwitch.on = NO;
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"Monitoring turned on for region: %@.", self.beaconRegion);
}

- (void)stopMonitoringForBeacons
{
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"Turned off monitoring");
}

#pragma mark - Location manager delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        if (self.operationContext == kMonitoringOperationContext) {
            NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
            self.monitoringSwitch.on = NO;
            return;
        } else {
            NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
            self.rangingSwitch.on = NO;
            return;
        }
    }
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    switch (authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.operationContext == kMonitoringOperationContext) {
                self.monitoringSwitch.on = YES;
            } else {
                self.rangingSwitch.on = YES;
            }
            return;

        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.operationContext == kMonitoringOperationContext) {
                NSLog(@"Couldn't turn on monitoring: Required Location Access(Always) missing.");
                self.monitoringSwitch.on = NO;
            } else {
                self.rangingSwitch.on = YES;
            }
            return;

        default:
            if (self.operationContext == kMonitoringOperationContext) {
                NSLog(@"Couldn't turn on monitoring: Required Location Access(Always) missing.");
                self.monitoringSwitch.on = NO;
                return;
            } else {
                NSLog(@"Couldn't turn on monitoring: Required Location Access(WhenInUse) missing.");
                self.rangingSwitch.on = NO;
                return;
            }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found %lu %@.", (unsigned long)[filteredBeacons count],
                [filteredBeacons count] > 1 ? @"beacons" : @"beacon");
    }
    
    NSIndexSet *insertedSections = [self insertedSections];
    NSIndexSet *deletedSections = [self deletedSections];
    NSArray *deletedRows = [self indexPathsOfRemovedBeacons:filteredBeacons];
    NSArray *insertedRows = [self indexPathsOfInsertedBeacons:filteredBeacons];
    NSArray *reloadedRows = nil;
    if (!deletedRows && !insertedRows)
        reloadedRows = [self indexPathsForBeacons:filteredBeacons];
    
    self.detectedBeacons = filteredBeacons;
    
    [self.beaconTableView beginUpdates];
    if (insertedSections)
        [self.beaconTableView insertSections:insertedSections withRowAnimation:UITableViewRowAnimationFade];
    if (deletedSections)
        [self.beaconTableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationFade];
    if (insertedRows)
        [self.beaconTableView insertRowsAtIndexPaths:insertedRows withRowAnimation:UITableViewRowAnimationFade];
    if (deletedRows)
        [self.beaconTableView deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationFade];
    if (reloadedRows)
        [self.beaconTableView reloadRowsAtIndexPaths:reloadedRows withRowAnimation:UITableViewRowAnimationNone];
    [self.beaconTableView endUpdates];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Entered region: %@", region);
    
    [self sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exited region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
        case CLRegionStateUnknown:
            stateString = @"unknown";
            break;
    }
    NSLog(@"State changed to %@ for region %@.", stateString, region);
}

#pragma mark - Local notifications
- (void)sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region
{
    UILocalNotification *notification = [UILocalNotification new];
    
    // Notification details
    notification.alertBody = [NSString stringWithFormat:@"Entered beacon region for UUID: %@",
        region.proximityUUID.UUIDString];   // Major and minor are not available at the monitoring stage
    notification.alertAction = NSLocalizedString(@"View Details", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - Beacon advertising
- (void)changeAdvertisingState:sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    if (theSwitch.on) {
        [self startAdvertisingBeacon];
    } else {
        [self stopAdvertisingBeacon];
    }
}

- (void)startAdvertisingBeacon
{
    NSLog(@"Turning on advertising...");
    
    [self createBeaconRegion];
    
    if (!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self turnOnAdvertising];
}

- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        self.advertisingSwitch.on = NO;
        return;
    }
    
    time_t t;
    srand((unsigned) time(&t));
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:rand()
                                                                     minor:rand()
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"Turning on advertising for region: %@.", region);
}

- (void)stopAdvertisingBeacon
{
    [self.peripheralManager stopAdvertising];
    
    NSLog(@"Turned off advertising.");
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
        self.advertisingSwitch.on = NO;
        return;
    }
    
    if (peripheralManager.isAdvertising) {
        NSLog(@"Turned on advertising.");
        self.advertisingSwitch.on = YES;
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        self.advertisingSwitch.on = NO;
        return;
    }

    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}

#pragma mark - Location access methods (iOS8/Xcode6)
- (void)checkLocationAccessForRanging {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)checkLocationAccessForMonitoring {
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusDenied ||
            authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Missing"
                                                            message:@"Required Location Access(Always) missing. Click Settings to update Location Access."
                                                           delegate:self
                                                  cancelButtonTitle:@"Settings"
                                                  otherButtonTitles:@"Cancel", nil];
            [alert show];
            self.monitoringSwitch.on = NO;
            return;
        }
        [self.locationManager requestAlwaysAuthorization];
    }
}

#pragma mark - Alert view delegate methods
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end

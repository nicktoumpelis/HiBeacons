//
//  NTViewController.m
//  HiBeacons
//
//  Created by Nick Toumpelis on 2013-10-06.
//  Copyright (c) 2013 Nick Toumpelis.
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

#import "NTViewController.h"
#import <asl.h>

static NSString * const kUUID = @"00000000-0000-0000-0000-000000000000";
static NSString * const kIdentifier = @"SomeIdentifier";

@interface NTViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSMutableString *consoleString;
@property (nonatomic, strong) NSTimer *consoleTimer;

@end

@implementation NTViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.consoleTextView.contentInset = UIEdgeInsetsZero;
    self.consoleTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                         target:self
                                                       selector:@selector(timerFireMethod:)
                                                       userInfo:nil
                                                        repeats:YES];
    [self updateConsoleTextViewForInterval:0.0f];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.advertisingSwitch addTarget:self
                              action:@selector(changeAdvertisingState:)
                    forControlEvents:UIControlEventValueChanged];
    [self.rangingSwitch addTarget:self
                              action:@selector(changeRangingState:)
                    forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Beacon ranging
- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
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
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.activityType = CLActivityTypeFitness;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self turnOnRanging];
}

- (void)stopRangingForBeacons
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Turned off ranging.");
}

#pragma mark - Beacon ranging delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
        self.rangingSwitch.on = NO;
        return;
    }
     
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on ranging: Location services not authorised.");
        self.rangingSwitch.on = NO;
        return;
    }
    
    self.rangingSwitch.on = YES;
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    if ([beacons count] == 0) {
        NSLog(@"No beacons found nearby.");
        return;
    }
    
    NSLog(@"Found beacons: \n");
    NSUInteger count = 1;
    for (CLBeacon *beacon in beacons) {
        NSLog(@"    %lu:: (%@, %li, %li), prox: %li, accur: %f, rssi: %ld\n",
              count,
              beacon.proximityUUID,
              beacon.major.integerValue,
              beacon.minor.integerValue,
              beacon.proximity,
              beacon.accuracy,
              beacon.rssi);
        count++;
    }
}

#pragma mark - Beacon advertising
- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != 5) {
        NSLog(@"Peripheral manager is off.");
        self.advertisingSwitch.on = NO;
        return;
    }
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:1
                                                                     minor:1
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
}

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
    if (peripheralManager.state != 5) {
        NSLog(@"Peripheral manager is off.");
        self.advertisingSwitch.on = NO;
        return;
    }

    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}

#pragma mark - Console text view functionality
- (void)updateConsoleTextViewForInterval:(double)interval {
    if (!self.consoleString)
        _consoleString = [NSMutableString string];
    
    @try {
        aslclient client = asl_open(NULL, "org.nicktoumpelis.HiBeacons", ASL_OPT_STDERR|ASL_LEVEL_DEBUG);
        
        aslmsg query = asl_new(ASL_TYPE_QUERY);
        if (interval == 0) {
            asl_set_query(query, ASL_KEY_MSG, NULL, ASL_QUERY_OP_NOT_EQUAL);
        } else {
            asl_set_query(query, ASL_KEY_TIME,
                          [[NSString stringWithFormat:@"%lf", [[NSDate date] timeIntervalSince1970] - interval] UTF8String],
                          ASL_QUERY_OP_GREATER_EQUAL);
        }
        aslresponse response = asl_search(client, query);
        
        asl_free(query);
        
        aslmsg message;
        BOOL hadAtLeastOneMessage = NO;
        while ((message = aslresponse_next(response))) {
            const char *msg = asl_get(message, ASL_KEY_MSG);
            [self.consoleString appendString:[NSString stringWithCString:msg encoding:NSUTF8StringEncoding]];
            [self.consoleString appendString:@"\n"];
            hadAtLeastOneMessage = YES;
        }
        
        if (hadAtLeastOneMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.consoleTextView setText:self.consoleString];
                [self.consoleTextView scrollRangeToVisible:NSMakeRange([self.consoleTextView.text length]-1, 0)];
                [self.consoleTextView setNeedsDisplay];
            });
        }
        
        aslresponse_free(response);
        asl_close(client);
    } @catch (NSException *exception) {
        NSLog(@"Console exception: %@", exception);
    }
}

- (void)timerFireMethod:(NSTimer *)theTimer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateConsoleTextViewForInterval:1.0];
    });
}

@end

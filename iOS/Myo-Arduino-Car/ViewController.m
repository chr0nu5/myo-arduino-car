//
//  ViewController.m
//  Myo-Arduino-Car
//
//  Created by Jonathan Querubina on 4/3/15.
//  Copyright (c) 2015 Jonathan Querubina. All rights reserved.
//

#import "ViewController.h"
#import <MyoKit/MyoKit.h>

TLMPose *currentPose;

@interface ViewController ()

@end

@implementation ViewController

//myo
- (void)didTapSettings:(id)sender {
    // Note that when the settings view controller is presented to the user, it must be in a UINavigationController.
    UINavigationController *controller = [TLMSettingsViewController settingsInNavigationController];
    // Present the settings view controller modally.
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    deviceList = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    deviceList.dataSource = self;
    deviceList.delegate = self;
    [self.view addSubview:deviceList];
    
    // Data notifications are received through NSNotificationCenter.
    // Posted whenever a TLMMyo connects
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didConnectDevice:)
                                                 name:TLMHubDidConnectDeviceNotification
                                               object:nil];
    // Posted whenever a TLMMyo disconnects.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDisconnectDevice:)
                                                 name:TLMHubDidDisconnectDeviceNotification
                                               object:nil];
    // Posted whenever the user does a successful Sync Gesture.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSyncArm:)
                                                 name:TLMMyoDidReceiveArmSyncEventNotification
                                               object:nil];
    // Posted whenever Myo loses sync with an arm (when Myo is taken off, or moved enough on the user's arm).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUnsyncArm:)
                                                 name:TLMMyoDidReceiveArmUnsyncEventNotification
                                               object:nil];
    // Posted whenever Myo is unlocked and the application uses TLMLockingPolicyStandard.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUnlockDevice:)
                                                 name:TLMMyoDidReceiveUnlockEventNotification
                                               object:nil];
    // Posted whenever Myo is locked and the application uses TLMLockingPolicyStandard.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLockDevice:)
                                                 name:TLMMyoDidReceiveLockEventNotification
                                               object:nil];
    // Posted when a new orientation event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    // Posted when a new accelerometer event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAccelerometerEvent:)
                                                 name:TLMMyoDidReceiveAccelerometerEventNotification
                                               object:nil];
    // Posted when a new pose is available from a TLMMyo.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
    UIButton *buttonConfig = [[UIButton alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, 60)];
    [buttonConfig addTarget:self action:@selector(didTapSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonConfig];
    
    UILabel *buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, buttonConfig.frame.size.width, 60)];
    buttonLabel.text = @"Select Myo";
    buttonLabel.textAlignment = NSTextAlignmentCenter;
    [buttonConfig addSubview:buttonLabel];
    
    _p = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, 60)];
    _p.text = @"Pose:";
    _p.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_p];
    
    _x = [[UILabel alloc] initWithFrame:CGRectMake(0, 180, self.view.frame.size.width, 60)];
    _x.text = @"X:";
    _x.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_x];
    
    _y = [[UILabel alloc] initWithFrame:CGRectMake(0, 240, self.view.frame.size.width, 60)];
    _y.text = @"Y:";
    _y.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_y];
    
    _z = [[UILabel alloc] initWithFrame:CGRectMake(0, 300, self.view.frame.size.width, 60)];
    _z.text = @"X:";
    _z.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_z];
    
    //start bluetooth manager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

//table deviceList
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devices count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    CBPeripheral * device = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [device name], [uuids objectAtIndex:[indexPath row]]];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    _selectedPeripheral = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
    [_centralManager cancelPeripheralConnection:_selectedPeripheral];
    [_centralManager connectPeripheral:_selectedPeripheral options:nil];
}

//myo
#pragma mark - NSNotificationCenter Methods
- (void)didConnectDevice:(NSNotification *)notification {
    
    NSLog(@"Perform the Sync Gesture");
    NSLog(@"Hello Myo");
    // Show the acceleration progress bar
}

- (void)didDisconnectDevice:(NSNotification *)notification {
    // Remove the text from our labels when the Myo has disconnected.
}

- (void)didUnlockDevice:(NSNotification *)notification {
    // Update the label to reflect Myo's lock state.
    NSLog(@"Unlocked");
}

- (void)didLockDevice:(NSNotification *)notification {
    // Update the label to reflect Myo's lock state.
    NSLog(@"Locked");
}
- (void)didSyncArm:(NSNotification *)notification {
    // Retrieve the arm event from the notification's userInfo with the kTLMKeyArmSyncEvent key.
    TLMArmSyncEvent *armEvent = notification.userInfo[kTLMKeyArmSyncEvent];
    // Update the armLabel with arm information.
    NSString *armString = armEvent.arm == TLMArmRight ? @"Right" : @"Left";
    NSString *directionString = armEvent.xDirection == TLMArmXDirectionTowardWrist ? @"Toward Wrist" : @"Toward Elbow";
    NSLog(@"Arm: %@ X-Direction: %@", armString, directionString);
    NSLog(@"Locked");
}
- (void)didUnsyncArm:(NSNotification *)notification {
    // Reset the labels.
    NSLog(@"Perform the Sync Gesture");
    NSLog(@"Hello Myo");
}
- (void)didReceiveOrientationEvent:(NSNotification *)notification {
    
    //TLMOrientationEvent *orientationEvent = notification.userInfo[kTLMKeyOrientationEvent];
    
    //TLMEulerAngles *angles = [TLMEulerAngles anglesWithQuaternion:orientationEvent.quaternion];
    
    //CATransform3D rotationAndPerspectiveTransform = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, angles.pitch.radians, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, angles.yaw.radians, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, angles.roll.radians, 0.0, 0.0, -1.0));
    // Apply the rotation and perspective transform to helloLabel.
    //self.helloLabel.layer.transform = rotationAndPerspectiveTransform;
}
- (void)didReceiveAccelerometerEvent:(NSNotification *)notification {
    // Retrieve the accelerometer event from the NSNotification's userInfo with the kTLMKeyAccelerometerEvent.
    TLMAccelerometerEvent *accelerometerEvent = notification.userInfo[kTLMKeyAccelerometerEvent];
    // Get the acceleration vector from the accelerometer event.
    TLMVector3 accelerationVector = accelerometerEvent.vector;
    
    //float magnitude = TLMVector3Length(accelerationVector);
    
    //self.accelerationProgressBar.progress = magnitude / 8;
    
    float x = accelerationVector.x;
    float y = accelerationVector.y;
    float z = accelerationVector.z;
    
    _x.text = [NSString stringWithFormat:@"X: %f",x];
    _y.text = [NSString stringWithFormat:@"Y: %f",y];
    _z.text = [NSString stringWithFormat:@"Z: %f",z];
    
    //NSLog(@"%f %f %f",x,y,z);
    
    
}
- (void)didReceivePoseChange:(NSNotification *)notification {
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    currentPose = pose;
    // Handle the cases of the TLMPoseType enumeration, and change the color of helloLabel based on the pose we receive.
    switch (pose.type) {
        case TLMPoseTypeUnknown:
        case TLMPoseTypeRest:
        case TLMPoseTypeDoubleTap:
            // Changes helloLabel's font to Helvetica Neue when the user is in a rest or unknown pose.
            _p.text = @"Rest";
            [self sendValue:@"rest"];
            break;
        case TLMPoseTypeFist:
            // Changes helloLabel's font to Noteworthy when the user is in a fist pose.
            _p.text = @"Fist";
            [self sendValue:@"fist"];
            break;
        case TLMPoseTypeWaveIn:
            // Changes helloLabel's font to Courier New when the user is in a wave in pose.
            _p.text = @"Wave In";
            [self sendValue:@"wavein"];
            break;
        case TLMPoseTypeWaveOut:
            // Changes helloLabel's font to Snell Roundhand when the user is in a wave out pose.
            _p.text = @"Wave Out";
            [self sendValue:@"waveout"];
            break;
        case TLMPoseTypeFingersSpread:
            // Changes helloLabel's font to Chalkduster when the user is in a fingers spread pose.
            _p.text = @"Fingers Spread";
            [self sendValue:@"spread"];
            break;
    }
    // Unlock the Myo whenever we receive a pose
    if (pose.type == TLMPoseTypeUnknown || pose.type == TLMPoseTypeRest) {
        // Causes the Myo to lock after a short period.
        [pose.myo unlockWithType:TLMUnlockTypeTimed];
    } else {
        // Keeps the Myo unlocked until specified.
        // This is required to keep Myo unlocked while holding a pose, but if a pose is not being held, use
        // TLMUnlockTypeTimed to restart the timer.
        [pose.myo unlockWithType:TLMUnlockTypeHold];
        // Indicates that a user action has been performed.
        [pose.myo indicateUserAction];
    }
}

//bluetooth
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    if (central.state == CBCentralManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (NSMutableDictionary *)devices {
    if (_devices == nil) {
        _devices = [NSMutableDictionary dictionaryWithCapacity:6];
    }
    return _devices;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString * uuid = [[peripheral identifier] UUIDString];
    NSLog(@"%@ %@",uuid, [peripheral name]);
    if ([[peripheral name] isEqualToString:@"HMSoft"]) {
        [self.devices setObject:peripheral forKey:uuid];
    }
    [deviceList reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService * service in [peripheral services]) {
        [_selectedPeripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic * character in [service characteristics])
    {
        [_selectedPeripheral discoverDescriptorsForCharacteristic:character];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    const char * bytes =[(NSData*)[[characteristic UUID] data] bytes];
    if (bytes && strlen(bytes) == 2 && bytes[0] == (char)255 && bytes[1] == (char)225) {
         _selectedPeripheral = peripheral;
        for (CBService * service in [_selectedPeripheral services]) {
            for (CBCharacteristic * characteristic in [service characteristics])
            {
                [_selectedPeripheral setNotifyValue:true forCharacteristic:characteristic];
            }
        }
    }
}

- (void)sendValue:(NSString *) str {
    for (CBService * service in [_selectedPeripheral services]) {
        for (CBCharacteristic * characteristic in [service characteristics]) {
            [_selectedPeripheral writeValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

@end

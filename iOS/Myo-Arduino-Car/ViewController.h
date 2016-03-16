//
//  ViewController.h
//  Myo-Arduino-Car
//
//  Created by Jonathan Querubina on 4/3/15.
//  Copyright (c) 2015 Jonathan Querubina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreBluetooth/CoreBluetooth.h>

UITableView *deviceList;
UILabel *_p;
UILabel *_x;
UILabel *_y;
UILabel *_z;

@interface ViewController : UIViewController <CBPeripheralDelegate, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableDictionary *devices;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
@property (readonly, nonatomic) CFUUIDRef UUID;
@property (strong, nonatomic) CBCharacteristic *characteristics;
@property (strong, nonatomic) NSMutableData *data;

@end


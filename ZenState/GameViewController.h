//
//  GameViewController.h
//  ZenState
//
//  Created by LASERNA CONDADO, DANIEL on 18/1/17.
//  Copyright © 2017 LASERNA CONDADO, DANIEL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameplayKit/GameplayKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface GameViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

//CoreMotion
@property (nonatomic) CMMotionManager *motManager;
@property (nonatomic) NSTimer *motTimer;

//Bluetooth - Central Role
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData *data;

//Bluetooth - Peripheral Role
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong, nonatomic) NSData *dataToSend;
@property (nonatomic, readwrite) NSInteger sendDataIndex;
@property (nonatomic) SKLabelNode *textView;

@property (nonatomic) BOOL isReloading;
@property (nonatomic) int movement;
@property (nonatomic) int touchX;
@property (nonatomic) int touchY;

//Start button
@property (nonatomic) SKLabelNode *buttonInput;
@property (nonatomic) SKLabelNode *buttonOutput;
@property (nonatomic) BOOL isStarted;

#define TRANSFER_SERVICE_UUID           @"FB694B90-F49E-4597-8306-171BBA78F846"
#define TRANSFER_CHARACTERISTIC_UUID    @"EB6727C4-F184-497A-A656-76B0CDAC633A"
#define NOTIFY_MTU 20

//https://code.tutsplus.com/tutorials/ios-7-sdk-core-bluetooth-practical-lesson--mobile-20741

@end

//
//  GameViewController.m
//  ZenState
//
//  Created by LASERNA CONDADO, DANIEL on 18/1/17.
//  Copyright © 2017 LASERNA CONDADO, DANIEL. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"

@implementation GameViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Present the scene
  SKView *skView = (SKView *)self.view;
  GameScene *scene = [[GameScene alloc] initWithSize:CGSizeMake(skView.bounds.size.width, skView.bounds.size.height)];
  [skView presentScene:scene];
  
  skView.ignoresSiblingOrder = NO;
  skView.showsFPS = NO;
  skView.showsNodeCount = NO;
  
  scene.scaleMode = SKSceneScaleModeAspectFill;
  
  //CoreMotion
  [self InitCoreMotion];
  
  //Start button (label)
  _buttonOutput = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
  _buttonOutput.position = CGPointMake(CGRectGetMidX(scene.frame), CGRectGetMidY(scene.frame) + 100);
  _buttonOutput.text = @"OUTPUT";
  _buttonOutput.fontColor = [UIColor blackColor];
  [scene addChild:_buttonOutput];
  
  //Start button (label)
  _buttonInput = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
  _buttonInput.position = CGPointMake(CGRectGetMidX(scene.frame), CGRectGetMidY(scene.frame) - 100);
  _buttonInput.text = @"INPUT";
  _buttonInput.fontColor = [UIColor blackColor];
  [scene addChild:_buttonInput];
  
  _isStarted = NO;
  
  //Debug label
  _textView = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
  _textView.position = CGPointMake(CGRectGetMidX(scene.frame), CGRectGetMidY(scene.frame));
  _textView.text = @"";
  _textView.fontColor = [UIColor blackColor];
  [scene addChild:_textView];
  
  _isReloading = NO;
  _movement = 0;
  _touchX = 0;
  _touchY = 0;
  
  [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  if (UIEventSubtypeMotionShake) {
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"deviceShaking" object:self];
    _isReloading = YES;
  }
}

-(void) InitCoreMotion {
  _motManager = [[CMMotionManager alloc] init];
  _motManager.deviceMotionUpdateInterval = 1/60;
  [_motManager startDeviceMotionUpdates];
  _motTimer = [NSTimer scheduledTimerWithTimeInterval:(1/60) target:self selector:@selector(getGyroscope) userInfo:nil repeats:YES];
}

-(void) getGyroscope {
  int Pitch = 180 * _motManager.deviceMotion.attitude.pitch / M_PI;
  _movement = Pitch;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.view];
  location.y = self.view.bounds.size.height - location.y;
  _touchX = location.x;
  _touchY = location.y;
  
  if (_isStarted == NO) {
    //Button Input
    if([_buttonOutput containsPoint: location]) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"setAsOutput" object:self userInfo:nil];
      NSLog(@"OUTPUT");
      _textView.text = @"";
      _textView.zPosition = -999;
      _isStarted = YES;
      _buttonOutput.hidden = TRUE;
      _buttonInput.hidden = TRUE;
      //Bluetooth C (OUTPUT)
      id plop = self;
      _centralManager = [[CBCentralManager alloc] initWithDelegate:plop queue:nil];
      _data = [[NSMutableData alloc] init];
    } else if([_buttonInput containsPoint: location]) {
      NSLog(@"INPUT");
      [[NSNotificationCenter defaultCenter] postNotificationName:@"setAsInput" object:self userInfo:nil];
      _textView.text = @"INPUT";
      _isStarted = YES;
      _buttonOutput.hidden = TRUE;
      _buttonInput.hidden = TRUE;
      //Bluetooth P (INPUT)
      id plop = self;
      _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:plop queue:nil];
    }
  }
}

//Bluetooth C
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  // You should test all scenarios
  if (central.state != CBManagerStatePoweredOn) {
    return;
  }
  
  if (central.state == CBManagerStatePoweredOn) {
    NSLog(@"Central ON (OUTPUT)");
    // Scan for devices
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    //NSLog(@"Scanning started");
  }
}

//Bluetooth C
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  //NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
  
  if (_discoveredPeripheral != peripheral) {
    // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
    _discoveredPeripheral = peripheral;
    
    // And connect
    //NSLog(@"Connecting to peripheral %@", peripheral);
    //NSLog(@"Connecting...");
    [_centralManager connectPeripheral:peripheral options:nil];
  }
}

//Bluetooth C
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"Failed to connect");
  [self cleanup];
}

//Bluetooth C
- (void)cleanup {
  // See if we are subscribed to a characteristic on the peripheral
  if (_discoveredPeripheral.services != nil) {
    for (CBService *service in _discoveredPeripheral.services) {
      if (service.characteristics != nil) {
        for (CBCharacteristic *characteristic in service.characteristics) {
          if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            if (characteristic.isNotifying) {
              [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
              return;
            }
          }
        }
      }
    }
  }
  [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
}

//Bluetooth C
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  //NSLog(@"Connected");
  
  [_centralManager stopScan];
  //NSLog(@"Scanning stopped");
  
  [_data setLength:0];
  
  id plop = self;
  peripheral.delegate = plop;
  
  [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

//Bluetooth C
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  if (error) {
    [self cleanup];
    return;
  }
  
  for (CBService *service in peripheral.services) {
    [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
  }
  // Discover other characteristics
}

//Bluetooth C
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
  if (error) {
    [self cleanup];
    return;
  }
  
  for (CBCharacteristic *characteristic in service.characteristics) {
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
      [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
  }
  [_centralManager stopScan];
}

//Bluetooth C
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (error) {
    NSLog(@"Error");
    return;
  }
  
  NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
  
  // Have we got everything we need?
  if ([stringFromData isEqualToString:@"EOM"]) {
    if (_isStarted) {
      [_textView setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
      NSLog(@"%@", _textView.text);
      NSArray *listItems = [_textView.text componentsSeparatedByString:@":"];
      if (listItems.count == 6) {
        NSDictionary *data = @{
                               @"reload":[listItems[0] isEqualToString:@"YES"] ? @"1" : @"0",
                               @"movement":listItems[1],
                               @"posX":listItems[2],
                               @"posY":listItems[3],
                               @"sizeX":listItems[4],
                               @"sizeY":listItems[5],
                               };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sendInput" object:self userInfo:data];
      }
    }
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
    
    [_centralManager cancelPeripheralConnection:peripheral];
  }
  
  [_data appendData:characteristic.value];
}

//Bluetooth C
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
    return;
  }
  
  if (characteristic.isNotifying) {
    //NSLog(@"Notification began on %@", characteristic);
  } else {
    // Notification has stopped
    [_centralManager cancelPeripheralConnection:peripheral];
  }
}

//Bluetooth C
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  _discoveredPeripheral = nil;
  [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Bluetooth P
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  if (peripheral.state != CBManagerStatePoweredOn) {
    return;
  }
  
  if (peripheral.state == CBManagerStatePoweredOn) {
    NSLog(@"Peripheral ON (INPUT)");
    //_textView.text = [NSString stringWithFormat:@"%d", (int)peripheral.state];
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    transferService.characteristics = @[_transferCharacteristic];
    [_peripheralManager addService:transferService];
    [_peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
  }
}

//Bluetooth P
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  _textView.text = [NSString stringWithFormat:@"%@:%d:%d:%d:%d:%d", _isReloading ? @"YES" : @"NO", _movement, _touchX, _touchY, (int)self.view.bounds.size.width, (int)self.view.bounds.size.height];
  _dataToSend = [_textView.text dataUsingEncoding:NSUTF8StringEncoding];
  
  //NSLog(@"%@", _dataToSend);
  _isReloading = NO;
  _touchX = 0;
  _touchY = 0;
  _sendDataIndex = 0;
  [self sendData];
}

//Bluetooth P
- (void)sendData {
  static BOOL sendingEOM = NO;
  
  // end of message?
  if (sendingEOM) {
    BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
    
    if (didSend) {
      // It did, so mark it as sent
      sendingEOM = NO;
    }
    // didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
    return;
  }
  
  // We're sending data
  // Is there any left to send?
  if (self.sendDataIndex >= self.dataToSend.length) {
    // No data left.  Do nothing
    return;
  }
  
  // There's data left, so send until the callback fails, or we're done.
  BOOL didSend = YES;
  
  while (didSend) {
    // Work out how big it should be
    NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
    
    // Can't be longer than 20 bytes
    if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
    
    // Copy out the data we want
    NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
    
    didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
    
    // If it didn't work, drop out and wait for the callback
    if (!didSend) {
      return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    NSLog(@"Sent: %@", stringFromData);
    
    // It did send, so update our index
    self.sendDataIndex += amountToSend;
    
    // Was it the last one?
    if (self.sendDataIndex >= self.dataToSend.length) {
      
      // Set this so if the send fails, we'll send it next time
      sendingEOM = YES;
      
      BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
      
      if (eomSent) {
        // It sent, we're all done
        sendingEOM = NO;
        NSLog(@"Sent: EOM");
      }
      
      return;
    }
  }
}

//Bluetooth P
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
  [self sendData];
}

@end

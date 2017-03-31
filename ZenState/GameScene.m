//
//  GameScene.m
//  ZenState
//
//  Created by LASERNA CONDADO, DANIEL on 18/1/17.
//  Copyright © 2017 LASERNA CONDADO, DANIEL. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene

+ (GameScene *)newGameScene {
  // Load 'GameScene.sks' as an SKScene.
  GameScene *scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
  if (!scene) {
    NSLog(@"Failed to load GameScene.sks");
    abort();
  }
  
  // Set the scale mode to scale to fit the window
  scene.scaleMode = SKSceneScaleModeAspectFill;
  
  return scene;
}

- (void) setUpScene {
  srand((unsigned int)time(NULL));
  
  _isGameOver = false;
  
  //Background
  _background = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
  _background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
  _background.xScale = self.frame.size.width / _background.size.width;
  _background.yScale = self.frame.size.height / _background.size.height;
  _background.zPosition = -100;
  [self addChild:_background];
  
  //Player
  _playerMaxLife = 3;
  _playerLife = _playerMaxLife;
  _playerPoints = 0;
  _playerAcceleration = 8.0f / 768.0f * self.frame.size.width;
  _playerActualAcceleration = 0.0f;
  _player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
  _player.xScale = self.frame.size.width / _player.size.width / 8;
  _player.yScale = self.frame.size.height / _player.size.height / 5;
  _player.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame) + _player.size.height * 0.2f);
  [self addChild:_player];  _kills = [NSMutableArray array];
  
  _killsCols = 1;
  _killsRows = _killsCols * 4;
  _maxKills = _killsCols * _killsRows;
  
  //Life
  _life = [NSMutableArray array];
  for (int i = 0; i < _playerLife; i++) {
    SKSpriteNode *life = [SKSpriteNode spriteNodeWithImageNamed:@"hearth"];
    [self addChild:life];
    [_life addObject:life];
    life.xScale = self.frame.size.width / life.size.width / 8;
    life.yScale = self.frame.size.height / life.size.height / 5;
    life.position = CGPointMake(CGRectGetMaxX(self.frame) - ((i + 1) * life.size.width) + (life.size.width * 0.5f), CGRectGetMaxY(self.frame) - (life.size.height * 0.5f));
  }
  
  _labelPoints = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
  _labelPoints.position = CGPointMake(CGRectGetMaxX(self.frame) - 100, CGRectGetMaxY(self.frame) - _life[0].size.height - (self.frame.size.height * 0.1f));
  _labelPoints.text = [NSString stringWithFormat:@"Points: %d", _playerPoints];
  _labelPoints.fontColor = [UIColor blackColor];
  [self addChild:_labelPoints];
  
  //Bullet
  _bulletAmountMax = 4;
  _bulletVelocity = 22.22f;
  _bullet = [NSMutableArray array];
  _bulletUsed = [NSMutableArray array];
  for (int i = 0; i < _bulletAmountMax; i++) {
    SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
    bullet.position = _player.position;
    bullet.xScale = (self.frame.size.width / bullet.size.width / 8) * 0.5f;
    bullet.yScale = (self.frame.size.height / bullet.size.height / 5 * 0.5f);
    [self addChild:bullet];
    [_bullet addObject:bullet];
  }
  
  //Enemy
  _enemy = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"enemy%d", (int)(rand() % 2)]];
  _enemy.position = CGPointMake(CGRectGetMidX(self.frame) + (rand() % (int)CGRectGetMaxX(self.frame)), CGRectGetMidY(self.frame) + 300);
  _enemy.xScale = self.frame.size.width / _enemy.size.width / 8;
  _enemy.yScale = self.frame.size.height / _enemy.size.height / 5;
  [self addChild:_enemy];
  _direction = 1;
  _enemyVelocityX = 10.0f;
  _enemyVelocityY = -1.0f;
  _enemyActualVelocityX = _enemyVelocityX;
  _enemyActualVelocityY = _enemyVelocityY;
  
  //GameOverScene
  self.labelGameOver = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
  _labelGameOver.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 30);
  _labelGameOver.text = [NSString stringWithFormat:@"Game Over"];
  _labelGameOver.fontColor = [UIColor blackColor];
  _labelGameOver.hidden = true;
  [self addChild:_labelGameOver];
  
  _buttonStartAgain = [SKSpriteNode spriteNodeWithImageNamed:@"start"];
  _buttonStartAgain.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 60);
  _buttonStartAgain.xScale = 1.5f;
  _buttonStartAgain.yScale = 1.5f;
  _buttonStartAgain.hidden = true;
  [self addChild:_buttonStartAgain];
  
  [self setTypeOfDevice:YES];
  _isGameOver = YES;
  _isInput = NO;
  
  //Notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getInput:) name:@"sendInput" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAsInput:) name:@"setAsInput" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAsOutput:) name:@"setAsOutput" object:nil];
}

- (void)didMoveToView:(SKView *)view {
  [self setUpScene];
}

-(void)update:(CFTimeInterval)currentTime {
  if (!_isGameOver) {
    //Move the enemy
    _enemy.position = CGPointMake(_enemy.position.x + (_enemyActualVelocityX * _direction), _enemy.position.y + _enemyActualVelocityY);
    if ((_enemy.position.x <= CGRectGetMinX(self.frame)) && _direction < 0) _direction = -_direction;
    if ((_enemy.position.x >= CGRectGetMaxX(self.frame)) && _direction > 0) _direction = -_direction;
    
    //Check bullets collision
    bool bulletHitEnemy = false;
    for (int i = 0; i < _bulletUsed.count && !bulletHitEnemy; i++) {
      _bulletUsed[i].position = CGPointMake(_bulletUsed[i].position.x, _bulletUsed[i].position.y + _bulletVelocity);
      
      if ([_bulletUsed[i] intersectsNode:_enemy]) {
        bulletHitEnemy = true;
        NSString *tempstr = _enemy.texture.description;
        //NSLog(@"%d", [tempstr rangeOfString:@"enemy0"].location);
        if(((int)[tempstr rangeOfString:@"enemy0"].location) != -1) {
          _playerPoints += 5;
        } else {
          _playerPoints += 3;
        }
        _labelPoints.text = [NSString stringWithFormat:@"Points: %d", _playerPoints];
        
        while (_bulletUsed.count > 0) {
          [_bulletUsed[0] removeFromParent];
          [_bulletUsed removeObject:_bulletUsed[0]];
        }
        
        SKSpriteNode *kill = [SKSpriteNode spriteNodeWithTexture:[_enemy texture]];
        [_enemy removeFromParent];
        _enemy = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"enemy%d", (int)(rand() % 2)]];
        _enemy.position = CGPointMake(CGRectGetMidX(self.frame) + (rand() % (int)CGRectGetMaxX(self.frame)), CGRectGetMidY(self.frame) + 300);
        _enemy.xScale = self.frame.size.width / _enemy.size.width / 8;
        _enemy.yScale = self.frame.size.height / _enemy.size.height / 5;
        [self addChild:_enemy];
        _enemyActualVelocityX += 0.1f / 1024 * self.frame.size.width;
        _enemyActualVelocityY -= 0.025f / 768 * self.frame.size.height;
        
        //Update the kill section of the screen
        if (_kills.count > _maxKills) {
          _killsCols++;
          _killsRows = _killsCols * 4;
          _maxKills = _killsCols * _killsRows;
        }
        [self addChild:kill];
        [_kills addObject:kill];
        int iCol = 0;
        int iRow = 0;
        int posX = 0;
        int posY = 0;
        int minX = self.frame.origin.x;
        int maxY = self.frame.origin.y + self.frame.size.height;
        float xScale = (self.frame.size.width / kill.size.width / 8.0f) *  ((4.0f / _killsCols) * 0.2f);
        float yScale = (self.frame.size.height / kill.size.height / 5.0f) * ((4.0f / _killsCols) * 0.2f);
        for (int i = 0; i < _kills.count; i++) {
          _kills[i].xScale = xScale;
          _kills[i].yScale = yScale;
          
          iCol = iCol + (i % 4 == 0);
          iRow = i % 4;
          
          posX = minX + (iCol * _kills[i].size.width);
          posY = maxY - (iRow * _kills[i].size.height) - (_kills[i].size.height * 0.8f);
          _kills[i].position = CGPointMake(posX, posY);
        }
      }
    }
    
    //Check enemy position
    if (_enemy.position.y < CGRectGetMinY(self.frame) || [_enemy intersectsNode:_player]) {
      _playerLife--;
      [_life[_life.count - 1] removeFromParent];
      [_life removeLastObject];
      NSLog(@"Enemy Hit with player");
      
      //Reset the enemy
      [_enemy removeFromParent];
      _enemy = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"enemy%d", (int)(rand() % 2)]];
      _enemy.position = CGPointMake(CGRectGetMidX(self.frame) + (rand() % (int)CGRectGetMaxX(self.frame)), self.frame.size.height * 1.2f);
      _enemy.xScale = self.frame.size.width / _enemy.size.width / 8;
      _enemy.yScale = self.frame.size.height / _enemy.size.height / 5;
      [self addChild:_enemy];
      _enemyActualVelocityX = _enemyVelocityX;
      _enemyActualVelocityY = _enemyVelocityY;
      
      if (_playerLife <= 0) {
        NSLog(@"Game Over");
        _enemyActualVelocityX = 0.0f;
        _enemyActualVelocityY = 0.0f;
        _buttonStartAgain.hidden = false;
        _labelGameOver.hidden = false;
        _isGameOver = true;
      }
    }
    
    //Move available bullets to the player position
    for (int i = 0; i < _bullet.count; i++) {
      _bullet[i].position = _player.position;
    }
  }
  
  [self movePlayer];
  _playerActualAcceleration *= 0.999f;
}

- (void) setTypeOfDevice:(BOOL)input {
  _player.hidden = input;
  _labelPoints.hidden = input;
  for (int i = 0; i < _bullet.count; i++) _bullet[i].hidden = input;
  for (int i = 0; i < _bulletUsed.count; i++) _bulletUsed[i].hidden = input;
  for (int i = 0; i < _life.count; i++) _life[i].hidden = input;
  _enemy.hidden = input;
}

- (void)touch:(int)x :(int)y {
  if (_isGameOver == NO) {
    if (_bullet.count > 0) {
      NSLog(@"Shot");
      _bullet[_bullet.count - 1].position = _player.position;
      [_bulletUsed addObject:_bullet[_bullet.count - 1]];
      [_bullet removeLastObject];
    }
  } else {
    //Start Again
    CGPoint location = CGPointMake(x, y);
    if([_buttonStartAgain containsPoint: location]) {
      //if(x != 0 && y != 0) { //Restart by just touching the screen (FASTER for the player)
      NSLog(@"Restarting Game");
      
      while (_kills.count > 0) {
        _kills[0].position = CGPointMake(-999, -999);
        [_kills[0] removeFromParent];
        [_kills removeObject:_kills[0]];
      }
      
      //Reset the player bullets
      for (int i = 0; i < _bulletAmountMax; i++) {
        SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
        bullet.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 200);
        bullet.xScale = (self.frame.size.width / bullet.size.width / 8) * 0.5f;
        bullet.yScale = (self.frame.size.height / bullet.size.height / 5) * 0.5f;
        [self addChild:bullet];
        [_bullet addObject:bullet];
      }
      
      //Remove the used bullets
      for (int j = (int)_bulletUsed.count - 1; j >= 0; j--) {
        if (_bulletUsed[j].position.y > CGRectGetMaxY(self.frame)) {
          [_bulletUsed removeObject:_bulletUsed[j]];
        }
      }
      
      _enemyActualVelocityX = _enemyVelocityX;
      _enemyActualVelocityY = _enemyVelocityY;
      _buttonStartAgain.hidden = true;
      _labelGameOver.hidden = true;
      _playerLife = _playerMaxLife;
      _isGameOver = false;
      _playerPoints = 0;
      
      //Life
      for (int i = 0; i < _playerLife; i++) {
        SKSpriteNode *life = [SKSpriteNode spriteNodeWithImageNamed:@"hearth"];
        [self addChild:life];
        [_life addObject:life];
        life.xScale = self.frame.size.width / life.size.width / 8;
        life.yScale = self.frame.size.height / life.size.height / 5;
        life.position = CGPointMake(CGRectGetMaxX(self.frame) - ((i + 1) * life.size.width) + (life.size.width * 0.5f), CGRectGetMaxY(self.frame) - (life.size.height * 0.5f));
      }
    }
  }
}

- (void) setAsInput:(NSNotification *) notificationParam {
  _isGameOver = YES;
  _isInput = YES;
  [self setTypeOfDevice:TRUE];
}

- (void) setAsOutput:(NSNotification *) notificationParam {
  _isGameOver = NO;
  _isInput = NO;
  [self setTypeOfDevice:FALSE];
}

- (void) getInput:(NSNotification *) notificationParam {
  NSDictionary *data = notificationParam.userInfo;
  bool reload = [[data valueForKey:@"reload"] integerValue] == 1 ? true : false;
  int movement = (int)[[data valueForKey:@"movement"] integerValue];
  int posX = (int)[[data valueForKey:@"posX"] integerValue];
  int posY = (int)[[data valueForKey:@"posY"] integerValue];
  int sizeX = (int)[[data valueForKey:@"sizeX"] integerValue];
  int sizeY = (int)[[data valueForKey:@"sizeY"] integerValue];
  
  if (reload == true) {
    [self reloadGun];
  }
  
  if (movement != 0) {
    _playerActualAcceleration = movement < 0 ? -_playerAcceleration : _playerAcceleration;
  } else {
    _playerActualAcceleration = 0.0f;
  }
  
  int realX = (((float)posX) / ((float)sizeX)) * self.view.bounds.size.width;
  int realY = (((float)posY) / ((float)sizeY)) * self.view.bounds.size.height;
  if (realX != 0 && realY != 0) {
    //NSLog(@"Touch");
    [self touch:realX :realY];
  }
}

- (void) reloadGun {
  if (!_isGameOver) {
    NSLog(@"Reloading");
    for (int i = 0; i < _bulletAmountMax && _bullet.count < _bulletAmountMax; i++) {
      SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
      bullet.position = _player.position;
      bullet.xScale = (self.frame.size.width / bullet.size.width / 8) * 0.5f;
      bullet.yScale = (self.frame.size.height / bullet.size.height / 5) * 0.5f;
      [self addChild:bullet];
      [_bullet addObject:bullet];
    }
    
    //Remove the bullets used that are out of the screen
    for (int j = (int)_bulletUsed.count - 1; j >= 0; j--) {
      if (_bulletUsed[j].position.y > CGRectGetMaxY(self.frame)) {
        [_bulletUsed removeObject:_bulletUsed[j]];
      }
    }
  }
}

- (void) movePlayer {
  if (!_isGameOver) {
    _player.position = CGPointMake(_player.position.x + _playerActualAcceleration, _player.position.y);
    if (_player.position.x < CGRectGetMinX(self.frame)) {
      _player.position = CGPointMake(CGRectGetMinX(self.frame), _player.position.y);
    } else if (_player.position.x > CGRectGetMaxX(self.frame)) {
      _player.position = CGPointMake(CGRectGetMaxX(self.frame), _player.position.y);
    }
  }
}

@end

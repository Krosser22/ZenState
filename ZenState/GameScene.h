//
//  GameScene.h
//  ZenState
//
//  Created by LASERNA CONDADO, DANIEL on 18/1/17.
//  Copyright © 2017 LASERNA CONDADO, DANIEL. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene

+ (GameScene *)newGameScene;

- (void) setTypeOfDevice:(BOOL)input;

@property (nonatomic) BOOL isInput;
@property (nonatomic) BOOL isGameOver;

//Background http://opengameart.org/content/bevouliin-the-mist-free-game-background
@property (nonatomic) SKSpriteNode *background;

//Player
@property (nonatomic) int playerMaxLife;
@property (nonatomic) int playerLife;
@property (nonatomic) int playerPoints;
@property (nonatomic) float playerAcceleration;
@property (nonatomic) float playerActualAcceleration;
@property (nonatomic) SKSpriteNode *player;
@property (nonatomic) SKLabelNode *labelPoints;
@property (nonatomic) NSMutableArray<SKSpriteNode *> *kills;

@property (nonatomic) int killsRows;
@property (nonatomic) int killsCols;
@property (nonatomic) int maxKills;

//Life http://www.flaticon.com/free-icons/heart_682
@property (nonatomic) NSMutableArray<SKSpriteNode *> *life;

//Bullet http://ark.gamepedia.com/Simple_Bullet
@property (nonatomic) int bulletAmountMax;
@property (nonatomic) float bulletVelocity;
@property (nonatomic) NSMutableArray<SKSpriteNode *> *bullet;
@property (nonatomic) NSMutableArray<SKSpriteNode *> *bulletUsed;

//Enemy http://opengameart.org/content/ufo-enemy-game-character
@property (nonatomic) SKSpriteNode *enemy;
@property (nonatomic) int direction;
@property (nonatomic) float enemyVelocityX;
@property (nonatomic) float enemyVelocityY;
@property (nonatomic) float enemyActualVelocityX;
@property (nonatomic) float enemyActualVelocityY;

//GameOverLabel
@property (nonatomic) SKLabelNode *labelGameOver;

//PlayAgain http://www.iconarchive.com/show/vista-multimedia-icons-by-icons-land/Play-1-Hot-icon.html
@property (nonatomic) SKSpriteNode *buttonStartAgain;

@end

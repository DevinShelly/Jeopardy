//
//  JeopardyGame.h
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 1/29/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JeopardyPlayer;

@interface JeopardyGame : NSObject

+ (JeopardyGame*)gameWithPlayers:(NSArray*)players gameID:(NSUInteger)gameID andDate:(NSString*)date;

@property (readonly) JeopardyGame *optimalTieGame;
@property (readonly) JeopardyGame *optimalWinGame;

@property (readonly) NSArray *players;

@property (readonly) NSArray *winners;
@property (readonly) NSArray *runnersUp;
@property (readonly) JeopardyPlayer *thirdPlacePlayer;

@property (readonly) NSArray *firstPlacePlayersAfterDoubleJeopardy;
@property (readonly) NSArray *secondPlacePlayersAfterDoubleJeopardy;
@property (readonly) JeopardyPlayer *thirdPlacePlayerAfterDoubleJeopardy;

@property (readonly) NSUInteger gameID;
@property (readonly) NSString *date;

@property (readonly) BOOL isLockGame;
@property (readonly) BOOL isTieGame;
@property (readonly) BOOL isNonTieOrLockGame;
@property (readonly) BOOL isLockTieGame;

@property (readonly) BOOL firstPlaceWon;

@property (readonly) BOOL secondPlaceWon;

@property (readonly) BOOL thirdPlaceCanWinTripleStumper;
@property (readonly) BOOL thirdPlaceCanWinDoubleStumper;
@property (readonly) BOOL thirdPlaceMustAnswerCorrectlyToWin;
@property (readonly) BOOL thirdPlaceWon;

@property (readonly) NSDictionary *dictionaryRepresentation;

@property BOOL thirdPlaceShouldCooperate;

- (NSUInteger)optimalTieWagerForPlayer:(JeopardyPlayer*)player;
- (NSUInteger)optimalWinWagerForPlayer:(JeopardyPlayer*)player;

- (BOOL)containsPlayer:(NSUInteger)playerID;

- (BOOL)playerDidBetOptimallyForTie:(JeopardyPlayer*)player;
- (BOOL)playerDidBetOptimallyForWin:(JeopardyPlayer*)player;

- (NSUInteger)finalPositionOfPlayer:(JeopardyPlayer*)player;
- (NSUInteger)winningsForPlayer:(JeopardyPlayer*)player;

@end

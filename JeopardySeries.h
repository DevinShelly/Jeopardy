//
//  JeopardySeries.h
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 2/1/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JeopardySeries : NSObject

@property (readonly) NSArray *games;
@property (readonly) NSUInteger moneyWon;
@property (readonly) NSUInteger totalPlayers;
@property (readonly) CGFloat perPlayerWinnings;
@property (readonly) NSUInteger numberOfGameWhichEndedInATie;

@property (readonly) JeopardySeries *seriesWithOptimalWinWagering;
@property (readonly) JeopardySeries *seriesWithOptimalTieWagering;

@property (readonly) JeopardySeries *seriesConsistingOfLockGames;
@property (readonly) JeopardySeries *seriesConsistingOfTieGames;
@property (readonly) JeopardySeries *seriesConsistingOfLockTieGames;
@property (readonly) JeopardySeries *seriesConsistingOfNonLockOrTieGames;
@property (readonly) JeopardySeries *seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin;
@property (readonly) JeopardySeries *seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie;
@property (readonly) JeopardySeries *seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss;

@property (readonly) CGFloat firstPlaceAnswerPercentage;
@property (readonly) CGFloat secondPlaceAnswerPercentage;
@property (readonly) CGFloat thirdPlaceAnswerPercentage;
@property (readonly) CGFloat firstPlaceWinPercentage;
@property (readonly) CGFloat secondPlaceWinPercentage;
@property (readonly) CGFloat thirdPlaceWinPercentage;

@property (readonly) NSArray *arrayRepresentation;

+ (JeopardySeries*)seriesFromJSONFile:(NSString*)jsonFilepath;
+ (JeopardySeries*)seriesWithGames:(NSArray*)games;
- (void)writeJSONToFile:(NSString*)filePath;

@end

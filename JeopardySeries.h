//
//  JeopardySeries.h
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 2/1/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JeopardySeries : NSObject

@property (readonly) NSOrderedSet *games;
@property (readonly) NSUInteger winnings;
@property (readonly) NSUInteger firstPlaceWinnings;
@property (readonly) NSUInteger secondPlaceWinnings;
@property (readonly) NSUInteger thirdPlaceWinnings;
@property (readonly) NSUInteger totalPlayers;
@property (readonly) CGFloat perPlayerWinnings;
@property (readonly) NSUInteger numberOfGameWhichEndedInATie;

@property (readonly) JeopardySeries *optimalWinSeries;
@property (readonly) JeopardySeries *optimalTieSeries;

@property (readonly) JeopardySeries *lockSeries;
@property (readonly) JeopardySeries *tieSeries;
@property (readonly) JeopardySeries *lockTieSeries;
@property (readonly) JeopardySeries *nonLockOrTieSeries;

@property (readonly) JeopardySeries *firstPlacePlayedForTheWinSeries;
@property (readonly) JeopardySeries *firstPlacePlayedForTheTieSeries;
@property (readonly) JeopardySeries *firstPlacePlayedForTheLossSeries;

@property (readonly) JeopardySeries *firstPlaceWonSeries;
@property (readonly) JeopardySeries *secondPlaceWonSeries;
@property (readonly) JeopardySeries *thirdPlaceWonSeries;

@property (readonly) JeopardySeries *firstPlaceLostSeries;
@property (readonly) JeopardySeries *secondPlaceLostSeries;
@property (readonly) JeopardySeries *thirdPlaceLostSeries;

@property (readonly) JeopardySeries *firstPlaceCorrectSeries;
@property (readonly) JeopardySeries *secondPlaceCorrectSeries;
@property (readonly) JeopardySeries *thirdPlaceCorrectSeries;

@property (readonly) JeopardySeries *firstPlaceIncorrectSeries;
@property (readonly) JeopardySeries *secondPlaceIncorrectSeries;
@property (readonly) JeopardySeries *thirdPlaceIncorrectSeries;

@property (readonly) JeopardySeries *thirdPlacePlayedFinalJeopardySeries;
@property (readonly) JeopardySeries *thirdPlaceExistedSeries;

@property (readonly) JeopardySeries *randomizedSeries;
@property (readonly) JeopardySeries *continuousSeries;

@property (readonly) CGFloat firstPlaceAnswerPercentage;
@property (readonly) CGFloat secondPlaceAnswerPercentage;
@property (readonly) CGFloat thirdPlaceAnswerPercentage;
@property (readonly) CGFloat firstPlaceWinPercentage;
@property (readonly) CGFloat secondPlaceWinPercentage;
@property (readonly) CGFloat thirdPlaceWinPercentage;

@property (nonatomic) BOOL thirdPlaceShouldCooperate;

@property (readonly) NSDictionary *playerWinnings;

+ (JeopardySeries*)seriesFromJSONFile:(NSString*)jsonFilepath;
+ (JeopardySeries*)seriesWithGames:(NSOrderedSet*)games;
- (void)writeJSONToFile:(NSString*)filePath;

- (JeopardySeries*)filteredSeriesUsingPredicate:(NSPredicate*)predicate;

- (JeopardySeries*)seriesByUnioningSeries:(JeopardySeries*)series;
- (JeopardySeries*)seriesByMinusingSeries:(JeopardySeries*)series;
- (JeopardySeries*)seriesByIntersectingSeries:(JeopardySeries*)series;

- (JeopardySeries*)playerSeries:(NSUInteger)playerid;

@end

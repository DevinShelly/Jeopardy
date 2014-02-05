//
//  JeopardySeries.m
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 2/1/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import "JeopardySeries.h"
#import "JeopardyPlayer.h"
#import "JeopardyGame.h"

@interface JeopardySeries ()

@property (readwrite) NSOrderedSet *games;

@end

@implementation JeopardySeries

@synthesize lockSeries = _lockSeries;
@synthesize lockTieSeries = _lockTieSeries;
@synthesize nonLockOrTieSeries = _nonLockOrTieSeries;
@synthesize tieSeries = _tieSeries;

@synthesize multipleWinnerSeries = _multipleWinnerSeries;

@synthesize optimalTieSeries = _optimalTieSeries;
@synthesize optimalWinSeries = _optimalWinSeries;

@synthesize firstPlacePlayedForTheWinSeries = _firstPlacePlayedForTheWinSeries;
@synthesize firstPlacePlayedForTheTieSeries = _firstPlacePlayedForTheTieSeries;
@synthesize firstPlacePlayedForTheLossSeries = _firstPlacePlayedForTheLossSeries;

@synthesize firstPlaceWonSeries = _firstPlaceWonSeries;
@synthesize secondPlaceWonSeries = _secondPlaceWonSeries;
@synthesize thirdPlaceWonSeries = _thirdPlaceWonSeries;

@synthesize firstPlaceLostSeries = _firstPlaceLostSeries;
@synthesize secondPlaceLostSeries = _secondPlaceLostSeries;
@synthesize thirdPlaceLostSeries = _thirdPlaceLostSeries;

@synthesize firstPlaceCorrectSeries = _firstPlaceCorrectSeries;
@synthesize secondPlaceCorrectSeries = _secondPlaceCorrectSeries;
@synthesize thirdPlaceCorrectSeries = _thirdPlaceCorrectSeries;

@synthesize firstPlaceIncorrectSeries = _firstPlaceIncorrectSeries;
@synthesize secondPlaceIncorrectSeries = _secondPlaceIncorrectSeries;
@synthesize thirdPlaceIncorrectSeries = _thirdPlaceIncorrectSeries;

@synthesize thirdPlacePlayedFinalJeopardySeries = _thirdPlacePlayedFinalJeopardySeries;
@synthesize thirdPlaceExistedSeries = _thirdPlaceExistedSeries;

@synthesize playerWinnings = _playerWinnings;

+ (JeopardySeries*)seriesFromJSONFile:(NSString*)jsonFilepath
{
    NSData *gamesData = [NSData dataWithContentsOfFile:jsonFilepath];
    NSArray *gamesJSON = [NSJSONSerialization JSONObjectWithData:gamesData options:NSJSONReadingAllowFragments error:nil];
    NSMutableOrderedSet *games = [NSMutableOrderedSet orderedSetWithCapacity:gamesJSON.count];
    for (NSDictionary *gameJSON in gamesJSON)
    {
        NSMutableArray *players = [NSMutableArray array];
        for (NSDictionary *playerJSON in [gameJSON objectForKey:@"players"])
        {
            NSNumber *DJscore = [playerJSON objectForKey:@"DJscore"];
            NSNumber *FJscore = [playerJSON objectForKey:@"FJscore"];
            NSNumber *answeredCorrectly = [playerJSON objectForKey:@"answeredCorrectly"];
            NSNumber *playerid = [playerJSON objectForKey:@"playerid"];
            NSString *name = [playerJSON objectForKey:@"name"];
            JeopardyPlayer *player = [JeopardyPlayer jeopardyPlayerWithID:playerid.unsignedIntegerValue name:name scoreAfterDoubleJeopardy:DJscore.integerValue scoreAfterFinalJeopardy:FJscore.integerValue andAnsweredFinalJeopardyCorrectly:answeredCorrectly.boolValue];
            [players addObject:player];
        }
        NSString *date = [gameJSON objectForKey:@"date"];
        NSNumber *gameid = [gameJSON objectForKey:@"gameid"];
        JeopardyGame *game = [JeopardyGame gameWithPlayers:players gameID:gameid.unsignedIntegerValue andDate:date];
        [games addObject:game];
    }
    
    return [self seriesWithGames:games];
}

+ (JeopardySeries*)seriesWithGames:(NSOrderedSet*)games
{
    JeopardySeries *series = [[JeopardySeries alloc] init];
    series.games = games;
    return series;
}

- (void)writeJSONToFile:(NSString *)filePath
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self.games.array options:NSJSONWritingPrettyPrinted error:nil];
    [JSONData writeToFile:filePath atomically:NO];
}

#pragma mark - Setters

- (void)setThirdPlaceShouldCooperate:(BOOL)thirdPlaceShouldCooperate
{
    if (_thirdPlaceShouldCooperate != thirdPlaceShouldCooperate)
    {
        _optimalTieSeries = nil;
    }
    _thirdPlaceShouldCooperate = thirdPlaceShouldCooperate;
}

#pragma mark - Getters

- (NSString*)description
{
    return self.games.description;
}

#pragma mark Optimal Wagering
- (JeopardySeries*)optimalWinSeries
{
    if (_optimalWinSeries)
    {
        return _optimalWinSeries;
    }
    
    NSMutableOrderedSet *optimalGames = [NSMutableOrderedSet orderedSetWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        JeopardyGame *optimalGame = game.optimalWinGame;
        [optimalGames addObject:optimalGame];
    }
    
    _optimalWinSeries = [JeopardySeries seriesWithGames:optimalGames];
    _optimalWinSeries = _optimalWinSeries.randomizedSeries.continuousSeries;
    return _optimalWinSeries;
}
- (JeopardySeries*)optimalTieSeries
{
    if (_optimalTieSeries)
    {
        return _optimalTieSeries;
    }
    
    NSMutableOrderedSet *optimalGames = [NSMutableOrderedSet orderedSetWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        game.thirdPlaceShouldCooperate = self.thirdPlaceShouldCooperate;
        JeopardyGame *optimalGame = game.optimalTieGame;
        [optimalGames addObject:optimalGame];
    }
    
    _optimalTieSeries = [JeopardySeries seriesWithGames:optimalGames];
    _optimalTieSeries = _optimalTieSeries.randomizedSeries.continuousSeries;
    return _optimalTieSeries;
}

#pragma mark Series Filtering

- (JeopardySeries*)filteredSeriesUsingPredicate:(NSPredicate*)predicate
{
    return [JeopardySeries seriesWithGames:[self.games filteredOrderedSetUsingPredicate:predicate]];
}

#pragma mark Filterd By Game Type
#pragma mark Double Jeopardy
- (JeopardySeries*) lockSeries
{
    if (_lockSeries)
    {
        return _lockSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isLockGame];
    }];
    _lockSeries = [self filteredSeriesUsingPredicate:predicate];
    return _lockSeries;
}
- (JeopardySeries*) tieSeries
{
    if (_tieSeries)
    {
        return _tieSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isTieGame];
    }];
    _tieSeries = [self filteredSeriesUsingPredicate:predicate];
    return _tieSeries;
}
- (JeopardySeries*) lockTieSeries
{
    if (_lockTieSeries)
    {
        return _lockTieSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isLockTieGame];
    }];
    _lockTieSeries = [self filteredSeriesUsingPredicate:predicate];
    return _lockTieSeries;
}
- (JeopardySeries*) nonLockOrTieSeries
{
    if (_nonLockOrTieSeries)
    {
        return _nonLockOrTieSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ![evaluatedObject isLockTieGame] && ![evaluatedObject isTieGame] && ![evaluatedObject isLockGame];
    }];
    _nonLockOrTieSeries = [self filteredSeriesUsingPredicate:predicate];
    return _nonLockOrTieSeries;
}

#pragma mark Final Jeopardy

- (JeopardySeries*) multipleWinnerSeries
{
    if (_multipleWinnerSeries)
    {
        return _multipleWinnerSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return game.winners.count > 1;
    }];
    _multipleWinnerSeries = [self filteredSeriesUsingPredicate:predicate];
    return _multipleWinnerSeries;
}

#pragma mark Filtered By First Place Strategy

- (JeopardySeries*)firstPlacePlayedForTheTieSeries
{
    if (_firstPlacePlayedForTheTieSeries)
    {
        return _firstPlacePlayedForTheTieSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *player in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            if (player.wager == [game optimalTieWagerForPlayer:player])
            {
                return YES;
            }
        }
        return NO;
    }];
    
    _firstPlacePlayedForTheTieSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlacePlayedForTheTieSeries;
}

- (JeopardySeries*)firstPlacePlayedForTheWinSeries
{
    if (_firstPlacePlayedForTheWinSeries)
    {
        return _firstPlacePlayedForTheWinSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        JeopardyPlayer *second = game.secondPlacePlayersAfterDoubleJeopardy.lastObject;
        for (JeopardyPlayer *leader in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            NSInteger secondDoubleUp = second.scoreAfterDoubleJeopardy * 2;
            NSInteger firstAfterCorrect = leader.scoreAfterDoubleJeopardy + leader.wager;
            NSInteger firstAfterIncorrect = leader.scoreAfterDoubleJeopardy - leader.wager;
            if (game.isLockGame && firstAfterCorrect > secondDoubleUp)
            {
                return YES;
            }
            else if (game.isNonTieOrLockGame && firstAfterIncorrect > secondDoubleUp)
            {
                return YES;
            }
        }
        return NO;
    }];
    
    _firstPlacePlayedForTheWinSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlacePlayedForTheWinSeries;
}

- (JeopardySeries*)firstPlacePlayedForTheLossSeries
{
    if (_firstPlacePlayedForTheLossSeries)
    {
        return _firstPlacePlayedForTheLossSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        JeopardyPlayer *second = game.secondPlacePlayersAfterDoubleJeopardy.lastObject;
        NSInteger secondDoubleUp = second.scoreAfterDoubleJeopardy * 2;
        
        for (JeopardyPlayer *leader in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            NSInteger leaderAfterMake = leader.scoreAfterDoubleJeopardy + leader.wager;
            NSInteger leaderAfterMiss = leader.scoreAfterDoubleJeopardy - leader.wager;
            
            if (game.isLockTieGame && leader.wager > 0)
            {
                return YES;
            }
            else if (game.isTieGame && leader.wager != leader.scoreAfterDoubleJeopardy)
            {
                return YES;
            }
            else if (game.isLockGame && leaderAfterMiss < secondDoubleUp)
            {
                return YES;
            }
            else if (game.isNonTieOrLockGame && leaderAfterMake < secondDoubleUp)
            {
                return YES;
            }
        }
        
        return NO;
    }];
    
    _firstPlacePlayedForTheLossSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlacePlayedForTheLossSeries;
}

#pragma mark Filtered By Winners and Losers

- (JeopardySeries*)firstPlaceWonSeries
{
    if (_firstPlaceWonSeries)
    {
        return _firstPlaceWonSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *first in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            if ([game.winners containsObject:first])
            {
                return YES;
            }
        }
        return NO;
    }];
    _firstPlaceWonSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlaceWonSeries;
}

- (JeopardySeries*)firstPlaceLostSeries
{
    if (_firstPlaceLostSeries)
    {
        return _firstPlaceLostSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *first in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            if (![game.winners containsObject:first])
            {
                return YES;
            }
        }
        return NO;
    }];
    _firstPlaceLostSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlaceLostSeries;
}

- (JeopardySeries*)secondPlaceWonSeries
{
    if (_secondPlaceWonSeries)
    {
        return _secondPlaceWonSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *second in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            if ([game.winners containsObject:second])
            {
                return YES;
            }
        }
        return NO;
    }];
    _secondPlaceWonSeries = [self filteredSeriesUsingPredicate:predicate];
    return _secondPlaceWonSeries;
}

- (JeopardySeries*)secondPlaceLostSeries
{
    if (_secondPlaceLostSeries)
    {
        return _secondPlaceLostSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *second in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            if (![game.winners containsObject:second])
            {
                return YES;
            }
        }
        return NO;
    }];
    _secondPlaceLostSeries = [self filteredSeriesUsingPredicate:predicate];
    return _secondPlaceLostSeries;
}

- (JeopardySeries*) thirdPlaceWonSeries
{
    if (_thirdPlaceWonSeries)
    {
        return _thirdPlaceWonSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        if ([game.winners containsObject:game.thirdPlacePlayerAfterDoubleJeopardy])
        {
            return YES;
        }
        return NO;
    }];
    _thirdPlaceWonSeries = [self filteredSeriesUsingPredicate:predicate];
    return _thirdPlaceWonSeries;
}

- (JeopardySeries*)thirdPlaceLostSeries
{
    if (_thirdPlaceLostSeries)
    {
        return _thirdPlaceLostSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return ![game.winners containsObject:game.thirdPlacePlayerAfterDoubleJeopardy];
    }];
    
    _thirdPlaceLostSeries = [self filteredSeriesUsingPredicate:predicate];
    return _thirdPlaceLostSeries;
}

#pragma mark Filtered by FJ Response

- (JeopardySeries*)firstPlaceCorrectSeries
{
    if (_firstPlaceCorrectSeries)
    {
        return _firstPlaceCorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *first in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            if (first.answeredFinalJeopardyCorrectly)
            {
                return YES;
            }
        }
        
        return NO;
    }];
    
    _firstPlaceCorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlaceCorrectSeries;
}

- (JeopardySeries*)firstPlaceIncorrectSeries
{
    if (_firstPlaceIncorrectSeries)
    {
        return _firstPlaceIncorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *first in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            if (!first.answeredFinalJeopardyCorrectly)
            {
                return YES;
            }
        }
        
        return NO;
    }];
    
    _firstPlaceIncorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _firstPlaceIncorrectSeries;
}

- (JeopardySeries*)secondPlaceCorrectSeries
{
    if (_secondPlaceCorrectSeries)
    {
        return _secondPlaceCorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *second in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            if (second.answeredFinalJeopardyCorrectly)
            {
                return YES;
            }
        }
        
        return NO;
    }];
    
    _secondPlaceCorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _secondPlaceCorrectSeries;
}

- (JeopardySeries*)secondPlaceIncorrectSeries
{
    if (_secondPlaceIncorrectSeries)
    {
        return _secondPlaceIncorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *second in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            if (!second.answeredFinalJeopardyCorrectly)
            {
                return YES;
            }
        }
        
        return NO;
    }];
    
    _secondPlaceIncorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _secondPlaceIncorrectSeries;
}

- (JeopardySeries*)thirdPlaceCorrectSeries
{
    if (_thirdPlaceCorrectSeries)
    {
        return _thirdPlaceCorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return game.thirdPlacePlayerAfterDoubleJeopardy.answeredFinalJeopardyCorrectly;
    }];
    
    _thirdPlaceCorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _thirdPlaceCorrectSeries;
}

- (JeopardySeries*)thirdPlaceIncorrectSeries
{
    if (_thirdPlaceIncorrectSeries)
    {
        return _thirdPlaceIncorrectSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return !game.thirdPlacePlayerAfterDoubleJeopardy.answeredFinalJeopardyCorrectly;
    }];
    
    _thirdPlaceIncorrectSeries = [self filteredSeriesUsingPredicate:predicate];
    return _thirdPlaceIncorrectSeries;
}

- (JeopardySeries*) thirdPlacePlayedFinalJeopardySeries
{
    if (_thirdPlacePlayedFinalJeopardySeries)
    {
        return _thirdPlacePlayedFinalJeopardySeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return game.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy > 0;
    }];
    return [self filteredSeriesUsingPredicate:predicate];
}
- (JeopardySeries*) thirdPlaceExistedSeries
{
    if (_thirdPlaceExistedSeries)
    {
        return _thirdPlaceExistedSeries;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        return game.thirdPlacePlayerAfterDoubleJeopardy != nil;
    }];
    return [self filteredSeriesUsingPredicate:predicate];
}

#pragma mark Combining and Recombining Series

- (JeopardySeries*)seriesByUnioningSeries:(JeopardySeries*)series
{
    NSMutableOrderedSet *newSet = self.games.mutableCopy;
    [newSet unionOrderedSet:series.games];
    [newSet sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSUInteger gameid1 = [obj1 gameID];
        NSUInteger gameid2 = [obj2 gameID];
        if (gameid1 > gameid2)
        {
            return NSOrderedDescending;
        }
        else if (gameid2 > gameid1)
        {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    return [JeopardySeries seriesWithGames:newSet];
}

- (JeopardySeries*)seriesByMinusingSeries:(JeopardySeries*)series
{
    NSMutableOrderedSet *newSet = self.games.mutableCopy;
    [newSet minusOrderedSet:series.games];
    return [JeopardySeries seriesWithGames:newSet];
}
- (JeopardySeries*)seriesByIntersectingSeries:(JeopardySeries*)series
{
    NSMutableOrderedSet *newSet = self.games.mutableCopy;
    [newSet intersectOrderedSet:series.games];
    return [JeopardySeries seriesWithGames:newSet];
}

- (JeopardySeries*)randomizedSeries
{
    NSMutableOrderedSet *oldGames = self.games.mutableCopy;
    NSMutableOrderedSet *newGames = [NSMutableOrderedSet orderedSetWithCapacity:self.games.count];
    
    while (oldGames.count)
    {
        NSUInteger indexToRemove = arc4random_uniform((u_int32_t)oldGames.count);
        JeopardyGame *aGame = [oldGames objectAtIndex:indexToRemove];
        [newGames addObject:aGame];
        [oldGames removeObjectAtIndex:indexToRemove];
    }
    
    return [JeopardySeries seriesWithGames:newGames];
}

- (JeopardySeries*)continuousSeries
{
    NSUInteger nextPlayerid = 0;
    NSArray *previousWinners = nil;
    
    NSMutableOrderedSet *newGames = self.games.mutableCopy;
    
    for (JeopardyGame *game in newGames.copy)
    {
        NSMutableArray *newPlayers = [NSMutableArray array];
        for (JeopardyPlayer *previousWinner in previousWinners)
        {
            JeopardyPlayer *oldPlayer = [game.players objectAtIndex:[previousWinners indexOfObject:previousWinner]];
            JeopardyPlayer *newPlayer = [JeopardyPlayer jeopardyPlayerWithID:previousWinner.playerID name:previousWinner.name scoreAfterDoubleJeopardy:oldPlayer.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:oldPlayer.scoreAfterFinalJeopardy andAnsweredFinalJeopardyCorrectly:oldPlayer.answeredFinalJeopardyCorrectly];
            [newPlayers addObject:newPlayer];
        }
        
        for (NSUInteger i = newPlayers.count; i<3; i++)
        {
            JeopardyPlayer *oldPlayer = [game.players objectAtIndex:i];
            JeopardyPlayer *newPlayer = [JeopardyPlayer jeopardyPlayerWithID:nextPlayerid name:[NSString stringWithFormat:@"#%lu", nextPlayerid] scoreAfterDoubleJeopardy:oldPlayer.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:oldPlayer.scoreAfterFinalJeopardy andAnsweredFinalJeopardyCorrectly:oldPlayer.answeredFinalJeopardyCorrectly];
            [newPlayers addObject:newPlayer];
            nextPlayerid++;
        }
        
        JeopardyGame *newGame = [JeopardyGame gameWithPlayers:newPlayers gameID:game.gameID andDate:game.date];
        [newGames replaceObjectAtIndex:[newGames indexOfObject:game] withObject:newGame];
        previousWinners = newGame.winners;
        
        /* These three games feature no return winners. The first first two are due to gaps in the j-archive, the third is because Priscilla Ball fell ill. She returns under a second playerid and is treated as an entirely new player for these purposes */
        if (game.gameID == 1065585600 || game.gameID == 1073278800 || game.gameID == 1232341200)
        {
            previousWinners = [NSArray array];
        }
    }
    
    return [JeopardySeries seriesWithGames:newGames];
}

#pragma mark Player Filtering

- (JeopardySeries*)playerSeries:(NSUInteger)playerid
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        JeopardyGame *game = evaluatedObject;
        for (JeopardyPlayer *player in game.players)
        {
            if (player.playerID == playerid)
            {
                return YES;
            }
        }
        return NO;
    }];
    return [self filteredSeriesUsingPredicate:predicate];
}

- (NSDictionary*)playerWinnings
{
    if (_playerWinnings)
    {
        return _playerWinnings;
    }
    
    NSMutableDictionary *winnings = [NSMutableDictionary dictionaryWithCapacity:self.games.count*3];
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.players)
        {
            NSUInteger gameWinnings = [game winningsForPlayer:player];
            NSNumber *playerid = [NSNumber numberWithUnsignedInteger:player.playerID];
            NSDictionary *playerKey = [NSDictionary dictionaryWithObjectsAndKeys:playerid, @"playerid", player.name, @"name", nil];
            NSNumber *seriesWinnings = [winnings objectForKey:playerKey];
            seriesWinnings = [NSNumber numberWithUnsignedInteger:seriesWinnings.unsignedIntegerValue + gameWinnings];
            [winnings setObject:seriesWinnings forKey:playerKey];
        }
    }
    _playerWinnings = winnings;
    return _playerWinnings;
}

#pragma mark Statistics

- (NSUInteger)numberOfGameWhichEndedInATie
{
    NSUInteger winners = 0;
    for (JeopardyGame *game in self.games)
    {
        if (game.winners.count > 1)
        {
            winners++;
        }
    }
    return winners;
}



- (NSUInteger)winnings
{
    NSUInteger winnings = 0;
    
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.players)
        {
            winnings += [game winningsForPlayer:player];
        }
    }
    
    return winnings;
}

- (NSUInteger)firstPlaceWinnings
{
    NSUInteger firstPlaceWinnings = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            firstPlaceWinnings += [game winningsForPlayer:player];
        }
    }
    return firstPlaceWinnings;
}

- (NSUInteger)secondPlaceWinnings
{
    NSUInteger secondPlaceWinnings = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            secondPlaceWinnings += [game winningsForPlayer:player];
        }
    }
    return secondPlaceWinnings;
}

- (NSUInteger)thirdPlaceWinnings
{
    NSUInteger thirdPlaceWinnings = 0;
    for (JeopardyGame *game in self.games)
    {
        thirdPlaceWinnings += [game winningsForPlayer:game.thirdPlacePlayerAfterDoubleJeopardy];
    }
    
    return thirdPlaceWinnings;
}

- (NSUInteger)totalPlayers
{
    NSMutableSet *set = [NSMutableSet setWithCapacity:self.games.count*3];
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.players)
        {
            NSNumber *gameid = [NSNumber numberWithUnsignedInteger:player.playerID];
            [set addObject:gameid];
        }
    }
    
    return set.count;
}

- (CGFloat)perPlayerWinnings
{
    return (CGFloat)self.winnings/(CGFloat)self.totalPlayers;
}


- (CGFloat)firstPlaceAnswerPercentage
{
    NSUInteger correctAnswers = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            numPlayers++;
            if (player.answeredFinalJeopardyCorrectly)
            {
                correctAnswers++;
            }
        }
    }
    
    return (CGFloat)correctAnswers / (CGFloat)numPlayers;
}
- (CGFloat)secondPlaceAnswerPercentage
{
    NSUInteger correctAnswers = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            numPlayers++;
            if (player.answeredFinalJeopardyCorrectly)
            {
                correctAnswers++;
            }
        }
    }
    
    return (CGFloat)correctAnswers / (CGFloat)numPlayers;
}
- (CGFloat)thirdPlaceAnswerPercentage
{
    NSUInteger correctAnswers = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        if (game.thirdPlacePlayerAfterDoubleJeopardy)
        {
            numPlayers++;
            if (game.thirdPlacePlayerAfterDoubleJeopardy.answeredFinalJeopardyCorrectly)
            {
                correctAnswers++;
            }
        }
    }
    
    return (CGFloat)correctAnswers / (CGFloat)numPlayers;
}

- (CGFloat)firstPlaceWinPercentage
{
    NSUInteger wins = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.firstPlacePlayersAfterDoubleJeopardy)
        {
            numPlayers++;
            if ([game.winners containsObject:player])
            {
                wins++;
            }
        }
    }
    
    return (CGFloat)wins/(CGFloat)numPlayers;
}

- (CGFloat)secondPlaceWinPercentage
{
    NSUInteger wins = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.secondPlacePlayersAfterDoubleJeopardy)
        {
            numPlayers++;
            if ([game.winners containsObject:player])
            {
                wins++;
            }
        }
    }
    
    return (CGFloat)wins/(CGFloat)numPlayers;
}

- (CGFloat)thirdPlaceWinPercentage
{
    NSUInteger wins = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        if (game.thirdPlacePlayerAfterDoubleJeopardy)
        {
            numPlayers++;
            if ([game.winners containsObject:game.thirdPlacePlayerAfterDoubleJeopardy])
            {
                wins++;
            }
        }
    }
    
    return (CGFloat)wins/(CGFloat)numPlayers;
}

@end

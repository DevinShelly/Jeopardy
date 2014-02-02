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

@property (readwrite) NSArray *games;

@end

@implementation JeopardySeries

@synthesize seriesConsistingOfLockGames = _seriesConsistingOfLockGames;
@synthesize seriesConsistingOfLockTieGames = _seriesConsistingOfLockTieGames;
@synthesize seriesConsistingOfNonLockOrTieGames = _seriesConsistingOfNonLockOrTieGames;
@synthesize seriesConsistingOfTieGames = _seriesConsistingOfTieGames;
@synthesize seriesWithOptimalTieWagering = _seriesWithOptimalTieWagering;
@synthesize seriesWithOptimalWinWagering = _seriesWithOptimalWinWagering;
@synthesize seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie = _seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie;
@synthesize seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin = _seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin;
@synthesize seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss = _seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss;

+ (JeopardySeries*)seriesFromJSONFile:(NSString*)jsonFilepath
{
    NSData *gamesData = [NSData dataWithContentsOfFile:jsonFilepath];
    NSArray *gamesJSON = [NSJSONSerialization JSONObjectWithData:gamesData options:NSJSONReadingAllowFragments error:nil];
    NSMutableArray *games = [NSMutableArray arrayWithCapacity:gamesJSON.count];
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

+ (JeopardySeries*)seriesWithGames:(NSArray *)games
{
    JeopardySeries *series = [[JeopardySeries alloc] init];
    series.games = games;
    return series;
}

- (void)writeJSONToFile:(NSString *)filePath
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self.arrayRepresentation options:NSJSONWritingPrettyPrinted error:nil];
    [JSONData writeToFile:filePath atomically:NO];
}

#pragma mark - Getters

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

- (NSString*)description
{
    return self.arrayRepresentation.description;
}

- (NSArray*)arrayRepresentation
{
    NSMutableArray *games = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        [games addObject:game.dictionaryRepresentation];
    }
    
    return games;
}

- (NSUInteger)moneyWon
{
    NSUInteger moneyWon = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.winners)
        {
            moneyWon += player.scoreAfterFinalJeopardy;
        }
        for (JeopardyPlayer *player in game.runnersUp)
        {
            moneyWon += 2000;
        }
        if (game.thirdPlacePlayerAfterDoubleJeopardy)
        {
            moneyWon += 1000;
        }
    }
    
    return moneyWon;
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
    return (CGFloat)self.moneyWon/(CGFloat)self.totalPlayers;
}

- (JeopardySeries*)seriesWithOptimalWinWagering
{
    if (_seriesWithOptimalWinWagering)
    {
        return _seriesWithOptimalWinWagering;
    }
    
    NSMutableArray *optimalGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        game.previousWinners = [optimalGames.lastObject winners];
        game.nextNewPlayerid = [optimalGames.lastObject nextNewPlayerid];
        JeopardyGame *optimalGame = game.gameWithOptimalWinBetting;
        [optimalGames addObject:optimalGame];
    }
    
    _seriesWithOptimalWinWagering = [JeopardySeries seriesWithGames:optimalGames];
    return _seriesWithOptimalWinWagering;
}
- (JeopardySeries*)seriesWithOptimalTieWagering
{
    if (_seriesWithOptimalTieWagering)
    {
        return _seriesWithOptimalTieWagering;
    }
    
    NSMutableArray *optimalGames = [NSMutableArray arrayWithCapacity:self.games.count];
    
    for (JeopardyGame *game in self.games)
    {
        game.previousWinners = [optimalGames.lastObject winners];
        game.nextNewPlayerid = [optimalGames.lastObject nextNewPlayerid];
        JeopardyGame *optimalGame = game.gameWithOptimalTieBetting;
        [optimalGames addObject:optimalGame];
    }
    
    _seriesWithOptimalTieWagering = [JeopardySeries seriesWithGames:optimalGames];
    return _seriesWithOptimalTieWagering;
}

- (JeopardySeries*) seriesConsistingOfLockGames
{
    if (_seriesConsistingOfLockGames)
    {
        return _seriesConsistingOfLockGames;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        if (game.isLockGame)
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfLockGames = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfLockGames;
}
- (JeopardySeries*) seriesConsistingOfTieGames
{
    if (_seriesConsistingOfTieGames)
    {
        return _seriesConsistingOfTieGames;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        if (game.isTieGame)
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfTieGames = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfTieGames;
}
- (JeopardySeries*) seriesConsistingOfLockTieGames
{
    if (_seriesConsistingOfLockTieGames)
    {
        return _seriesConsistingOfLockTieGames;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        if (game.isLockTieGame)
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfLockTieGames = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfLockTieGames;
}
- (JeopardySeries*) seriesConsistingOfNonLockOrTieGames
{
    if (_seriesConsistingOfNonLockOrTieGames)
    {
        return _seriesConsistingOfNonLockOrTieGames;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        if (!game.isLockGame && !game.isLockTieGame && !game.isTieGame)
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfNonLockOrTieGames = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfNonLockOrTieGames;
}

- (JeopardySeries*)seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie
{
    if (_seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie)
    {
        return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        
        JeopardyPlayer *leader = game.leadersAfterDoubleJeopardy.lastObject;
        if ((game.isNonTieOrLockGame || game.isLockGame) && leader.wager == [game optimalTieWagerForPlayer:leader])
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie;
}

- (JeopardySeries*)seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin
{
    if (_seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin)
    {
        return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin;
    }
    
    NSMutableArray *newGames = [NSMutableArray arrayWithCapacity:self.games.count];
    for (JeopardyGame *game in self.games)
    {
        JeopardyPlayer *leader = game.leadersAfterDoubleJeopardy.lastObject;
        JeopardyPlayer *secondPlace = game.secondPlacePlayersAfterDoubleJeopardy.lastObject;
        if  (game.isNonTieOrLockGame && leader.wager + leader.scoreAfterDoubleJeopardy > secondPlace.scoreAfterDoubleJeopardy*2)
        {
            [newGames addObject:game];
        }
        else if (game.isLockGame && leader.scoreAfterDoubleJeopardy - (NSInteger)leader.wager > secondPlace.scoreAfterDoubleJeopardy*2)
        {
            [newGames addObject:game];
        }
    }
    
    _seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin = [JeopardySeries seriesWithGames:newGames];
    return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin;
}

- (JeopardySeries*)seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss
{
    if (_seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss)
    {
        return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss;
    }
    
    NSMutableSet *set = [NSMutableSet setWithArray:self.games];
    [set minusSet:[NSSet setWithArray:self.seriesConsistingOfGamesWhereTheLeaderPlayedForTheWin.games]];
    [set minusSet:[NSSet setWithArray:self.seriesConsistingOfGamesWhereTheLeaderPlayedForTheTie.games]];
    [set minusSet:[NSSet setWithArray:self.seriesConsistingOfTieGames.games]];
    [set minusSet:[NSSet setWithArray:self.seriesConsistingOfLockTieGames.games]];
    
    _seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss = [JeopardySeries seriesWithGames:set.allObjects];
    return _seriesConsistingOfGamesWhereTheLeaderPlayedForTheLoss;
}

- (CGFloat)firstPlaceAnswerPercentage
{
    NSUInteger correctAnswers = 0;
    NSUInteger numPlayers = 0;
    for (JeopardyGame *game in self.games)
    {
        for (JeopardyPlayer *player in game.leadersAfterDoubleJeopardy)
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
        for (JeopardyPlayer *player in game.leadersAfterDoubleJeopardy)
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

//
//  JeopardyGame.m
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 1/29/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import "JeopardyGame.h"
#import "JeopardyPlayer.h"

@interface JeopardyGame ()

@property (readonly) NSArray *sortedFinalJeopardyPlayers;
@property (readonly) NSArray *sortedDoubleJeopardyPlayers;
@property (readwrite) NSArray *players;

@property (readwrite) NSUInteger gameID;
@property (readwrite) NSString *date;

@end

@implementation JeopardyGame

@synthesize sortedDoubleJeopardyPlayers = _sortedDoubleJeopardyPlayers;
@synthesize sortedFinalJeopardyPlayers = _sortedFinalJeopardyPlayers;
@synthesize winners = _winners;
@synthesize runnersUp = _runnersUp;
@synthesize thirdPlacePlayer = _thirdPlacePlayer;

@synthesize leadersAfterDoubleJeopardy = _leadersAfterDoubleJeopardy;
@synthesize secondPlacePlayersAfterDoubleJeopardy = _secondPlacePlayersAfterDoubleJeopardy;
@synthesize thirdPlacePlayerAfterDoubleJeopardy = _thirdPlacePlayerAfterDoubleJeopardy;

+ (instancetype)gameWithPlayers:(NSArray *)players gameID:(NSUInteger)gameID andDate:(NSString *)date
{
    NSAssert3(players.count == 3, @"JeopardyGame created without three players: %lu, %@, %@", gameID, date, players);
    NSAssert3([[players objectAtIndex:0] playerID] != [[players objectAtIndex:1] playerID], @"Player is multiaccounting Jeopardy: %lu %@, %@", gameID, date, players);
    NSAssert3([[players objectAtIndex:0] playerID] != [[players objectAtIndex:2] playerID], @"Player is multiaccounting Jeopardy: %lu %@, %@", gameID, date, players);
    NSAssert3([[players objectAtIndex:2] playerID] != [[players objectAtIndex:1] playerID], @"Player is multiaccounting Jeopardy: %lu %@, %@", gameID, date, players);
    
    JeopardyGame *game = [[self alloc] init];
    game.players = players;
    game.gameID = gameID;
    game.date = date;
    return game;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.players forKey:@"players"];
    [aCoder encodeInteger:self.gameID forKey:@"gameID"];
    [aCoder encodeObject:self.date forKey:@"date"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.players = [aDecoder decodeObjectForKey:@"players"];
        self.gameID = [aDecoder decodeIntegerForKey:@"gameID"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

- (BOOL)containsPlayer:(NSUInteger)playerID
{
    for (JeopardyPlayer *player in self.players)
    {
        if (player.playerID == playerID)
        {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Final Jeopardy
- (NSArray*)sortedFinalJeopardyPlayers
{
    if (!_sortedFinalJeopardyPlayers)
    {
        _sortedFinalJeopardyPlayers = [self.players sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 scoreAfterFinalJeopardy] > [obj2 scoreAfterFinalJeopardy])
            {
                return NSOrderedAscending;
            }
            else if ([obj1 scoreAfterFinalJeopardy] < [obj2 scoreAfterFinalJeopardy])
            {
                return NSOrderedDescending;
            }
            
            NSUInteger index1 = [self.players indexOfObject:obj1];
            NSUInteger index2 = [self.players indexOfObject:obj2];
            
            if (index1 > index2)
            {
                return NSOrderedAscending;
            }
            else if (index2 < index1)
            {
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }];
    }
        
    return _sortedFinalJeopardyPlayers;
}

- (NSArray*)winners
{
    if (!_winners)
    {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject scoreAfterFinalJeopardy] >= [[self.sortedFinalJeopardyPlayers objectAtIndex:0] scoreAfterFinalJeopardy];
        }];
        _winners = [self.sortedFinalJeopardyPlayers filteredArrayUsingPredicate:predicate];
        
        /* There was a malfunction in FJ, and the player who finished in second place returned as a winner. Make sure that happens here too */
        if (self.gameID == 1209614400)
        {
            _winners = [NSArray arrayWithObjects:[self.players objectAtIndex:0], [self.players objectAtIndex:1], nil];
        }
    }
    
    return _winners;
}

- (NSArray*)runnersUp
{
    if (!_runnersUp)
    {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.sortedFinalJeopardyPlayers];
        [array removeObjectsInArray:self.winners];
        if (array.count>1)
        {
            JeopardyPlayer *firstPlayer = [array objectAtIndex:0];
            JeopardyPlayer *secondPlayer = array.lastObject;
            if (secondPlayer.scoreAfterFinalJeopardy != firstPlayer.scoreAfterFinalJeopardy)
            {
                [array removeLastObject];
            }
            _runnersUp = array;
            
            /* There was a malfunction in FJ, and the player who finished in second place returned as a winner. Bump third place up to second */
            if (self.gameID == 1209614400)
            {
                _runnersUp = [NSArray arrayWithObject:self.players.lastObject];
            }
            
        }
    }
    
    return _runnersUp;
}

- (JeopardyPlayer*)thirdPlacePlayer
{
    if (self.winners.count + self.runnersUp.count == 3)
    {
        return nil;
    }
    
    return self.sortedFinalJeopardyPlayers.lastObject;
}

- (NSUInteger)finalPositionOfPlayer:(JeopardyPlayer*)player
{
    return [self.winners containsObject:player] ? 1 : [self.runnersUp containsObject:player] ? 2 : self.thirdPlacePlayer == player ? 3 : NSNotFound;
}

#pragma mark - Double Jeopardy

- (NSArray*)sortedDoubleJeopardyPlayers
{
    if (!_sortedDoubleJeopardyPlayers)
    {
        _sortedDoubleJeopardyPlayers = [self.players sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 scoreAfterDoubleJeopardy] > [obj2 scoreAfterDoubleJeopardy])
            {
                return NSOrderedAscending;
            }
            else if ([obj1 scoreAfterDoubleJeopardy] < [obj2 scoreAfterDoubleJeopardy])
            {
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }];
    }
    
    return _sortedDoubleJeopardyPlayers;
}

- (NSArray*)leadersAfterDoubleJeopardy
{
    if (!_leadersAfterDoubleJeopardy)
    {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject scoreAfterDoubleJeopardy] >= [[self.sortedDoubleJeopardyPlayers objectAtIndex:0] scoreAfterDoubleJeopardy];
        }];
        _leadersAfterDoubleJeopardy = [self.sortedDoubleJeopardyPlayers filteredArrayUsingPredicate:predicate];
    }
    
    return _leadersAfterDoubleJeopardy;
}

- (NSArray*)secondPlacePlayersAfterDoubleJeopardy
{
    if (!_secondPlacePlayersAfterDoubleJeopardy)
    {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.sortedDoubleJeopardyPlayers];
        [array removeObjectsInArray:self.leadersAfterDoubleJeopardy];
        
        if (array.count>1)
        {
            JeopardyPlayer *firstPlayer = [array objectAtIndex:0];
            JeopardyPlayer *secondPlayer = array.lastObject;
            if (secondPlayer.scoreAfterDoubleJeopardy != firstPlayer.scoreAfterDoubleJeopardy)
            {
                [array removeLastObject];
            }
        }
        
        _secondPlacePlayersAfterDoubleJeopardy = array;
    }
    
    return _secondPlacePlayersAfterDoubleJeopardy;
}

- (JeopardyPlayer*)thirdPlacePlayerAfterDoubleJeopardy
{
    if (self.leadersAfterDoubleJeopardy.count + self.secondPlacePlayersAfterDoubleJeopardy.count == 3)
    {
        return nil;
    }
    
    return self.sortedDoubleJeopardyPlayers.lastObject;
}

#pragma mark - Optimal Wagering

- (NSUInteger)optimalTieWagerForLeader
{
    JeopardyPlayer *leader = self.leadersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *secondPlace = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    
    /* Tied at the end of DJ, wager it all */
    if (self.leadersAfterDoubleJeopardy.count > 1)
    {
        return [self.leadersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy];
    }
    /* Lock game, wager enough for the tie */
    else if (leader.scoreAfterDoubleJeopardy - secondPlace.scoreAfterDoubleJeopardy*2 > 0)
    {
        return leader.scoreAfterDoubleJeopardy - secondPlace.scoreAfterDoubleJeopardy*2;
    }
    
    /* Non lock game, wager enough to tie should second place double */
    return secondPlace.scoreAfterDoubleJeopardy*2 - leader.scoreAfterDoubleJeopardy;
}

- (NSUInteger)optimalTieWagerForSecondPlace
{
    /* If there is a tie for first place, both players will have to bet it all. Therefore, bet zero since you will also be likely to miss on a triple stumper  */
    if (self.leadersAfterDoubleJeopardy.count > 1)
    {
        return 0;
    }
    
    /* Since first place will play for the tie, bet it all */
    return [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy];
}

- (NSUInteger)optimalTieWagerForThirdPlace
{
    JeopardyPlayer *leader = [self leadersAfterDoubleJeopardy].lastObject;
    NSUInteger leaderWager = [self optimalTieWagerForLeader];
    NSInteger leaderScoreAfterMiss = leader.scoreAfterDoubleJeopardy - leaderWager;
    
    /* If we can catch the leader after a miss, bet enough for the tie, otherwise, bet 0 to ensure second place should second place miss */
    if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 >= leaderScoreAfterMiss)
    {
        return leaderScoreAfterMiss - self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy;
    }
    
    return 0;
}

- (NSUInteger)optimalTieWagerForPlayer:(JeopardyPlayer *)player
{
    if ([self.leadersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalTieWagerForLeader];
    }
    else if ([self.secondPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalTieWagerForSecondPlace];
    }
    
    return [self optimalTieWagerForThirdPlace];
}

- (NSUInteger)optimalWinWagerForLeader
{
    JeopardyPlayer *leader = self.leadersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *secondPlace = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    
    /* Leader is well over 50% in a lock game, so bet the max while still guaranteeing a win */
    if (self.isLockGame)
    {
        return leader.scoreAfterDoubleJeopardy - secondPlace.scoreAfterDoubleJeopardy*2 - 1;
    }
    
    if (self.isTieGame)
    {
        return leader.scoreAfterDoubleJeopardy;
    }
    
    if (self.isLockTieGame)
    {
        return 0;
    }
    
    return secondPlace.scoreAfterDoubleJeopardy*2 - leader.scoreAfterDoubleJeopardy + 1;
}

- (NSUInteger)optimalWinWagerForSecondPlace
{
    JeopardyPlayer *leader = self.leadersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *secondPlace = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *thirdPlace  = self.thirdPlacePlayerAfterDoubleJeopardy;
    
    if(self.secondPlacePlayersAfterDoubleJeopardy.count > 1)
    {
        return secondPlace.scoreAfterDoubleJeopardy;
    }
    
    if (self.isLockGame && thirdPlace.scoreAfterDoubleJeopardy * 2 <= secondPlace.scoreAfterDoubleJeopardy)
    {
        return 0;
    }
    
    if (self.isLockGame)
    {
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 - [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy]+1;
    }
    
    if (self.isLockTieGame)
    {
        return secondPlace.scoreAfterDoubleJeopardy;
    }
    
    NSInteger leaderScoreAfterMiss = leader.scoreAfterDoubleJeopardy - [self optimalWinWagerForLeader];
    NSInteger thirdPlaceDouble = thirdPlace.scoreAfterDoubleJeopardy*2;
    NSInteger scoreToBeat = MAX(leaderScoreAfterMiss, thirdPlaceDouble);
    
    if (secondPlace.scoreAfterDoubleJeopardy >= scoreToBeat)
    {
        return 0;
    }
    
    return scoreToBeat - secondPlace.scoreAfterDoubleJeopardy + 1;
}

- (NSUInteger)optimalWinWagerForThirdPlace
{
    NSInteger leaderScoreAfterMiss = [self.leadersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] - [self optimalWinWagerForLeader];
    NSInteger secondScoreAfterMiss = [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] - [self optimalTieWagerForSecondPlace];
    NSInteger scoreToBeatAfterTwoMisses = MAX(leaderScoreAfterMiss, secondScoreAfterMiss);
    NSInteger secondScoreToBeatAfterTwoMisses = MIN(leaderScoreAfterMiss, secondScoreAfterMiss);
    NSInteger thirdPlaceDouble = self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2;
    
    /* Does not play final jeopardy due to a negative score */
    if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy <= 0)
    {
        return 0;
    }
    
    /* Cannot catch either of the two other players, locked into third, wager is irrelevant */
    if (thirdPlaceDouble <= secondScoreToBeatAfterTwoMisses)
    {
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy;
    }
    /* Can only win in a W/W/R scenario, so bet it all to maximize winnings */
    else if (thirdPlaceDouble >= scoreToBeatAfterTwoMisses && self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy < scoreToBeatAfterTwoMisses)
    {
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy;
    }
    /* Can't catch first place, but can catch second place */
    else if (thirdPlaceDouble < scoreToBeatAfterTwoMisses && thirdPlaceDouble >= secondScoreToBeatAfterTwoMisses)
    {
        return secondScoreToBeatAfterTwoMisses - self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy + 1;
    }
    
    /* Third player can win in a triple stumper, therefore bet 0 */
    return 0;
}

- (NSUInteger)optimalWinWagerForPlayer:(JeopardyPlayer *)player
{
    if ([self.leadersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalWinWagerForLeader];
    }
    else if ([self.secondPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalWinWagerForSecondPlace];
    }
    
    return [self optimalWinWagerForThirdPlace];
}

- (BOOL)playerDidBetOptimallyForTie:(JeopardyPlayer*)player
{
    return player.wager == [self optimalTieWagerForPlayer:player];
}
- (BOOL)playerDidBetOptimallyForWin:(JeopardyPlayer*)player
{
    return player.wager == [self optimalWinWagerForPlayer:player];
}

- (JeopardyGame*)gameWithOptimalWinBetting
{
    NSMutableArray *optimalPlayers = [NSMutableArray array];
    NSUInteger podiumPosition = 0;
    for (JeopardyPlayer *player in self.players)
    {
        NSUInteger optimalWager = [self optimalWinWagerForPlayer:player];
        NSInteger newFinalScore = player.answeredFinalJeopardyCorrectly ? player.scoreAfterDoubleJeopardy + optimalWager : player.scoreAfterDoubleJeopardy - optimalWager;
        NSUInteger optimumPlayerID = self.nextNewPlayerid;
        NSString *optimumPlayerName = [NSString stringWithFormat:@"#%lu", optimumPlayerID];
        if (podiumPosition < self.previousWinners.count)
        {
            optimumPlayerID = [[self.previousWinners objectAtIndex:podiumPosition] playerID];
            optimumPlayerName = [[self.previousWinners objectAtIndex:podiumPosition] name];
        }
        else
        {
            self.nextNewPlayerid++;
        }
        
        JeopardyPlayer *optimumPlayer = [JeopardyPlayer jeopardyPlayerWithID:optimumPlayerID name:optimumPlayerName scoreAfterDoubleJeopardy:player.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:newFinalScore andAnsweredFinalJeopardyCorrectly:player.answeredFinalJeopardyCorrectly];
        [optimalPlayers addObject:optimumPlayer];
        podiumPosition++;
    }
    
    JeopardyGame *optimalGame = [JeopardyGame gameWithPlayers:optimalPlayers gameID:self.gameID andDate:self.date];
    optimalGame.nextNewPlayerid = self.nextNewPlayerid;
    optimalGame.previousWinners = self.previousWinners;
    return optimalGame;
}

- (JeopardyGame*)gameWithOptimalTieBetting
{
    
    NSMutableArray *optimalPlayers = [NSMutableArray array];
    NSUInteger podiumPosition = 0;
    for (JeopardyPlayer *player in self.players)
    {
        NSUInteger optimalWager = [self optimalTieWagerForPlayer:player];
        NSInteger newFinalScore = player.answeredFinalJeopardyCorrectly ? player.scoreAfterDoubleJeopardy + optimalWager : player.scoreAfterDoubleJeopardy - optimalWager;
        NSUInteger optimumPlayerID = self.nextNewPlayerid;
        NSString *optimumPlayerName = [NSString stringWithFormat:@"#%lu", optimumPlayerID];
        if (podiumPosition < self.previousWinners.count)
        {
            optimumPlayerID = [[self.previousWinners objectAtIndex:podiumPosition] playerID];
            optimumPlayerName = [[self.previousWinners objectAtIndex:podiumPosition] name];
        }
        else
        {
            self.nextNewPlayerid++;
        }
        
        JeopardyPlayer *optimumPlayer = [JeopardyPlayer jeopardyPlayerWithID:optimumPlayerID name:optimumPlayerName scoreAfterDoubleJeopardy:player.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:newFinalScore andAnsweredFinalJeopardyCorrectly:player.answeredFinalJeopardyCorrectly];
        [optimalPlayers addObject:optimumPlayer];
        podiumPosition++;
    }
    
    JeopardyGame *optimalGame = [JeopardyGame gameWithPlayers:optimalPlayers gameID:self.gameID andDate:self.date];
    optimalGame.nextNewPlayerid = self.nextNewPlayerid;
    optimalGame.previousWinners = self.previousWinners;
    return optimalGame;
}

#pragma mark - Getters

- (NSDictionary*)dictionaryRepresentation
{
    NSMutableArray *players = [NSMutableArray arrayWithCapacity:3];
    for (JeopardyPlayer *player in self.players)
    {
        [players addObject:player.dictionaryRepresentation];
    }
    NSNumber *gameid = [NSNumber numberWithUnsignedInteger:self.gameID];
    return [NSDictionary dictionaryWithObjectsAndKeys:gameid, @"gameid", self.date, @"date", players, @"players", nil];
}

- (NSString*)description
{
    NSMutableArray *playersInOrderOfDJScores = self.leadersAfterDoubleJeopardy.mutableCopy;
    [playersInOrderOfDJScores addObjectsFromArray:self.secondPlacePlayersAfterDoubleJeopardy];
    if (self.thirdPlacePlayerAfterDoubleJeopardy)
    {
        [playersInOrderOfDJScores addObject:self.thirdPlacePlayerAfterDoubleJeopardy];
    }
    
    return [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:self.gameID], @"gameid", self.date, @"date", self.players, @"players", nil] description];
}

- (BOOL)isLockGame
{
    return !self.isTieGame && [self.leadersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] > [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy]* 2;
}

- (BOOL)isTieGame
{
    return self.leadersAfterDoubleJeopardy.count > 1;
}

- (BOOL)isNonTieOrLockGame
{
    return !self.isTieGame && !self.isLockGame && !self.isLockTieGame;
}

- (BOOL)isLockTieGame
{
    return [self.leadersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] - [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] == [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy];
}
- (NSArray*)previousWinners
{
    /* These three games feature no returning winners. The first two are due to gaps in the j-archive, the third is due to Priscilla Ball withdrawing due to illness. She returns under a new playerid later, so her second appearance is treated as a new player both in the real games and any hypothetical game */
    if (self.gameID == 1065585600 || self.gameID == 1073278800 || self.gameID == 1232341200)
    {
        return [NSArray array];
    }
    
    return _previousWinners;
}

@end

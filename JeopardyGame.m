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

@synthesize firstPlacePlayersAfterDoubleJeopardy = _firstPlacePlayersAfterDoubleJeopardy;
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

- (BOOL)isEqual:(id)object
{
    JeopardyGame *otherGame = object;
    return self.gameID == otherGame.gameID && [self.date isEqualToString:otherGame.date] && [self.players isEqualToArray:otherGame.players];
}

- (NSUInteger)hash
{
    return self.gameID;
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
    return self.dictionaryRepresentation.description;
}

#pragma mark Double Jeopardy

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

- (NSArray*)firstPlacePlayersAfterDoubleJeopardy
{
    if (!_firstPlacePlayersAfterDoubleJeopardy)
    {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject scoreAfterDoubleJeopardy] >= [[self.sortedDoubleJeopardyPlayers objectAtIndex:0] scoreAfterDoubleJeopardy];
        }];
        _firstPlacePlayersAfterDoubleJeopardy = [self.sortedDoubleJeopardyPlayers filteredArrayUsingPredicate:predicate];
    }
    
    return _firstPlacePlayersAfterDoubleJeopardy;
}

- (NSArray*)secondPlacePlayersAfterDoubleJeopardy
{
    if (!_secondPlacePlayersAfterDoubleJeopardy)
    {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.sortedDoubleJeopardyPlayers];
        [array removeObjectsInArray:self.firstPlacePlayersAfterDoubleJeopardy];
        
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
    if (self.firstPlacePlayersAfterDoubleJeopardy.count + self.secondPlacePlayersAfterDoubleJeopardy.count == 3)
    {
        return nil;
    }
    
    return self.sortedDoubleJeopardyPlayers.lastObject;
}

#pragma mark Final Jeopardy
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

- (NSUInteger)winningsForPlayer:(JeopardyPlayer *)player
{
    NSUInteger finalPosition = [self finalPositionOfPlayer:player];
    return finalPosition == 1 ? player.scoreAfterFinalJeopardy : finalPosition == 2 ? 2000 : 1000;
}

- (BOOL)firstPlaceWon
{
    for (JeopardyPlayer *first in self.firstPlacePlayersAfterDoubleJeopardy)
    {
        if ([self.winners containsObject:first])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) secondPlaceWon
{
    for (JeopardyPlayer *second in self.secondPlacePlayersAfterDoubleJeopardy)
    {
        if ([self.winners containsObject:second])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)thirdPlaceCanWinDoubleStumper
{
    for (JeopardyPlayer *firstPlace in self.firstPlacePlayersAfterDoubleJeopardy)
    {
        if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 < firstPlace.scoreAfterDoubleJeopardy - firstPlace.wager)
        {
            return NO;
        }
    }
    
    for (JeopardyPlayer *secondPlace in self.secondPlacePlayersAfterDoubleJeopardy)
    {
        if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 < secondPlace.scoreAfterDoubleJeopardy - secondPlace.wager)
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)thirdPlaceCanWinTripleStumper
{
    for (JeopardyPlayer *firstPlace in self.firstPlacePlayersAfterDoubleJeopardy)
    {
        if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy < firstPlace.scoreAfterDoubleJeopardy - firstPlace.wager)
        {
            return NO;
        }
    }
    
    for (JeopardyPlayer *secondPlace in self.secondPlacePlayersAfterDoubleJeopardy)
    {
        if (self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy  < secondPlace.scoreAfterDoubleJeopardy - secondPlace.wager)
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)thirdPlaceMustAnswerCorrectlyToWin
{
    return self.thirdPlaceCanWinDoubleStumper && !self.thirdPlaceCanWinTripleStumper;
}

- (BOOL)thirdPlaceWon
{
    return [self.winners containsObject:self.thirdPlacePlayerAfterDoubleJeopardy];
}

#pragma mark Types Of Games

- (BOOL)isLockGame
{
    JeopardyPlayer *leader = self.firstPlacePlayersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *second = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    return !self.isTieGame && leader.scoreAfterDoubleJeopardy > second.scoreAfterDoubleJeopardy * 2;
}

- (BOOL)isTieGame
{
    return self.firstPlacePlayersAfterDoubleJeopardy.count > 1;
}

- (BOOL)isLockTieGame
{
    JeopardyPlayer *leader = self.firstPlacePlayersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *second = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    return !self.isTieGame && leader.scoreAfterDoubleJeopardy == second.scoreAfterDoubleJeopardy*2;
}

- (BOOL)isNonTieOrLockGame
{
    return !self.isTieGame && !self.isLockGame && !self.isLockTieGame;
}

#pragma mark Optimal Tie Wagering
- (NSUInteger)optimalTieWagerForLeader
{
    JeopardyPlayer *leader = self.firstPlacePlayersAfterDoubleJeopardy.lastObject;
    JeopardyPlayer *secondPlace = self.secondPlacePlayersAfterDoubleJeopardy.lastObject;
    
    /* Tied at the end of DJ, wager it all */
    if (self.firstPlacePlayersAfterDoubleJeopardy.count > 1)
    {
        return [self.firstPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy];
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
    if (self.firstPlacePlayersAfterDoubleJeopardy.count > 1)
    {
        return 0;
    }
    
    /* Since first place will play for the tie, bet it all */
    return [self.secondPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy];
}

- (NSUInteger)optimalTieWagerForThirdPlace
{
    JeopardyPlayer *leader = [self firstPlacePlayersAfterDoubleJeopardy].lastObject;
    NSUInteger leaderWager = [self optimalTieWagerForLeader];
    NSInteger leaderScoreAfterMiss = leader.scoreAfterDoubleJeopardy - leaderWager;
    BOOL thirdPlayerNeedsToAnswerCorrectly = self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy < leaderScoreAfterMiss;
    BOOL thirdPlayerCanWin = self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 >= leaderScoreAfterMiss;
    BOOL thirdPlayerCanTie = self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy * 2 == leaderScoreAfterMiss;
    
    if (thirdPlayerCanTie)
    {
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy;
    }
    else if (thirdPlayerNeedsToAnswerCorrectly && thirdPlayerCanWin)
    {
        if (self.thirdPlaceShouldCooperate)
        {
            return leaderScoreAfterMiss - self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy;
        }
        
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy-1;
        
    }
    else if (thirdPlayerCanWin && self.thirdPlaceShouldCooperate)
    {
        return self.thirdPlacePlayerAfterDoubleJeopardy.scoreAfterDoubleJeopardy - leaderScoreAfterMiss;
    }
    
    return 0;
}

- (NSUInteger)optimalTieWagerForPlayer:(JeopardyPlayer *)player
{
    if ([self.firstPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalTieWagerForLeader];
    }
    else if ([self.secondPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalTieWagerForSecondPlace];
    }
    
    return [self optimalTieWagerForThirdPlace];
}

- (BOOL)playerDidBetOptimallyForTie:(JeopardyPlayer*)player
{
    return player.wager == [self optimalTieWagerForPlayer:player];
}

- (JeopardyGame*)optimalTieGame
{
    
    NSMutableArray *optimalPlayers = [NSMutableArray array];
    NSUInteger podiumPosition = 0;
    for (JeopardyPlayer *player in self.players)
    {
        NSUInteger optimalWager = [self optimalTieWagerForPlayer:player];
        NSInteger newFinalScore = player.answeredFinalJeopardyCorrectly ? player.scoreAfterDoubleJeopardy + optimalWager : player.scoreAfterDoubleJeopardy - optimalWager;
        
        JeopardyPlayer *optimumPlayer = [JeopardyPlayer jeopardyPlayerWithID:player.playerID name:player.name scoreAfterDoubleJeopardy:player.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:newFinalScore andAnsweredFinalJeopardyCorrectly:player.answeredFinalJeopardyCorrectly];
        [optimalPlayers addObject:optimumPlayer];
        podiumPosition++;
    }
    
    JeopardyGame *optimalGame = [JeopardyGame gameWithPlayers:optimalPlayers gameID:self.gameID andDate:self.date];
    
    return optimalGame;
}

#pragma mark Optimal Win Wagering

- (NSUInteger)optimalWinWagerForLeader
{
    JeopardyPlayer *leader = self.firstPlacePlayersAfterDoubleJeopardy.lastObject;
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
    JeopardyPlayer *leader = self.firstPlacePlayersAfterDoubleJeopardy.lastObject;
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
    NSInteger leaderScoreAfterMiss = [self.firstPlacePlayersAfterDoubleJeopardy.lastObject scoreAfterDoubleJeopardy] - [self optimalWinWagerForLeader];
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
    if ([self.firstPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalWinWagerForLeader];
    }
    else if ([self.secondPlacePlayersAfterDoubleJeopardy containsObject:player])
    {
        return [self optimalWinWagerForSecondPlace];
    }
    
    return [self optimalWinWagerForThirdPlace];
}

- (BOOL)playerDidBetOptimallyForWin:(JeopardyPlayer*)player
{
    return player.wager == [self optimalWinWagerForPlayer:player];
}

- (JeopardyGame*)optimalWinGame
{
    NSMutableArray *optimalPlayers = [NSMutableArray array];
    NSUInteger podiumPosition = 0;
    for (JeopardyPlayer *player in self.players)
    {
        NSUInteger optimalWager = [self optimalWinWagerForPlayer:player];
        NSInteger newFinalScore = player.answeredFinalJeopardyCorrectly ? player.scoreAfterDoubleJeopardy + optimalWager : player.scoreAfterDoubleJeopardy - optimalWager;
        
        JeopardyPlayer *optimumPlayer = [JeopardyPlayer jeopardyPlayerWithID:player.playerID name:player.name scoreAfterDoubleJeopardy:player.scoreAfterDoubleJeopardy scoreAfterFinalJeopardy:newFinalScore andAnsweredFinalJeopardyCorrectly:player.answeredFinalJeopardyCorrectly];
        [optimalPlayers addObject:optimumPlayer];
        podiumPosition++;
    }
    
    JeopardyGame *optimalGame = [JeopardyGame gameWithPlayers:optimalPlayers gameID:self.gameID andDate:self.date];
    return optimalGame;
}

@end

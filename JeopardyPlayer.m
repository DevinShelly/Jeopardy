//
//  JeopardyPlayer.m
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 1/29/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import "JeopardyPlayer.h"

@interface JeopardyPlayer ()

@property (readwrite) NSUInteger playerID;
@property (readwrite) NSString *name;
@property (readwrite) NSInteger scoreAfterDoubleJeopardy;
@property (readwrite) NSInteger scoreAfterFinalJeopardy;
@property (readwrite) BOOL answeredFinalJeopardyCorrectly;

@end

@implementation JeopardyPlayer

+(instancetype)jeopardyPlayerWithID:(NSUInteger)playerID name:(NSString *)name scoreAfterDoubleJeopardy:(NSInteger)doubleJeopardyScore scoreAfterFinalJeopardy:(NSInteger)finalJeopardyScore andAnsweredFinalJeopardyCorrectly:(BOOL)answeredCorrectly
{
    JeopardyPlayer *player = [[self alloc] init];
    player.playerID = playerID;
    player.name = name;
    player.scoreAfterDoubleJeopardy = doubleJeopardyScore;
    player.scoreAfterFinalJeopardy = finalJeopardyScore;
    player.answeredFinalJeopardyCorrectly = answeredCorrectly;
    return player;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.playerID forKey:@"playerid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.scoreAfterDoubleJeopardy forKey:@"scoreAfterDoubleJeopardy"];
    [aCoder encodeInteger:self.scoreAfterFinalJeopardy forKey:@"scoreAfterFinalJeopardy"];
    [aCoder encodeBool:self.answeredFinalJeopardyCorrectly forKey:@"answeredFinalJeopardyCorrectly"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.playerID = [aDecoder decodeIntegerForKey:@"playerid"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.scoreAfterDoubleJeopardy = [aDecoder decodeIntegerForKey:@"scoreAfterDoubleJeopardy"];
        self.scoreAfterFinalJeopardy = [aDecoder decodeIntegerForKey:@"scoreAfterFinalJeopardy"];
        self.answeredFinalJeopardyCorrectly = [aDecoder decodeBoolForKey:@"answeredFinalJeopardyCorrectly"];
    }
    
    return self;
}

#pragma mark - Getters

- (NSUInteger)wager
{
    return labs(self.scoreAfterFinalJeopardy - self.scoreAfterDoubleJeopardy);
}

- (NSString*)description
{
    return [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:self.playerID], @"playerid", [NSNumber numberWithInteger:self.scoreAfterFinalJeopardy], @"scoreAfterFinalJeopardy", [NSNumber numberWithInteger:self.scoreAfterDoubleJeopardy], @"scoreAfterDoubleJeopardy", self.name, @"name", [NSNumber numberWithBool:self.answeredFinalJeopardyCorrectly], @"answeredFinalJeopardyCorrectly", nil] description];
}

- (NSDictionary*)dictionaryRepresentation
{
    NSNumber *DJscore = [NSNumber numberWithInteger:self.scoreAfterDoubleJeopardy];
    NSNumber *FJscore = [NSNumber numberWithInteger:self.scoreAfterFinalJeopardy];
    NSNumber *answeredCorrectly = [NSNumber numberWithBool:self.answeredFinalJeopardyCorrectly];
    NSNumber *playerid = [NSNumber numberWithUnsignedInteger:self.playerID];
    NSNumber *wager = [NSNumber numberWithUnsignedInteger:self.wager];
    NSString *name = self.name;
    return [NSDictionary dictionaryWithObjectsAndKeys:DJscore, @"DJscore", FJscore, @"FJScore", answeredCorrectly, @"answeredCorrectly", playerid, @"playerid", name, @"name", wager, @"wager", nil];
}

@end

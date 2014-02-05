//
//  JeopardyPlayer.h
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 1/29/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JeopardyPlayer : NSObject <NSCoding>

@property (readonly) NSUInteger playerID;
@property (readonly) NSString *name;
@property (readonly) NSInteger scoreAfterDoubleJeopardy;
@property (readonly) NSInteger scoreAfterFinalJeopardy;
@property (readonly) BOOL answeredFinalJeopardyCorrectly;

@property (readonly) NSInteger wager;

@property (readonly) NSDictionary *dictionaryRepresentation;

+(instancetype)jeopardyPlayerWithID:(NSUInteger)playerID name:(NSString*)name scoreAfterDoubleJeopardy:(NSInteger)doubleJeopardyScore scoreAfterFinalJeopardy:(NSInteger)finalJeopardyScore andAnsweredFinalJeopardyCorrectly:(BOOL)answeredCorrectly;

@end

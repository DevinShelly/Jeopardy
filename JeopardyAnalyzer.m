//
//  JeopardyAnalyzer.m
//  JeopardyWageringSim
//
//  Created by Devin Shelly on 1/29/14.
//  Copyright (c) 2014 Devin Shelly. All rights reserved.
//

#import "JeopardyAnalyzer.h"
#import "JeopardyGame.h"
#import "JeopardyPlayer.h"
#import "JeopardySeries.h"
#import "sqlite3.h"

@implementation JeopardyAnalyzer

- (void)logGameTypesForSeries:(JeopardySeries*)series
{
    NSLog(@"The games were of the following type:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu\n----------------------------------------------------------------------------------------------------------------------------", series.lockSeries.games.count, series.tieSeries.games.count, series.lockTieSeries.games.count, series.nonLockOrTieSeries.games.count, series.games.count);
}

- (void)logEndGameTiesForSeries:(JeopardySeries*)series
{
    NSLog(@"There were %lu ties at the end of Final Jeopardy", series.multipleWinnersSeries.games.count);
}

- (void)logCorrectAnswersForSeries:(JeopardySeries*)series
{
    NSLog(@"First place answered correctly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.firstPlaceCorrectSeries.games.count, series.tieSeries.firstPlaceCorrectSeries.games.count,  series.lockTieSeries.firstPlaceCorrectSeries.games.count, series.nonLockOrTieSeries.firstPlaceCorrectSeries.games.count, series.firstPlaceCorrectSeries.games.count);
    NSLog(@"First place answered incorrectly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.firstPlaceIncorrectSeries.games.count, series.tieSeries.firstPlaceIncorrectSeries.games.count,  series.lockTieSeries.firstPlaceIncorrectSeries.games.count, series.nonLockOrTieSeries.firstPlaceIncorrectSeries.games.count, series.firstPlaceIncorrectSeries.games.count);
    
    NSLog(@"Second place answered incorrectly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.secondPlaceCorrectSeries.games.count, series.tieSeries.secondPlaceCorrectSeries.games.count, series.lockTieSeries.secondPlaceCorrectSeries.games.count, series.nonLockOrTieSeries.secondPlaceCorrectSeries.games.count, series.secondPlaceCorrectSeries.games.count);
    NSLog(@"Second place answered correctly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.secondPlaceIncorrectSeries.games.count, series.tieSeries.secondPlaceIncorrectSeries.games.count, series.lockTieSeries.secondPlaceIncorrectSeries.games.count, series.nonLockOrTieSeries.secondPlaceIncorrectSeries.games.count, series.secondPlaceCorrectSeries.games.count);
    
    
    NSLog(@"Third place answered correctly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.thirdPlaceCorrectSeries.games.count, series.tieSeries.thirdPlaceCorrectSeries.games.count, series.lockTieSeries.thirdPlaceCorrectSeries.games.count, series.nonLockOrTieSeries.thirdPlaceCorrectSeries.games.count, series.thirdPlaceCorrectSeries.games.count);
    NSLog(@"Third place answered correctly the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu\n----------------------------------------------------------------------------------------------------------------------------", series.lockSeries.thirdPlaceIncorrectSeries.games.count, series.tieSeries.thirdPlaceIncorrectSeries.games.count, series.lockTieSeries.thirdPlaceIncorrectSeries.games.count, series.nonLockOrTieSeries.thirdPlaceIncorrectSeries.games.count, series.thirdPlaceIncorrectSeries.games.count);
}

- (void)logWinsForSeries:(JeopardySeries*)series
{
    NSLog(@"First place won the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu", series.lockSeries.firstPlaceWonSeries.games.count, series.tieSeries.firstPlaceWonSeries.games.count, series.lockTieSeries.firstPlaceWonSeries.games.count, series.nonLockOrTieSeries.firstPlaceWonSeries.games.count, series.firstPlaceWonSeries.games.count);
    
    NSLog(@"Second place won the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu\n", series.lockSeries.secondPlaceWonSeries.games.count, series.tieSeries.secondPlaceWonSeries.games.count, series.lockTieSeries.secondPlaceWonSeries.games.count, series.nonLockOrTieSeries.secondPlaceWonSeries.games.count, series.secondPlaceWonSeries.games.count);
    
    NSLog(@"Third place won the following times:");
    NSLog(@"Lock: %lu Tie: %lu Locktie: %lu All Others: %lu Total: %lu\n----------------------------------------------------------------------------------------------------------------------------", series.lockSeries.thirdPlaceWonSeries.games.count, series.tieSeries.thirdPlaceWonSeries.games.count, series.lockTieSeries.thirdPlaceWonSeries.games.count, series.nonLockOrTieSeries.thirdPlaceWonSeries.games.count, series.thirdPlaceWonSeries.games.count);
}

- (void)logWinningsByPosition:(JeopardySeries*)series
{
    NSLog(@"Players in first place entering Final Jeopardy won $%lu. Second: $%lu Third: $%lu Total: $%lu", series.firstPlaceWinnings, series.secondPlaceWinnings, series.thirdPlaceWinnings, series.winnings);
    NSLog(@"Overall, %lu players appeared on Jeopardy! and earned an average of %f dollars", series.totalPlayers, series.perPlayerWinnings);
}

- (void)logThirdPlaceTotalWinnings:(JeopardySeries*)series
{
    NSMutableSet *playersWhoWonAGameFromThirdPlace = [NSMutableSet set];
    for (JeopardyGame *game in series.games)
    {
        if (game.thirdPlaceWon)
        {
            NSDictionary *playerKey = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:game.thirdPlacePlayerAfterDoubleJeopardy.playerID], @"playerid", game.thirdPlacePlayerAfterDoubleJeopardy.name, @"name", nil];
            [playersWhoWonAGameFromThirdPlace addObject:playerKey];
        }
    }
    
    NSUInteger thirdPlaceWinnings = 0;
    for (NSDictionary *playerKey in series.playerWinnings)
    {
        if ([playersWhoWonAGameFromThirdPlace containsObject:playerKey])
        {
            thirdPlaceWinnings += [[series.playerWinnings objectForKey:playerKey] unsignedIntegerValue];
        }
    }
    
    NSLog(@"In total, players who won a game while starting Final Jeopardy in third place won $%lu\n----------------------------------------------------------------------------------------------------------------------------", thirdPlaceWinnings);
}

- (void)startAnalysis:(id)sender
{
    if ([[NSThread currentThread] isMainThread])
    {
        [self performSelectorInBackground:@selector(startAnalysis:) withObject:sender];
        return;
    }
    
    JeopardySeries *realLife = [JeopardySeries seriesFromJSONFile:[[NSBundle mainBundle] pathForResource:@"games" ofType:@"txt"]];
    
    NSLog(@"For the following stats, all real life data is used.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logGameTypesForSeries:realLife];
    [self logCorrectAnswersForSeries:realLife];
    NSLog(@"For the following stats, first place answered correctly.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logCorrectAnswersForSeries:realLife.firstPlaceCorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceCorrectSeries];
    NSLog(@"For the following stats, first place answered incorrectly.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logCorrectAnswersForSeries:realLife.firstPlaceIncorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceIncorrectSeries];
    NSLog(@"For the following stats, first and second place answered correctly.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logCorrectAnswersForSeries:realLife.firstPlaceCorrectSeries.secondPlaceCorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceCorrectSeries.secondPlaceCorrectSeries];
    NSLog(@"For the following stats, first place answered correctly and second place answered incorrectly\n----------------------------------------------------------------------------------------------------------------------------");
    [self logCorrectAnswersForSeries:realLife.firstPlaceCorrectSeries.secondPlaceIncorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceCorrectSeries.secondPlaceIncorrectSeries];
    NSLog(@"For the following stats, first place answered incorrectly and second place answered correctly\n----------------------------------------------------------------------------------------------------------------------------");
    [self logCorrectAnswersForSeries:realLife.firstPlaceIncorrectSeries.secondPlaceCorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceIncorrectSeries.secondPlaceCorrectSeries];
    NSLog(@"For the following stats, first and second place answered incorrectly (%lu total games)\n----------------------------------------------------------------------------------------------------------------------------", realLife.firstPlaceIncorrectSeries.secondPlaceIncorrectSeries.games.count);
    [self logCorrectAnswersForSeries:realLife.firstPlaceIncorrectSeries.secondPlaceIncorrectSeries];
    [self logWinsForSeries:realLife.firstPlaceIncorrectSeries.secondPlaceIncorrectSeries];
    
    NSLog(@"For the following stats, all real life data is used.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logEndGameTiesForSeries:realLife];
    [self logWinsForSeries:realLife];
    [self logWinningsByPosition:realLife];
    [self logThirdPlaceTotalWinnings:realLife];
    
    NSLog(@"For the following stats, the wagering has been changed so that it follows the tie strategy with third place cooperating.\n----------------------------------------------------------------------------------------------------------------------------");
    realLife.thirdPlaceShouldCooperate = YES;
    [self logEndGameTiesForSeries:realLife.optimalTieSeries];
    [self logWinsForSeries:realLife.optimalTieSeries];
    [self logWinningsByPosition:realLife.optimalTieSeries];
    [self logThirdPlaceTotalWinnings:realLife.optimalTieSeries];
    NSLog(@"For the following stats, the wagering has been changed so that it follows the tie strategy with third place not cooperating.\n----------------------------------------------------------------------------------------------------------------------------");
    realLife.thirdPlaceShouldCooperate = NO;
    [self logEndGameTiesForSeries:realLife.optimalTieSeries];
    [self logWinsForSeries:realLife.optimalTieSeries];
    [self logWinningsByPosition:realLife.optimalTieSeries];
    [self logThirdPlaceTotalWinnings:realLife.optimalTieSeries];
    
    NSLog(@"For the following stats, the wagering has been changed so that it follows the win strategy.\n----------------------------------------------------------------------------------------------------------------------------");
    [self logEndGameTiesForSeries:realLife.optimalWinSeries];
    [self logWinsForSeries:realLife.optimalWinSeries];
    [self logWinningsByPosition:realLife.optimalWinSeries];
    [self logThirdPlaceTotalWinnings:realLife.optimalWinSeries];
}



@end

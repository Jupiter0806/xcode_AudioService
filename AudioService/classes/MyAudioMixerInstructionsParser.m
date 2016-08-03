//
//  MyAudioMixerInstructionsParser.m
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import "MyAudioMixerInstructionsParser.h"

@interface MyAudioMixerInstructionsParser() {
    NSMutableArray *instructions;
}

@end

@implementation MyAudioMixerInstructionsParser

- (id) initWithAudioMixerInstructions: (NSString *)str_instructions {
    NSLog(@"Init a MyAudioMixerInstructionsParser with instructions.");
    
    self = [super init];
    
    instructions = [[NSMutableArray alloc] init];
    _bgmsFileUrl = [[NSMutableArray alloc] init];
    
    NSArray *str_instructions_components = [str_instructions componentsSeparatedByString:@";"];
    
    for (int i = 0; i < [str_instructions_components count] - 1; i++) {
        [instructions addObject:[[MyAudioMixerInstruction alloc] initWithNSStringInstruction:[str_instructions_components objectAtIndex:i]]];
    }
    
    for (int i = 0; i < [instructions count]; i++) {
        if (![_bgmsFileUrl containsObject:[[instructions objectAtIndex:i] bgmFileUrl]]) {
            [_bgmsFileUrl addObject:[[instructions objectAtIndex:i] bgmFileUrl]];
        }
    }
    
    return self;
}

// if return false then index, whetherNeedBGM and bgmOffsetInMS are unusable
- (BOOL) getNextInstructionWithMSPostion: (NSInteger) ms bgmIndex:(int *)index bgmOffsetInMS:(int *) offset whetherNeedBGM:(bool *)needBGM {
    BOOL res = true;
    
    for (int i = 0; i < [instructions count]; i++) {
        if ([[instructions objectAtIndex:i] startPosition] <= ms && [[instructions objectAtIndex:i] endPosition] >= ms) {
            // found the bgm
            *index = [_bgmsFileUrl indexOfObject:[[instructions objectAtIndex:i] bgmFileUrl]];
            *offset = [[instructions objectAtIndex:i] offset];
            *needBGM = true;
            return res;
        }
    }
    
    *needBGM = false;
    
    return res;
}

// --------------------------------------------------------------------------------------
//
// Helper functions
//
// --------------------------------------------------------------------------------------




@end

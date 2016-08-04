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

- (id) initWithAudioMixerInstructionsJSON: (NSString *)json_instructions {
    NSLog(@"Init a MyAudioMixerInstructionsParser with instructions JSON.");

    self = [super init];
    
    instructions = [[NSMutableArray alloc] init];
    _bgmsFileUrl = [[NSMutableArray alloc] init];
    
    NSData *data = [json_instructions dataUsingEncoding:NSUTF8StringEncoding];
    
    if (NSClassFromString(@"NSJSONSerialization")) {
        
        NSError *error = nil;
        
        id object = [NSJSONSerialization
                     JSONObjectWithData:data
                     options:0
                     error:&error];
        
        if (error) {
            NSLog(@"Parsing json in string to object failed");
        }
        
        if ([object isKindOfClass:[NSArray class]]) {
            NSArray *res = object;
            for (int i = 0; i < [res count]; i++) {
                MyAudioMixerInstruction *instruction = [[MyAudioMixerInstruction alloc] initWithNSDictionaryInstruction:[res objectAtIndex:i]];
                [instructions addObject:instruction];
            }
            
            for (int i = 0; i < [instructions count]; i++) {
                if (![_bgmsFileUrl containsObject:[[instructions objectAtIndex:i] bgmFileUrl]]) {
                    [_bgmsFileUrl addObject:[[instructions objectAtIndex:i] bgmFileUrl]];
                }
            }
            
        } else {
            NSLog(@"The parsing result is not in format of NSDictionary.");
        }
    } else {
        NSLog(@"NSJSONSerialization is not available.");
    }
    
    return self;
}



// if return false then index, whetherNeedBGM and bgmOffsetInMS are unusable
- (BOOL) getNextInstructionWithMSPostion: (UInt64) ms bgmIndex:(int *)index bgmOffsetInMS:(UInt64 *) offset whetherNeedBGM:(bool *)needBGM {
    BOOL res = true;
    
    for (int i = 0; i < [instructions count]; i++) {
        if ([[instructions objectAtIndex:i] startPosition] <= ms && [[instructions objectAtIndex:i] endPosition] >= ms) {
            // found the bgm
            *index = (int)[_bgmsFileUrl indexOfObject:[[instructions objectAtIndex:i] bgmFileUrl]];
            *offset = [[instructions objectAtIndex:i] offset];
            *needBGM = true;
            return res;
        }
    }
    
    *needBGM = false;
    
    return res;
}

- (BOOL) getNextInstructionWithMSPostion: (UInt64) ms bgmIndex:(int *)index bgmOffsetInMS:(UInt64 *) offset whetherNeedBGM:(bool *)needBGM volumeLevel:(int *)volumeLevel {
    BOOL res = true;
    
    for (int i = 0; i < [instructions count]; i++) {
        if ([[instructions objectAtIndex:i] startPosition] <= ms && [[instructions objectAtIndex:i] endPosition] >= ms) {
            // found the bgm
            *index = (int)[_bgmsFileUrl indexOfObject:[[instructions objectAtIndex:i] bgmFileUrl]];
            *offset = [[instructions objectAtIndex:i] offset];
            *needBGM = true;
            
            for (int j = 0; j < [[[instructions objectAtIndex:i] volumeControl] count]; j++) {
                NSDictionary *volumeControl = [[[instructions objectAtIndex:i] volumeControl] objectAtIndex:j];
                if ([[volumeControl objectForKey:@"startPosition"] integerValue] <= (ms - [[instructions objectAtIndex:i] startPosition]) &&
                    (ms - [[instructions objectAtIndex:i] startPosition]) <= [[volumeControl objectForKey:@"endPosition"] integerValue]) {
                    *volumeLevel = [[volumeControl objectForKey:@"volumeLevel"] integerValue];
                    
                    return res;
                }
            }
            // has not find any volume instruction, using 100 instead.
            *volumeLevel = 100;
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

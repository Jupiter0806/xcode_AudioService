//
//  MyAudioMixerInstruction.m
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import "MyAudioMixerInstruction.h"

@implementation MyAudioMixerInstruction

// not in user, the first version instruction
- (id) initWithNSStringInstruction: (NSString *)instruction {
    NSLog(@"Init an instruction.");
    
    self = [super init];
    
    NSArray *components = [instruction componentsSeparatedByString:@","];
    
    _startPosition = [[components objectAtIndex:0] integerValue] / 10;
    _endPosition = [[components objectAtIndex:1] integerValue] / 10;
    _bgmFileUrl = [components objectAtIndex:2];
    _offset = [[components objectAtIndex:3] integerValue] / 10;
    
    return self;
}

- (id) initWithNSDictionaryInstruction: (NSDictionary *)instruction {
    NSLog(@"Init an instruction.");

    self = [super init];
    
    _startPosition = [[instruction objectForKey:@"startPosition"] integerValue];
    _endPosition = [[instruction objectForKey:@"endPosition"] integerValue];
    _bgmFileUrl = [instruction objectForKey:@"bgmFileUrl"];
    _offset = [[instruction objectForKey:@"offset"] integerValue];
    _volumeControl = [instruction objectForKey:@"volumeControl"];
    
    return self;
}

@end

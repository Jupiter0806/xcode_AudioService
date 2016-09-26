//
//  MyAudioEditorInstructionParser.m
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioEditorInstructionParser.h"

@interface MyAudioEditorInstructionParser() {
    NSMutableArray *instructions;
}

@end

@implementation MyAudioEditorInstructionParser

- (id) initWithAudioEditorInstructionsString: (NSString *)str_instructions {
    NSLog(@"Init a MyAudioEditorInstructionParser with instruction.");
    
    self = [super init];
    
    instructions = [[NSMutableArray alloc] init];
    
    NSArray *str_instructions_components = [str_instructions componentsSeparatedByString:@";"];
    
    for (int i = 0; i < [str_instructions_components count] - 1; i++) {
        [instructions addObject:[[MyAudioEditorInstruction alloc] initWithNSStringInstruction:[str_instructions_components objectAtIndex:i]]];
    }
    
    return self;
}

- (Boolean) ifNeedSkipAt:(UInt64) position {
    Boolean res = false;
    
    for (int i = 0; i < [instructions count]; i++) {
        UInt64 startPosition = [[instructions objectAtIndex:i] getStartPosition];
        UInt64 endPosition = [[instructions objectAtIndex:i] getEndPosition];
        
        if (position >= startPosition && position <= endPosition) {
            res = true;
        }
    }
    
    return res;
}

@end

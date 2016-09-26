//
//  MyAudioEditorInstruction.m
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioEditorInstruction.h"

@implementation MyAudioEditorInstruction

- (id) initWithNSStringInstruction : (NSString *)instruction {
    NSLog(@"Init a MyAudioEditorInstruction");
    
    self = [super init];
    
    NSArray *components = [instruction componentsSeparatedByString:@","];
    
    _startPosition = [[components objectAtIndex:0] integerValue];
    _endPosition = [[components objectAtIndex:1] integerValue];
    
    return self;

}

// getter
- (UInt64) getStartPosition {
    return _startPosition;
}
- (UInt64) getEndPosition {
    return _endPosition;
}

@end

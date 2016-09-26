//
//  MyAudioEditorInstruction.h
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyAudioEditorInstruction : NSObject

@property (readonly) UInt64 startPosition;
@property (readonly) UInt64 endPosition;

- (id) initWithNSStringInstruction : (NSString *)instruction;

// getter, I was supposed to use propery getter, but have watched some article still has no idea how to do it
- (UInt64) getStartPosition;
- (UInt64) getEndPosition;

@end

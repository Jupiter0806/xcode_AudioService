//
//  MyAudioEditorInstructionParser.h
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MyAudioEditorInstruction.h"

@interface MyAudioEditorInstructionParser : NSObject

- (id) initWithAudioEditorInstructionsString: (NSString *)instructions;

- (Boolean) ifNeedSkipAt:(UInt64) position;

@end

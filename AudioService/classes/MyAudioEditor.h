//
//  MyAudioEditor.h
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <unistd.h>

#import "MyAudioEditorInstructionParser.h"

@interface MyAudioEditor : NSObject

+ (bool) cutAudioWithInstructions:(NSString *)audioUrl instructions: (MyAudioEditorInstructionParser *)instructions outputFileUrl : (NSString *) outputFileUrl;

@end

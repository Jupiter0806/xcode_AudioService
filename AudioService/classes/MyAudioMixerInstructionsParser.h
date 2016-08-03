//
//  MyAudioMixerInstructionsParser.h
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import <Foundation/Foundation.h>

#import "MyAudioMixerInstruction.h"

@interface MyAudioMixerInstructionsParser : NSObject

@property (readonly) NSMutableArray *bgmsFileUrl;

- (id) initWithAudioMixerInstructions: (NSString *)instructions;

- (BOOL) getNextInstructionWithMSPostion: (NSInteger) ms bgmIndex:(int *)index bgmOffsetInMS:(int *) offset whetherNeedBGM:(bool *)needBGM;

@end

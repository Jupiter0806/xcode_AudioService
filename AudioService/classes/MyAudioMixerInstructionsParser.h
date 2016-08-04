//
//  MyAudioMixerInstructionsParser.h
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import <Foundation/Foundation.h>

#import "MyAudioMixerInstruction.h"
#import "JSONParser.h"

@interface MyAudioMixerInstructionsParser : NSObject

@property (readonly) NSMutableArray *bgmsFileUrl;

- (id) initWithAudioMixerInstructions: (NSString *)instructions;
- (id) initWithAudioMixerInstructionsJSON: (NSString *)instructions;

- (BOOL) getNextInstructionWithMSPostion: (UInt64) ms bgmIndex:(int *)index bgmOffsetInMS:(UInt64 *) offset whetherNeedBGM:(bool *)needBGM;
- (BOOL) getNextInstructionWithMSPostion: (UInt64) ms bgmIndex:(int *)index bgmOffsetInMS:(UInt64 *) offset whetherNeedBGM:(bool *)needBGM volumeLevel:(int *)volumeLevel;


@end

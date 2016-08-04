//
//  MyAudioMixerInstruction.h
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import <Foundation/Foundation.h>

@interface MyAudioMixerInstruction : NSObject

@property (readonly) UInt64 startPosition;
@property (readonly) UInt64 endPosition;
@property (readonly) UInt64 offset;
@property (readonly) NSString *bgmFileUrl;
@property (readonly) NSArray *volumeControl;

- (id) initWithNSStringInstruction: (NSString *)instruction;
- (id) initWithNSDictionaryInstruction: (NSDictionary *)instruction;

@end

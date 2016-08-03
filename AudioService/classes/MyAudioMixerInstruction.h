//
//  MyAudioMixerInstruction.h
//  HelloCordova
//
//  Created by Jupiter Li on 2/08/2016.
//
//

#import <Foundation/Foundation.h>

@interface MyAudioMixerInstruction : NSObject

@property (readonly) NSInteger startPosition;
@property (readonly) NSInteger endPosition;
@property (readonly) NSInteger offset;
@property (readonly) NSString *bgmFileUrl;

- (id) initWithNSStringInstruction: (NSString *)instruction;

@end

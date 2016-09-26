//
//  MyAudioRecorderAndPlayer.h
//  AudioService
//
//  Created by Jupiter Li on 9/08/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@interface MyAudioRecorderAndPlayer : NSObject

- (id) init;
- (BOOL) finalise;

- (BOOL) playWithUrl: (NSString *)url;
- (BOOL) stopPlay;

- (BOOL) record;
- (NSString *) stopRecord;

@end

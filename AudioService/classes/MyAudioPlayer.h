//
//  MyAudioPlayer.h
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MyAudioPlayer : NSObject <AVAudioPlayerDelegate> {
    AVAudioPlayer *myPlayer;
}

@property (readonly) NSString *audioFilePath;

- (id) initWithAudioFilePath: (NSString *) audioFilePath;

- (BOOL) setAudioFilePath: (NSString *) audioFilePath;

- (BOOL) playAudio: (NSString *) errorMessage;
- (BOOL) stopPlayingAudio: (NSString *) errorMessage;

@end

//
//  MyAudioPlayer.m
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioPlayer.h"

@implementation MyAudioPlayer

- (id) initWithAudioFilePath: (NSString *) audioFilePath {
    NSLog(@"Init an MyAudioPlayer with audio file path of %@", audioFilePath);
    
    self = [super init];
    
    NSError *err;
    
    _audioFilePath = audioFilePath;
    
    myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: [NSURL fileURLWithPath: _audioFilePath] error: &err];
    
    if (err) {
        [self standerErrorHandler: err withMessage: @"Init audio player"];
    }
    err = nil;
    
    [myPlayer setDelegate:self];
    
    return self;
}

- (BOOL) setAudioFilePath: (NSString *) audioFilePath {
    NSLog(@"Set audio file path from %@ to %@", _audioFilePath, audioFilePath);
    
    _audioFilePath = audioFilePath;
    
    NSError *err;

    myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: [NSURL fileURLWithPath: _audioFilePath] error: &err];
    
    if (err) {
        [self standerErrorHandler: err withMessage: @"Change audio file path: init a new audio player"];
        
        return false;
    }
    err = nil;
    
    return true;
}

- (BOOL) playAudio: (NSString *) errorMessage {
    NSLog(@"Play audio at %@", _audioFilePath);
    
    if (myPlayer) {
        [myPlayer play];
        return true;
    } else {
        errorMessage = @"Cannot play audio due to player not set up properly";
        NSLog(@"%@", errorMessage);
        return false;
    }
    
}

- (BOOL) stopPlayingAudio: (NSString *) errorMessage {
    NSLog(@"Stop audio playing at %@", _audioFilePath);
    
    if (myPlayer) {
        [myPlayer stop];
        return true;
    } else {
        errorMessage = @"Cannot stop audio playing due to player not set up properly";
        NSLog(@"%@", errorMessage);
        return  false;
    }
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Audio file at %@ has played successfully", _audioFilePath);
}

- (void) standerErrorHandler: (NSError *)err withMessage:(NSString *) message {
    NSLog(@"%@ got an error: %@ %ld %@", message, [err domain], (long)[err code], [[err userInfo] description]);
}

@end

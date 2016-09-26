//
//  MyAudioRecorderAndPlayer.m
//  AudioService
//
//  Created by Jupiter Li on 9/08/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioRecorderAndPlayer.h"

@interface MyAudioRecorderAndPlayer() {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
    AVAudioSession *session;
}

@end

@implementation MyAudioRecorderAndPlayer

- (id) init {
    NSLog(@"Init a MyAudioRecorderAndPlayer");
    
    self = [super init];
    
    NSError *err;
    
    // setup audio session
    session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&err];
    if (err) {
        [self standerErrorHandler: err withMessage: @"Init MyAudioRecorderAndPlayer"];
    }
    err = nil;
    
    NSMutableDictionary *recordingSetting = [[NSMutableDictionary alloc] init];
    [recordingSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordingSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordingSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:[self getRecordFileUrl]] settings:recordingSetting error:&err];
    if (err) {
        [self standerErrorHandler: err withMessage: @"Init recorder"];
    } else {
        [recorder prepareToRecord];
    }
    err = nil;
    
    return self;
}

- (void) standerErrorHandler: (NSError *)err withMessage:(NSString *) message {
    NSLog(@"%@ got an error: %@ %ld %@", message, [err domain], (long)[err code], [[err userInfo] description]);
}

- (NSString *) getRecordFileUrl {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"record.m4a"];
}

@end

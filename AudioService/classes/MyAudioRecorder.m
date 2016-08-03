//
//  MyAudioRecorder.m
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioRecorder.h"

@implementation MyAudioRecorder

/**
 *
 * Init this audio reocrder with default setting
 *  recorde audio in linearPCM
 *
 */
- (id) init {
    NSLog(@"Create a MyAudioRecorder instance with default setting, linearPCM.");
    
    self = [super init];
    
    // default audio parameters
    [self setUpDefaultAudioFormatParameter];
    
    encdoeFormat = ENC_PCM;
    
    _audioFilePath = [NSString stringWithFormat: @"%@%@", [self getDeviceDocumentDirectory], [self generateARondomAudioFilename]];
    
    // error handler
    NSError *err;
    
    // set up session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error: &err];
    if (err) {
        [self standerErrorHandler: err withMessage:@"Audio recorder set audio session category"];
    }
    err = nil;
    
    // define recorder settings
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    [recordSettings setObject:[NSNumber numberWithFloat: _SAMPLE_RATE] forKey: AVSampleRateKey];
    [recordSettings setObject:[NSNumber numberWithInt: _NUMBER_OF_CHANNELS] forKey: AVNumberOfChannelsKey];
    [recordSettings setObject:[NSNumber numberWithInt: _ENCODING_BIT] forKey: AVLinearPCMBitDepthKey];
    [recordSettings setObject:[NSNumber numberWithBool: NO] forKey: AVLinearPCMIsBigEndianKey];
    [recordSettings setObject:[NSNumber numberWithBool: NO] forKey: AVLinearPCMIsFloatKey];
    
    // init and prepare the recorder
    myRocorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath: _audioFilePath] settings: recordSettings error: &err];
    if (err) {
        [self standerErrorHandler: err withMessage: @"Init audio recorder"];
    }
    err = nil;
    
    myRocorder.delegate = self;
    myRocorder.meteringEnabled = true;
    [myRocorder prepareToRecord];
    
    return self;
}

/** TODO
 *
 * Not implement yet
 *
 */
- (id) initWithFormat: (int) encodeFormat {
    self = [super init];
    
    
    
    return self;
}

/** TODO
 *
 * Not implement yet
 *
 */
- (BOOL) setEncodeFormat:(int) encodeFormat {
    return true;
}

/** TODO
 *
 * Not implement yet
 *
 */
- (BOOL) setAudioFilePath:(NSString *) encodeFormat {
    return true;
}

- (BOOL) startRecord: (NSString *) errorMessage {
    NSLog(@"Start to record");
    
    NSError *err;
    
    bool res = true;
    
    if (!myRocorder.recording) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive: YES error: &err];
        
        if (err) {
            [self standerErrorHandler: err withMessage: @"Start to record set audio session active"];
            
            res = false;
            errorMessage = @"Set session active failed";
        }
        err = nil;
        
        //start recording
        [myRocorder record];
    } else {
        errorMessage = @"Another audio recording session in processing";
        NSLog(@"Another audio recording session in processing");
        
        res = false;
    }
    
    return res;
}
- (BOOL) stopRecord: (NSString *) errorMessage {
    NSLog(@"Stop recording");
    
    NSError *err;
    
    bool res = true;
    
    if (myRocorder.recording) {
        // stop recording
        [myRocorder stop];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive: NO error: &err];
        
        if (err) {
            [self standerErrorHandler: err withMessage: @"Stop audio recording set off audio session active"];
            
            res = false;
            errorMessage = @"Set off audio session active failed";
        }
        err = nil;
    } else {
        res = false;
        errorMessage = @"Recording has not started yet, cannot stop it";
        NSLog(@"Recording has not started yet, cannot stop it");
    }
    
    return res;
}

- (BOOL) deleteRecording {
    NSLog(@"Delete the recorded file");
    
    return [myRocorder deleteRecording];
}

- (NSString *) getRecordFilePath {
    return _audioFilePath;
}

- (NSString *) generateARondomAudioFilename {
    NSString *res = [[NSUUID UUID] UUIDString];
    
    switch (encdoeFormat) {
        case ENC_PCM:
            res = [res stringByAppendingString: @".caf"];
            break;
            
        default:
            break;
    }
    
    return res;
}

- (NSString *) getDeviceDocumentDirectory {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString: @"/"];
}

- (void) standerErrorHandler: (NSError *)err withMessage:(NSString *) message {
    NSLog(@"%@ got an error: %@ %ld %@", message, [err domain], (long)[err code], [[err userInfo] description]);
}

- (void) setUpDefaultAudioFormatParameter{
    _SAMPLE_RATE = 44100.0;
    _NUMBER_OF_CHANNELS = 2;
    _ENCODING_BIT = 16;
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"Recording has done");
}

@end





























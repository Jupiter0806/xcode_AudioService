//
//  MyAudioRecorder.h
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//
//  This class can record any supported audio.
//
//  For now, one instance can only record an audio in the only one audio file, in other words, the file path cannot change
//      this will be improve later.
//
//  initWithFormat and setEncodeFormat are not implemented yet.
//
//  No test yet.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MyAudioRecorder : NSObject <AVAudioRecorderDelegate> {
    AVAudioRecorder *myRocorder;
    
    int encdoeFormat;
    
    enum {
        ENC_AAC = 1,
        ENC_ALAC = 2,
        ENC_IMA4 = 3,
        ENC_ILBC = 4,
        ENC_ULAW = 5,
        ENC_PCM = 6,
    } encodingTypes;
}

@property (readonly) float SAMPLE_RATE;
@property (readonly) int NUMBER_OF_CHANNELS;
@property (readonly) int ENCODING_BIT;
@property (readonly) NSString *audioFilePath;


// Construct function

/**
 *
 * Init this audio reocrder with default setting
 *  recorde audio in linearPCM
 *
 */
- (id) init;

/** TODO
 *
 * Not implement yet
 *
 */
- (id) initWithFormat: (int) encodeFormat;

// functions

/** TODO
 *
 * Not implement yet
 *
 */
- (BOOL) setEncodeFormat:(int) encodeFormat;

/** TODO
 *
 * Not implement yet
 *
 */
- (BOOL) setAudioFilePath:(NSString *) encodeFormat;

/**
 *
 * Start to record an audio using the setting setup in init.
 * 
 * Return true of false to indicate sucess of fail. If fail errorMessage will contain a message.
 *
 */
- (BOOL) startRecord: (NSString *) errorMessage;

/**
 *
 * Stop recording the audio.
 *
 * Return true of false to indicate sucess of fail. If fail errorMessage will contain a message.
 *
 */
- (BOOL) stopRecord: (NSString *) errorMessage;

/**
 *
 * Return the record file path.
 *
 * Also can get from the instance property
 *
 */
- (NSString *) getRecordFilePath;

/**
 *
 * Delete the recorded audio file
 *
 * Return true of false to indicate sucess of fail.
 *
 */
- (BOOL) deleteRecording;
@end

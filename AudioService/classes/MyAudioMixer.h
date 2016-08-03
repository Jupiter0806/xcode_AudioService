//
//  MyAudioMixer.h
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//
//
//  convert code from project Mix2Files-master, download from internet
//
//  Now can convert all supported audio files to caf or aiff(not test yet) with parameters of
//      sample rate: 44100.0
//      linear pcm
//      channels: 2
//      bit: 16

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <unistd.h>

#import "MyAudioMixerInstructionsParser.h"

@interface MyAudioMixer : NSObject

+ (OSStatus) mix: (NSString *)file1 file2: (NSString*)file2 offset: (int)offset mixfile: (NSString *)mixfile;
+ (OSStatus) mix: (NSString*)file1 file2:(NSString*)file2 offset:(int)offset mixfile:(NSString*)mixfile bgmMix:(BOOL) bgmMix;

+ (OSStatus) mixFiles: (NSArray *)files atTimes: (NSArray *)times toMixfile: (NSString *)mixfile;

+ (OSStatus) complexMixFilesWithInstructions: (NSString *)instructions voiceFileUrl:(NSString *)voiceFileUrl mixFileUrl:(NSString *)mixFileUrl;

@end

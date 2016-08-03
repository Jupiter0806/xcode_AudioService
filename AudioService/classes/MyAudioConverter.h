//
//  MyAudioConverter.h
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
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

@interface MyAudioConverter : NSObject

typedef struct MyAudioConverterSettings
{
    // output file's data stream description
    AudioStreamBasicDescription outputFormat;
    
    // reference to your input file
    ExtAudioFileRef inputFile;
    
    // refrence to your output file
    AudioFileID outputFile;
    
} MyAudioConverterSettings;


+ (BOOL) convertFiles: (NSArray *)filesIn toFiles: (NSArray *)filesOut;
+ (BOOL) convertFile: (NSString *)fileIn toFile: (NSString *)fileOut;

@end

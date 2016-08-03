//
//  MyAudioConverter.m
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//


#import "MyAudioConverter.h"

@implementation MyAudioConverter

// generic error handler - if result is nonzero, prints error message and exits program.
static void checkResult(OSStatus result, const char * opration) {
    if (result == noErr) {
        return;
    }
    
    char errorString[20];
    
    // see if it appears to be a 4-char-code
    //  *(UInt32 *)(errorString + 1) is the content at errorString[1] and cast it to UInt32 pointer
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    }
    
    NSLog(@"Error: %s (%s)", opration, errorString);
    
    exit(1);
}

void convert(MyAudioConverterSettings * myAudioConverterSettings) {
    
    // 32 KB is a good starting point
    //  why????
    UInt32 outputBufferSize = 32 * 1024;
    UInt32 sizePerPacket = myAudioConverterSettings->outputFormat.mBytesPerPacket;
    UInt32 packetsPerBuffer = outputBufferSize / sizePerPacket;
    
    // allocate destination buffer
    UInt8 *outputBuffer = (UInt8 *) malloc(sizeof(UInt8) * outputBufferSize);
    
    UInt32 outputFilePacketPosition = 0;
    
    while (true) {
        // wrap the destination buffer in an AudioBufferList
        AudioBufferList convertedData;
        convertedData.mNumberBuffers = 1;
        convertedData.mBuffers[0].mNumberChannels = myAudioConverterSettings->outputFormat.mChannelsPerFrame;
        convertedData.mBuffers[0].mDataByteSize = outputBufferSize;
        convertedData.mBuffers[0].mData = outputBuffer;
        
        UInt32 frameCount = packetsPerBuffer;
        
        // read from extaudiofile
        checkResult(ExtAudioFileRead(myAudioConverterSettings->inputFile, &frameCount, &convertedData), "Couldn't read from input file");
        
        if (frameCount == 0) {
            NSLog(@"Done reading from file");
            return;
        }
        
        // write the converted data to the output file
        checkResult( AudioFileWritePackets(myAudioConverterSettings->outputFile, false, frameCount, NULL, outputFilePacketPosition / myAudioConverterSettings->outputFormat.mBytesPerPacket, &frameCount, convertedData.mBuffers[0].mData), "Couldn't write packets to file");
        
        // advance the output file write location
        outputFilePacketPosition += (frameCount * myAudioConverterSettings->outputFormat.mBytesPerPacket);
    }
}

+ (BOOL) convertFile: (NSString *)fileIn toFile: (NSString *)fileOut {
    MyAudioConverterSettings audioConverterSettings = {0};
    
    // open the input with ExAudioFile
    CFURLRef inputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileIn,kCFURLPOSIXPathStyle, false);
    
    checkResult(ExtAudioFileOpenURL(inputFileURL, &audioConverterSettings.inputFile), "ExAudioFileOpenURL failed");
    
    CFRelease(inputFileURL);
    
    if ([fileOut rangeOfString: @".aiff"].location != NSNotFound) {
        // define the output format. AudioConverter requires that one of the data formats be linear PCM
        audioConverterSettings.outputFormat.mSampleRate = 44100.0;
        audioConverterSettings.outputFormat.mFormatID = kAudioFormatLinearPCM;
        audioConverterSettings.outputFormat.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioConverterSettings.outputFormat.mBytesPerPacket = 4;
        audioConverterSettings.outputFormat.mFramesPerPacket = 1;
        audioConverterSettings.outputFormat.mBytesPerFrame = 4;
        audioConverterSettings.outputFormat.mChannelsPerFrame = 2;
        audioConverterSettings.outputFormat.mBitsPerChannel = 16;
        
        // create output file
        CFURLRef outputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileOut, kCFURLPOSIXPathStyle, false);
        
        checkResult(AudioFileCreateWithURL(outputFileURL, kAudioFileAIFFType, &audioConverterSettings.outputFormat, kAudioFileFlags_EraseFile, &audioConverterSettings.outputFile), "AudioFileCreateWithURL failed");
        
        CFRelease(outputFileURL);
    } else if ([fileOut rangeOfString: @".caf"].location != NSNotFound) {
        // define the outpur format. AudioConverter requires that one of the data formats be linear PCM
        audioConverterSettings.outputFormat.mSampleRate = 44100.0;
        audioConverterSettings.outputFormat.mFormatID = kAudioFormatLinearPCM;
        // kAudioFormatFlagsCanonical = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked
        audioConverterSettings.outputFormat.mFormatFlags = kAudioFormatFlagsCanonical;
        audioConverterSettings.outputFormat.mBytesPerPacket = 4;
        audioConverterSettings.outputFormat.mFramesPerPacket = 1;
        audioConverterSettings.outputFormat.mBytesPerFrame = 4;
        audioConverterSettings.outputFormat.mChannelsPerFrame = 2;
        audioConverterSettings.outputFormat.mBitsPerChannel = 16;
        
        // create output file
        CFURLRef outputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fileOut, kCFURLPOSIXPathStyle, false);
        checkResult(AudioFileCreateWithURL(outputFileURL, kAudioFileCAFType, &audioConverterSettings.outputFormat, kAudioFileFlags_EraseFile, &audioConverterSettings.outputFile), "AudioFileCreateWithURL failed");
        
        CFRelease(outputFileURL);
    }
    
    // set the pcm format  as the client format on the input ext audio file
    checkResult(ExtAudioFileSetProperty(audioConverterSettings.inputFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       sizeof (AudioStreamBasicDescription),
                                       &audioConverterSettings.outputFormat),
               "Couldn't set client data format on input ext file");
    
    NSLog(@"Convering...");
    convert(&audioConverterSettings);
    
cleanup:
    ExtAudioFileDispose(audioConverterSettings.inputFile);
    AudioFileClose(audioConverterSettings.outputFile);
    return YES;
}

+ (BOOL) convertFiles: (NSArray *)filesIn toFiles: (NSArray *)filesOut {
    [filesIn enumerateObjectsUsingBlock:^(NSString *fileIn, NSUInteger idx, BOOL *stop) {
        [self convertFile:fileIn toFile:[filesOut objectAtIndex:idx]];
    }];
    
    return YES;
}

@end





















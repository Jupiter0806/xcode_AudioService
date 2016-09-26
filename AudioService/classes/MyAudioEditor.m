//
//  MyAudioEditor.m
//  AudioService
//
//  Created by Jupiter Li on 26/09/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import "MyAudioEditor.h"

@implementation MyAudioEditor

+ (void) _setDefaultAudioFormatFlags: (AudioStreamBasicDescription *)audioForamtPtr numChannels: (NSUInteger)numChannels {
    NSLog(@"Set up default audio format flags");

    // set all memory for inputDataFromat to 0
    bzero(audioForamtPtr, sizeof(AudioStreamBasicDescription));

    audioForamtPtr->mFormatID = kAudioFormatLinearPCM;
    audioForamtPtr->mSampleRate = 44100.0;
    audioForamtPtr->mChannelsPerFrame = numChannels;
    audioForamtPtr->mBytesPerPacket = 2 * numChannels;
    audioForamtPtr->mFramesPerPacket = 1;
    audioForamtPtr->mBytesPerFrame = 2 * numChannels;
    audioForamtPtr->mBitsPerChannel = 16;
    audioForamtPtr->mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
}

+ (bool) cutAudioWithInstructions:(NSString *)audioUrl instructions: (MyAudioEditorInstructionParser *)instructions outputFileUrl : (NSString *) outputFileUrl{
    bool res = true;
    
    NSLog(@"Cut audio with instructions.");

    OSStatus status, closeStatus;

    NSURL *audioNSUrl = [NSURL fileURLWithPath:audioUrl];
    NSURL *outputFileNSUrl = [NSURL fileURLWithPath:outputFileUrl];
    
    AudioFileID audioFile = NULL;
    AudioFileID outputFile = NULL;

#ifndef TARGET_OS_IPHONE
    // why is this constant missing under Mac OS X?
#define kAudioFileReadPermission fsRdPerm
#endif

#define BUFFER_SIZE 1764 // to read 441 packets
    char *audioFileBuffer = NULL;
    char *outputFileBuffer = NULL;

    status = AudioFileOpenURL((__bridge CFURLRef)audioNSUrl, kAudioFileReadPermission, 0, &audioFile);
    if (status) {
        NSLog(@"ERROR: Open file at %@ failed", audioUrl);
        goto reterr;
    }

    // verify that file contains pcm data at 44kHz

    AudioStreamBasicDescription audioFileFormat;
    UInt32 propSize = sizeof(audioFileFormat);

    // set all memory for audioFileFormat to 0
    bzero(&audioFileFormat, sizeof(audioFileFormat)); // the reason does not user propSize is that it will be passed to AudioFileGetProperty as reference

    status = AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
    if (status) {
        NSLog(@"Error: get audio file format failed.");
        goto reterr;
    }

    if ((audioFileFormat.mFormatID == kAudioFormatLinearPCM) &&
            (audioFileFormat.mSampleRate == 44100.0) &&
            (audioFileFormat.mChannelsPerFrame == 2) &&
            (audioFileFormat.mBitsPerChannel == 16)) {
        NSLog(@"Audio file format is correct.");
    } else {
        status = kAudioFileUnsupportedFileTypeError;
        NSLog(@"Error: audio file format is incorrect.");
    }

    // open output file
    AudioStreamBasicDescription outputDataFormat;
    bzero(&outputDataFormat, sizeof(outputDataFormat));
    [self _setDefaultAudioFormatFlags:&outputDataFormat numChannels:2];
    status = AudioFileCreateWithURL((__bridge CFURLRef)outputFileNSUrl, kAudioFileCAFType, &outputDataFormat, kAudioFileFlags_EraseFile, &outputFile);

    // Read buffer of data from each file

    audioFileBuffer = malloc(BUFFER_SIZE);
    assert(audioFileBuffer);
    outputFileBuffer = malloc(BUFFER_SIZE);
    assert(outputFileBuffer);

    SInt64 audioFilePacketNumber = 0;
    SInt64 outputFilePacketNumber = 0;

    int PACKETS_PER_10MS = audioFileFormat.mSampleRate / audioFileFormat.mFramesPerPacket / 100;

    while (true) {
        // read a chunk of input

        UInt32 audioFileByteRead = 0;
        UInt32 audioFileNumberPacketsRead = 0;

        // read packets from audio file

        // number of packets about to read
        audioFileNumberPacketsRead = BUFFER_SIZE / audioFileFormat.mBytesPerPacket;
        status = AudioFileReadPackets(audioFile, false, &audioFileByteRead, NULL, audioFilePacketNumber, &audioFileNumberPacketsRead, audioFileBuffer);
        if (status) {
            NSLog(@"Read file1 packets failed at packet number: %lld", audioFilePacketNumber);
            goto reterr;
        }

        // if buffer was not filled, file with zeros
        //  buffer1 + bytesRead1 means &(buffer1[bytesRead1])
        if (audioFileByteRead < BUFFER_SIZE) {
            bzero(audioFileBuffer + audioFileByteRead, (BUFFER_SIZE - audioFileByteRead));
        }

        audioFilePacketNumber += audioFileNumberPacketsRead;

        if ([instructions ifNeedSkipAt:(int)(audioFilePacketNumber / PACKETS_PER_10MS)]) {

        } else {
            outputFileBuffer = audioFileBuffer;

            UInt32 packetsWritten = audioFileNumberPacketsRead;
            status = AudioFileWritePackets(outputFile, false, (audioFileNumberPacketsRead * outputDataFormat.mBytesPerPacket), NULL, outputFilePacketNumber, &packetsWritten, outputFileBuffer);

            if (status) {
                NSLog(@"Write to output file failed at packet number: %lld", outputFilePacketNumber);
                goto reterr;
            }

            if (packetsWritten != audioFileNumberPacketsRead) {
                status = kAudioFileInvalidPacketOffsetError;
                NSLog(@"Write to output file failed, not all packets write to file");
                goto reterr;
            }

            outputFilePacketNumber += packetsWritten;
        }

    }

reterr:
    if (audioFile != NULL) {
        closeStatus = AudioFileClose(audioFile);
        assert(closeStatus == 0);
    }
    if (outputFile != NULL) {
        closeStatus = AudioFileClose(outputFile);
        assert(closeStatus == 0);
    }
    if (audioFileBuffer != NULL) {
        free(audioFileBuffer);
    }
    if (outputFileBuffer != NULL) {
        free(outputFileBuffer);
    }

    return res;
}

@end

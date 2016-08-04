//
//  MyAudioMixer.m
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

// basic terms of audio
// sample rate: how may frames of an audio has
// frame: 是一整段波形
// packet: only in terms of Objective-c which is defined in AudioStreamBasicDescription

#import "MyAudioMixer.h"

#define MAX_BGMS 40

static inline void mix_buffers(const int16_t *buffer1,
                               const int16_t *buffer2,
                               int16_t *mixbuffer,
                               int mixbufferNumSamples,
                               BOOL shouldSwap)
{
    for (int i = 0; i < mixbufferNumSamples; i++) {
        int16_t s1 = buffer1[i];
        
        int16_t s2;
        if (shouldSwap) {
            s2 = (buffer2[i] << 8) | (buffer2[i] >> 8);
        } else {
            s2 = buffer2[i];
        }
        
        int16_t mixed;
        
        if (s1 < 0 && s2 < 0) {
            mixed = (s1 + s2) - ((s1 * s2) / INT16_MIN);
        } else if (s1 > 0 && s2 > 0) {
            mixed = (s1 + s2) - ((s1 * s2) / INT16_MAX);
        } else {
            mixed = s1 + s2;
        }
        
        mixbuffer[i] = mixed;
    }
}

static inline void mix_buffers_volumeControl(const int16_t *buffer1,
                                             const int16_t *buffer2,
                                             const int16_t volumeLevel,
                                             int16_t *mixbuffer,
                                             int mixbufferNumSamples,
                                             BOOL shouldSwap)
{
    for (int i = 0; i < mixbufferNumSamples; i++) {
        int16_t s1 = buffer1[i];
        
        int16_t s2;
        if (shouldSwap) {
            s2 = (buffer2[i] << 8) | (buffer2[i] >> 8);
        } else {
            s2 = buffer2[i];
        }
        
        // volume controle
        // less than 100 sound attenuation
        // greater than 100 sould gain
        int16_t s2_gained = s2 * (volumeLevel / 100);
        if (s2_gained > INT16_MAX) {
            s2 = INT16_MAX;
        } else if (s2_gained < INT16_MIN) {
            s2 = INT16_MIN;
        } else {
            s2 = s2_gained;
        }
        
        int16_t mixed;
        
        if (s1 < 0 && s2 < 0) {
            mixed = (s1 + s2) - ((s1 * s2) / INT16_MIN);
        } else if (s1 > 0 && s2 > 0) {
            mixed = (s1 + s2) - ((s1 * s2) / INT16_MAX);
        } else {
            mixed = s1 + s2;
        }
        
        mixbuffer[i] = mixed;
    }
}

@implementation MyAudioMixer

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

+ (OSStatus) mix:(NSString*)file1 file2:(NSString*)file2 offset:(int)offset mixfile:(NSString*)mixfile{
    return [self mix:file1 file2:file2 offset:offset mixfile:mixfile bgmMix:false];
}

// bgmMix means this will not be a fully mix, file1 will be the voice, and file2 will be the bgm. bgm will be repeat until
//  voice is done, on the other hand if voice is done before bgm, stop mix immediatelly
+ (OSStatus) mix:(NSString*)file1 file2:(NSString*)file2 offset:(int)offset mixfile:(NSString*)mixfile bgmMix:(BOOL) bgmMix {
    NSLog(@"Start to mix \n \b file1: %@ \n \b and file2: %@", file1, file2);
    
    OSStatus status, close_status;
    
    NSURL *url1 = [NSURL fileURLWithPath:file1];
    NSURL *url2 = [NSURL fileURLWithPath:file2];
    NSURL *mixURL = [NSURL fileURLWithPath:mixfile];
    
    AudioFileID inAudioFile1 = NULL;
    AudioFileID inAudioFile2 = NULL;
    AudioFileID mixAudioFile = NULL;
    
#ifndef TARGET_OS_IPHONE
    // why is this constant missing under Mac OS X?
#define kAudioFileReadPermission fsRdPerm
#endif
    
#define BUFFER_SIZE 882 // to read 441 packets
    char *buffer1 = NULL;
    char *buffer2 = NULL;
    char *mixbuffer = NULL;
    
    status = AudioFileOpenURL((__bridge CFURLRef)url1, kAudioFileReadPermission, 0, &inAudioFile1);
    if (status) {
        NSLog(@"ERROR: Open file at %@ failed", file1);
        goto reterr;
    }
    
    status = AudioFileOpenURL((__bridge CFURLRef)url2, kAudioFileReadPermission, 0, &inAudioFile2);
    if (status) {
        NSLog(@"ERROR: Open file at %@ failed", file2);
        goto reterr;
    }
    
    // verify that file contains pcm data at 44kHz
    
    AudioStreamBasicDescription inputDataFormat1;
    UInt32 propSize = sizeof(inputDataFormat1);
    
    // set all memory for inputDataFromat to 0
    bzero(&inputDataFormat1, sizeof(inputDataFormat1));
    
    status = AudioFileGetProperty(inAudioFile1, kAudioFilePropertyDataFormat, &propSize, &inputDataFormat1);
    if (status) {
        goto reterr;
    }
    
    // In this case, the input audio file as file1 is the record audio file, which means will never be big endian, unless I changed the recording parmeters
    BOOL isFile1BigEndian = NO;
    
    if ((inputDataFormat1.mFormatID == kAudioFormatLinearPCM) &&
        (inputDataFormat1.mSampleRate == 44100.0) &&
        (inputDataFormat1.mChannelsPerFrame == 2) &&
        (inputDataFormat1.mBitsPerChannel == 16)) {
        
        if (inputDataFormat1.mFormatFlags == (kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger)) {
            NSLog(@"File1's format is correct, at %@ ", file1);
        } else {
            if ((inputDataFormat1.mFormatFlags & kAudioFormatFlagIsBigEndian) == kAudioFormatFlagIsBigEndian) {
                NSLog(@"File1's format is a big endian, at %@ ", file1);
                isFile1BigEndian = YES;
            } else {
                status = kAudioFileUnsupportedFileTypeError;
                NSLog(@"File1's format is incorrect, at %@", file1);
                goto reterr;
            }
        }
    } else {
        status = kAudioFileUnsupportedFileTypeError;
        NSLog(@"File1's format is incorrect, at %@", file1);
        goto reterr;
    }
    
    // do the same for file2
    
    AudioStreamBasicDescription inputDataFormat2;
    UInt32 propSize2 = sizeof(inputDataFormat2);
    
    bzero(&inputDataFormat2, propSize);
    
    status = AudioFileGetProperty(inAudioFile2, kAudioFilePropertyDataFormat, &propSize2, &inputDataFormat2);
    if (status) {
        goto reterr;
    }
    
    BOOL isFile2BigEndian = NO;
    
    if ((inputDataFormat2.mFormatID == kAudioFormatLinearPCM) &&
        (inputDataFormat2.mSampleRate == 44100.0) &&
        (inputDataFormat2.mChannelsPerFrame == 2) &&
        (inputDataFormat2.mBitsPerChannel == 16)) {
        
        if (inputDataFormat2.mFormatFlags == (kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger)) {
            NSLog(@"File2 is in correct format, at %@", file2);
        } else {
            if ((inputDataFormat2.mFormatFlags & kAudioFormatFlagIsBigEndian) == kAudioFormatFlagIsBigEndian) {
                NSLog(@"File2 is a big endian, at %@", file2);
                
                isFile2BigEndian = YES;
            } else {
                NSLog(@"File2 is in incorrect format, at %@", file2);
                
                status = kAudioFileUnsupportedDataFormatError;
                goto reterr;
            }
        }
    } else {
        NSLog(@"File2 is in incorrect format, at %@", file2);
        
        status = kAudioFileUnsupportedDataFormatError;
        goto reterr;
    }
    
    // Both input files validated, open output (mix) file
    
    AudioStreamBasicDescription outpurDataFormat;
    bzero(&outpurDataFormat, sizeof(outpurDataFormat));
    [self _setDefaultAudioFormatFlags:&outpurDataFormat numChannels:2];
    status = AudioFileCreateWithURL((__bridge CFURLRef)mixURL, kAudioFileCAFType, &outpurDataFormat, kAudioFileFlags_EraseFile, &mixAudioFile);
    
    // Read buffer of data from each file
    
    buffer1 = malloc(BUFFER_SIZE);
    assert(buffer1);
    buffer2 = malloc(BUFFER_SIZE);
    assert(buffer2);
    mixbuffer = malloc(BUFFER_SIZE);
    assert(mixbuffer);
    
    SInt64 packetNum1 = 0;
    SInt64 packetNum2 = 0;
    SInt64 mixpacketNum = 0;
    
    while (true) {
        // read a chunk of input
        
        UInt32 bytesRead1 = 0;
        UInt32 bytesRead2 = 0;
        UInt32 numPackets1 = 0;
        UInt32 numPackets2 = 0;
        
        // read a packet from file1
        
        // number of packets about to read
        numPackets1 = BUFFER_SIZE / outpurDataFormat.mBytesPerPacket;
        status = AudioFileReadPackets(inAudioFile1, false, &bytesRead1, NULL, packetNum1, &numPackets1, buffer1);
        if (status) {
            NSLog(@"Read file1 packets failed at packet number: %lld", packetNum1);
            goto reterr;
        }
        
        // if buffer was not filled, file with zeros
        //  buffer1 + bytesRead1 means &(buffer1[bytesRead1])
        if (bytesRead1 < BUFFER_SIZE) {
            bzero(buffer1 + bytesRead1, (BUFFER_SIZE - bytesRead1));
        }
        
        packetNum1 += numPackets1;
        
        // to control file2 start position
        if (mixpacketNum > offset * BUFFER_SIZE) {
            // number of packet about to read
            numPackets2 = BUFFER_SIZE / outpurDataFormat.mBytesPerPacket;
            
            status = AudioFileReadPackets(inAudioFile2, false, &bytesRead2, NULL, packetNum2, &numPackets2, buffer2);
            if (status) {
                NSLog(@"Read file2 packet failed at packt number: %lld", packetNum2);
                goto reterr;
            }
        } else {
            // file2 should not start to mix yet.
            bytesRead2 = 0;
        }
        
        // if buffer2 was not filled, file it with zeros
        if (bytesRead2 < BUFFER_SIZE) {
            if (bgmMix) {
                packetNum2 = 0;
                numPackets2 = (BUFFER_SIZE / outpurDataFormat.mBytesPerPacket) - numPackets2;
                
                // buffer2 now may have some data, if i just pass buffer2 to get data, then previous data will be override
                char *temp_buffer2 = NULL;
                temp_buffer2 = malloc(BUFFER_SIZE);
                assert(temp_buffer2);
                
                UInt32 temp_byteRead2 = 0;
                
                // fill buffer2
                status = AudioFileReadPackets(inAudioFile2, false, &temp_byteRead2, NULL, packetNum2, &numPackets2, temp_buffer2);
                if (status) {
                    NSLog(@"Read file2 packet failed at packt number: %lld", packetNum2);
                    goto reterr;
                } else {
                    for (UInt32 i = bytesRead2; i < BUFFER_SIZE; i++) {
                        buffer2[i] = temp_buffer2[i - bytesRead2];
                    }
                    
                    // since data has been read twice, the value in numPackets2 is only for sencond read
                    //  so re-calculate it
                    numPackets2 = (bytesRead2 + temp_byteRead2) / outpurDataFormat.mBytesPerPacket;
                }
                
            } else {
                bzero(buffer2 + bytesRead2, (BUFFER_SIZE - bytesRead2));
            }
        }
        packetNum2 += numPackets2;
        
        // This is mixxing voice with bgm, so it has different control
        if (bgmMix) {
            if (numPackets1 == 0) {
                NSLog(@"Voice audio file meets its end, stop mix");
                break;
            } else if (numPackets2 == 0) {
                // should never be ran
                NSLog(@"Bgm audio file meets its end, load it from the beginning");
                
                packetNum2 = 0;
                
            }
        } else {
            // If no frames were returned, conversion is finished
            //  numPackets1 == 0 and numPackets2 == 0 means no packets read from file1 and file2
            //  packetNum2 > 0 means did read packets from file2, in other words, it used to control mix file2 when file1 at a specific position and then file1 has no fream returned, but file2 still got more data.
            // Used to control the length of outpur audio file
            if (numPackets1 == 0 && numPackets2 == 0 && packetNum2 > 0) {
                break;
            }
        }
        
        
        // Write pcm data to outpur file
        
        // handle when buffer did not fully filled
        int maxNumPackets;
        if (numPackets1 > numPackets2) {
            maxNumPackets = numPackets1;
        } else if (numPackets1 == 0 && numPackets2 == 0) {
            maxNumPackets = 1;
        } else {
            maxNumPackets = numPackets2;
        }
        
        int numSamples = (maxNumPackets * outpurDataFormat.mBytesPerPacket) / sizeof(int16_t);
        
        
        // if is file1 big endian does not equal is file 2 big endian, then file1 and file2 are not in the
        //  same encode, change file2 to file1's encode
        mix_buffers((const int16_t *)buffer1, (const int16_t *)buffer2,
                                    (int16_t *) mixbuffer, numSamples, !(isFile1BigEndian == isFile2BigEndian));
        // write the mixed packets to the output file
        UInt32 packetsWritten = maxNumPackets;
        status = AudioFileWritePackets(mixAudioFile, false, (maxNumPackets * outpurDataFormat.mBytesPerPacket), NULL, mixpacketNum, &packetsWritten, mixbuffer);
        if (status) {
            NSLog(@"Write to output file failed at packet number: %lld", mixpacketNum);
            goto reterr;
        }
        
        if (packetsWritten != maxNumPackets) {
            status = kAudioFileInvalidPacketOffsetError;
            NSLog(@"Write to outpur file failed, not all packets write to file");
            goto reterr;
        }
        
        mixpacketNum += packetsWritten;
    }
    
    
reterr:
    if (inAudioFile1 != NULL) {
        close_status = AudioFileClose(inAudioFile1);
        assert(close_status == 0);
    }
    if (inAudioFile2 != NULL) {
        close_status = AudioFileClose(inAudioFile2);
        assert(close_status == 0);
    }
    if (mixAudioFile != NULL) {
        close_status = AudioFileClose(mixAudioFile);
        assert(close_status == 0);
    }
    if (buffer1 != NULL) {
        free(buffer1);
    }
    if (buffer2 != NULL) {
        free(buffer2);
    }
    if (mixbuffer != NULL) {
        free(mixbuffer);
    }
    
    return status;
}

+ (OSStatus) complexMixFilesWithInstructions: (NSString *)instructions_json_str voiceFileUrl:(NSString *)voiceFileUrl mixFileUrl:(NSString *)mixFileUrl {
    NSLog(@"Mix files under instructions.");
    
    MyAudioMixerInstructionsParser *instructions = [[MyAudioMixerInstructionsParser alloc] initWithAudioMixerInstructionsJSON:instructions_json_str];
    
    OSStatus status, close_status;
    
    // setup NSURL for read or write audio files
    NSArray *bgmFileUrls = [instructions bgmsFileUrl];
    NSMutableArray *bgmFileUrls_nsurl = [[NSMutableArray alloc] init];
    for (int i = 0; i < [bgmFileUrls count]; i++) {
        [bgmFileUrls_nsurl addObject:[NSURL fileURLWithPath:[bgmFileUrls objectAtIndex:i]]];
    }
    
    NSURL *voiceFileUrl_nsurl = [NSURL fileURLWithPath:voiceFileUrl];
    NSURL *mixFileUrl_nsurl = [NSURL fileURLWithPath:mixFileUrl];
   
    // should put all variable declaration before goto instruction
#ifndef TARGET_OS_IPHONE
    // why is this constant missing under Mac OS X?
#define kAudioFileReadPermission fsRdPerm
#endif
    
#define BUFFER_SIZE 1764
    char *voicebuffer = NULL;
    char *bgmbuffer = NULL; // for all bgm, once only one bgm use
    char *mixbuffer = NULL;
    
    // setup AudioFileID
    
    // put all AudioFileID declare together is to ensure all initialised properly
    AudioFileID bgmAudioFiles[MAX_BGMS] = {NULL};
    AudioFileID voiceAudioFile = NULL;
    AudioFileID mixAudioFile = NULL;
    
    for (int i = 0; i < [bgmFileUrls count]; i++) {
        AudioFileID tempAudioFileID = NULL;
        
        status = AudioFileOpenURL((__bridge CFURLRef)[bgmFileUrls_nsurl objectAtIndex:i], kAudioFileReadPermission, 0, &tempAudioFileID);
        if (status) {
            NSLog(@"ERROR: Open file at %@ failed.", [bgmFileUrls objectAtIndex:i]);
            goto reterr;
        }
        
        bgmAudioFiles[i] = tempAudioFileID;

    }

    status = AudioFileOpenURL((__bridge CFURLRef)voiceFileUrl_nsurl, kAudioFileReadPermission, 0, &voiceAudioFile);
    if (status) {
        NSLog(@"ERROR: Open file at %@ failed.", voiceFileUrl);
        goto reterr;
    }
    
    // verify these files containt pcm data at 44khz
    
    // voice file
    AudioStreamBasicDescription voiceDataFormat;
    UInt32 proSize = sizeof(voiceDataFormat); // this value used by voice file and bgm files basic description
    // initialise
    bzero(&voiceDataFormat, proSize);
    status = AudioFileGetProperty(voiceAudioFile, kAudioFilePropertyDataFormat, &proSize, &voiceDataFormat);
    if (status) {
        goto reterr;
    }
    BOOL isVoiceFileBigEndian = false;
    if ((voiceDataFormat.mFormatID == kAudioFormatLinearPCM) &&
        (voiceDataFormat.mSampleRate == 44100.0) &&
        (voiceDataFormat.mChannelsPerFrame == 2) &&
        (voiceDataFormat.mBitsPerChannel) == 16) {
        if (voiceDataFormat.mFormatFlags == (kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger)) {
            NSLog(@"Voice file's format is correct, at %@", voiceFileUrl);
        } else {
            if ((voiceDataFormat.mFormatFlags & kAudioFormatFlagIsBigEndian) == kAudioFormatFlagIsBigEndian) {
                NSLog(@"Voice file is encoded in big endian, at %@", voiceFileUrl);
                isVoiceFileBigEndian = true;
            } else {
                status = kAudioFileUnsupportedFileTypeError;
                NSLog(@"Voice file's format is incorrect, at %@", voiceFileUrl);
                goto reterr;
            }
        }
    } else {
        status = kAudioFileUnsupportedFileTypeError;
        NSLog(@"Voice file's format is incorrect, at %@", voiceFileUrl);
        goto reterr;
    }
    
    // bgm files
    bool isBGMFilesBigEndian[MAX_BGMS] = {false};
    AudioStreamBasicDescription bgmDataFormats[MAX_BGMS];
    for (int i = 0; i < [bgmFileUrls_nsurl count]; i++) {
        bzero(bgmDataFormats + i, proSize);
        status = AudioFileGetProperty(bgmAudioFiles[i], kAudioFilePropertyDataFormat, &proSize, bgmDataFormats + i);
        if (status) {
            goto reterr;
        }
        if ((bgmDataFormats[i].mFormatID == kAudioFormatLinearPCM) &&
            (bgmDataFormats[i].mSampleRate == 44100.0) &&
            (bgmDataFormats[i].mChannelsPerFrame == 2) &&
            (bgmDataFormats[i].mBitsPerChannel == 16)) {
            if (bgmDataFormats[i].mFormatFlags == (kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger)) {
                NSLog(@"BGM format is correct, at %@", [bgmFileUrls objectAtIndex:i]);
            } else {
                if ((bgmDataFormats[i].mFormatFlags & kAudioFormatFlagIsBigEndian) == kAudioFormatFlagIsBigEndian) {
                    NSLog(@"BGM is encoded in big endian, at %@", [bgmFileUrls objectAtIndex:i]);
                    isBGMFilesBigEndian[i] = true;
                } else {
                    NSLog(@"BGM format is incorrect, at %@", [bgmFileUrls objectAtIndex:i]);
                    status = kAudioFileUnsupportedFileTypeError;
                    goto reterr;
                }
            }
        } else {
            NSLog(@"BGM format is incorrect, at %@", [bgmFileUrls objectAtIndex:i]);
            status = kAudioFileUnsupportedFileTypeError;
            goto reterr;
        }
    }
    
    // All input files validated, open output (mix) file
    AudioStreamBasicDescription mixFileDataFormat;
    bzero(&mixFileDataFormat, sizeof(mixFileDataFormat));
    [self _setDefaultAudioFormatFlags:&mixFileDataFormat numChannels:2];
    status = AudioFileCreateWithURL((__bridge CFURLRef)mixFileUrl_nsurl, kAudioFileCAFType, &mixFileDataFormat, kAudioFileFlags_EraseFile, &mixAudioFile);
    if (status) {
        NSLog(@"Create mix audio file failed.");
        goto reterr;
    }
    
    // Read buffer of data from each file
    
    // Initialise buffers for mixing
    voicebuffer = malloc(BUFFER_SIZE);
    assert(voicebuffer);
    bgmbuffer = malloc(BUFFER_SIZE);
    assert(bgmbuffer);
    mixbuffer = malloc(BUFFER_SIZE);
    assert(mixbuffer);
    
    SInt64 voiceFilePacketNum = 0;
    SInt64 bgmFilePacketNum = 0; // shared by all bgm files as once only one bgm will be used
    SInt64 mixFilePacketNum = 0;
    
    int PACKETS_PER_10MS = voiceDataFormat.mSampleRate / voiceDataFormat.mFramesPerPacket / 100;
    
    // find the correct bgm
    int bgmIndex = 0,
    previousBGMIndex = -1;      // store last time bgm index, if previous and current index are the diffeent, bgm packet number need to be initialised to offset
    UInt64 bgmOffsetInMs = 0;
    bool needBGM = false;
    int volumeLevel = 100;
    
    while (true) {
        // Read a chunk of input
        UInt32 voiceFileBytesRead = 0;
        UInt32 bgmFileBytesRead = 0;
        UInt32 voiceFileNumPacket = 0; // number of packets about to read
        UInt32 bgmFileNumPacket = 0; // number of packets about to read
        
        [instructions getNextInstructionWithMSPostion:(int)(voiceFilePacketNum / PACKETS_PER_10MS) bgmIndex:&bgmIndex bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM volumeLevel:&volumeLevel];
        
        // to check whether need to initialised bgmFilePacketNum
        if (previousBGMIndex != bgmIndex) {
            // bgm has changed
            bgmFilePacketNum = bgmOffsetInMs * PACKETS_PER_10MS;
        }
        previousBGMIndex = bgmIndex;
        
        // read packets from voice file
        voiceFileNumPacket = BUFFER_SIZE / voiceDataFormat.mBytesPerPacket;
        status = AudioFileReadPackets(voiceAudioFile, // the audio file ID of the audio about to read
                                      false, // whehter cache
                                      &voiceFileBytesRead, // a return value to indicate how many bytes read successfully
                                      NULL, // AudioStreamBasicDescription, optional
                                      voiceFilePacketNum, // starting packet number
                                      &voiceFileNumPacket, // both way, pass the number of packets want to read, return the actual number of packets has read
                                      voicebuffer); // to collect the acutal data
        if (status) {
            NSLog(@"Read voice packets failed at packet number: %lld", voiceFilePacketNum);
            goto reterr;
        }
        
        // if buffer was not filled, fill with zeros
        if (voiceFileBytesRead < BUFFER_SIZE) {
            bzero(voicebuffer + voiceFileBytesRead, (BUFFER_SIZE - voiceFileBytesRead));
        }
        
        voiceFilePacketNum += voiceFileNumPacket;
        
        // read packets from bgm file
        if (needBGM) {
            bgmFileNumPacket = BUFFER_SIZE / bgmDataFormats[bgmIndex].mBytesPerPacket;
            status = AudioFileReadPackets(bgmAudioFiles[bgmIndex], false, &bgmFileBytesRead, NULL, bgmFilePacketNum, &bgmFileNumPacket, bgmbuffer);
            if (status) {
                NSLog(@"Read bgm packets failed at packet number: %lld, at bgm file %@", bgmFilePacketNum, bgmFileUrls[bgmIndex]);
                goto reterr;
            }
            
            // if buffer was not filled, fill with zeros
            if (bgmFileBytesRead < BUFFER_SIZE) {
                bzero(bgmbuffer + bgmFileBytesRead, (BUFFER_SIZE - bgmFileBytesRead));
            }
            
            bgmFilePacketNum += bgmFileNumPacket;
                      
        } else {
            // no bgm need to mix
            bgmFileBytesRead = 0;
        }
        
        // if buffer was not filled, fill with zeros
        if (bgmFileBytesRead < BUFFER_SIZE) {
            bzero(bgmbuffer + bgmFileBytesRead, (BUFFER_SIZE - bgmFileBytesRead));
        }
        
        // Handle voice meet its end
        if (voiceFileNumPacket == 0) {
            NSLog(@"Voice audio file meets its end, stop mix.");
            break;
        }
        
        // Write pcm data to output file
        
        // Handle when buffer did not fully filled
        int maxNumPackets;
        if (voiceFileNumPacket > bgmFileNumPacket) {
            maxNumPackets = voiceFileNumPacket;
        } else if (voiceFileNumPacket == 0 && bgmFileNumPacket == 0) {
            maxNumPackets = 1;
        } else {
            maxNumPackets = bgmFileNumPacket;
        }
        
        int numSamples = (maxNumPackets * mixFileDataFormat.mBytesPerPacket) / sizeof(int16_t);
        
        // if two input files are encoded in different endian, then change bgm to voice's encode
        mix_buffers_volumeControl((const int16_t *)voicebuffer, (const int16_t *)bgmbuffer, (const int16_t)volumeLevel, (int16_t *)mixbuffer, numSamples, !(isVoiceFileBigEndian == isBGMFilesBigEndian[bgmIndex]));
        
        
        // write the mixed packets to the output file
        UInt32 packetsWritten = maxNumPackets;
        status = AudioFileWritePackets(mixAudioFile, false, (maxNumPackets * mixFileDataFormat.mBytesPerPacket), NULL, mixFilePacketNum, &packetsWritten, mixbuffer);
        if (status) {
            status = kAudioFileInvalidPacketOffsetError;
            NSLog(@"Write to output file failed, not all packets write to file");
            goto reterr;
        }
        
        mixFilePacketNum += packetsWritten;
        
    }

    
reterr:
    for (int i = 0; i < [bgmFileUrls_nsurl count]; i++) {
        if (bgmAudioFiles[i] != NULL) {
            close_status = AudioFileClose(bgmAudioFiles[i]);
            assert(close_status == 0);
        }
    }
    if (voiceAudioFile != NULL) {
        close_status = AudioFileClose(voiceAudioFile);
        assert(close_status == 0);
    }
    if (mixAudioFile != NULL) {
        close_status = AudioFileClose(mixAudioFile);
        assert(close_status == 0);
    }
    if (voicebuffer != NULL) {
        free(voicebuffer);
    }
    if (bgmbuffer != NULL) {
        free(bgmbuffer);
    }
    if (mixbuffer != NULL) {
        free(mixbuffer);
    }
    
    return status;
    
}

+ (OSStatus) mixFiles:(NSArray*)files atTimes:(NSArray*)times toMixfile:(NSString*)mixfile {
    OSStatus status = 0;
    NSString *tmpDir = NSTemporaryDirectory();
    for (int i=1; i<[files count]; i++) {
        NSString *file1 = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.caf",i-1]];
        NSString *file2 = [files objectAtIndex:i];
        if (i==1) file1 = [files objectAtIndex:0];
        NSString *target = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.caf",i]];
        if (i+1==[files count]) {
            target = mixfile;
        }
        status = [self mix:file1 file2:file2 offset:[(NSNumber*)[times objectAtIndex:i] intValue]*5 mixfile:target];
    }
    return status;
}

@end





















































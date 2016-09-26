//
//  ViewController.m
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // init audio recorder
    recorder = [[MyAudioRecorder alloc] init];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Recorder
//
// -------------------------------------------------------------------------------------------------------------------

- (IBAction) recorder_startTapped:(id)sender {
    NSLog(@"Recorder_start tapped");
    
    if (recorder) {
        NSString *errorMessage;
        if (![recorder startRecord: errorMessage]) {
            // start record failed.
        }
    }
}

- (IBAction) recorder_stopTapped:(id)sender {
    NSLog(@"Recorder_stop tapped");
    
    if (recorder) {
        NSString *errorMessage;
        if (![recorder stopRecord: errorMessage]) {
            // stop record failed
        }
    }
}

- (IBAction) recorder_showPathTapped:(id)sender {
    NSLog(@"Recorder_showPath tapped");
    
    NSLog(@"%@", recorder.audioFilePath);
    
    [[[UIAlertView alloc] initWithTitle:@"Done" message:[NSString stringWithFormat:@"Record audio file at %@", recorder.audioFilePath] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

- (IBAction) recorder_deleteTapped:(id)sender {
    NSLog(@"Recorder_delete tapped");
    
    if (recorder) {
        if ([recorder deleteRecording]) {
            NSLog(@"Audio file has deleted");
        } else {
            NSLog(@"Failed to delete audio file at %@", recorder.audioFilePath);
        }
    }
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Player
//
// -------------------------------------------------------------------------------------------------------------------

- (IBAction) player_playRecordTapped:(id)sender {
    NSLog(@"player_playRecord Tapped");
    
    player = [[MyAudioPlayer alloc] initWithAudioFilePath: recorder.audioFilePath];
    
    NSString *errorMessage;
    if (![player playAudio: errorMessage]) {
        NSLog(@"Play audio record failed due to %@", errorMessage);
    }
}

- (IBAction) player_playBGMTapped:(id)sender {
    NSLog(@"player_playBGM Tapped");
    
    player = [[MyAudioPlayer alloc] initWithAudioFilePath: [self getBGMFilePath]];
    
    NSString *errorMessage;
    if (![player playAudio: errorMessage]) {
        NSLog(@"Play audio record failed due to %@", errorMessage);
    }
    
}
- (IBAction) player_stopTapped:(id)sender {
    NSLog(@"player_stopTapped");
    
    if (player) {
        NSString *errorMessage;
        if (![player stopPlayingAudio: errorMessage]) {
            NSLog(@"Stop audio playing failed due to %@", errorMessage);
        }
    } else {
        NSLog(@"Stop audio playing failed due to player does not setup properly");
    }
    
}


// -------------------------------------------------------------------------------------------------------------------
//
//  Converter
//
// -------------------------------------------------------------------------------------------------------------------

- (IBAction) convert_convertTapped:(id)sender {
    NSLog(@"Convert all mp3 to caf");
    
    NSArray *mp4s = [self getMP4s];
    NSArray *cafs = [self getCAFs:mp4s];
    
    [MyAudioConverter convertFiles:mp4s toFiles:cafs];
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Mixer
//
// -------------------------------------------------------------------------------------------------------------------

- (IBAction)mix_converNMixTapped:(id)sender {
    NSLog(@"Convert all mp3 to caf and then mix them");
    
    NSArray *mp3s = [self getMP3s];
    NSArray *cafs = [self getCAFs:mp3s];
    
    [MyAudioConverter convertFiles:mp3s toFiles:cafs];
    
    NSArray *times = [self getDefaultTimes:[cafs count]];
    NSString *mixURL = [self getMixURL];
    
    OSStatus status = [MyAudioMixer mixFiles:cafs atTimes:times toMixfile:mixURL];
    
    if (status) {
        NSLog(@"Mix files got a status of %d", (int)status);
    } else {
        NSLog(@"Mix done successfully");
    }
}

- (IBAction)mix_recordNMixBGMTapped:(id)sender {
    NSLog(@"Record a voice and then mix with bgm");
    
    if (recorder) {
        
        NSString *recordFileUrl = recorder.audioFilePath;
        NSString *bgmFileUrl = [self getBGMFilePath];
        
        NSString *mixUrl = [self getMixURL];
        
        // start to mix
        OSStatus status = [MyAudioMixer mix:recordFileUrl file2:bgmFileUrl offset:0 mixfile:mixUrl bgmMix:true];
        if (status) {
            NSLog(@"Mix files got a status of %d", (int)status);
        } else {
            NSLog(@"Mix done successfully");
        }
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Record a voice first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction) mix_record_playBGMTapped:(id)sender {
    NSLog(@"Record a voice and play BGM and then mix voice with BGM");
    
    [self playBGM];
    [self startRecord];
}

- (IBAction) mix_stop_mixBGMTapped:(id)sender {
    NSLog(@"Stop record and mix the record with bgm");
    
    [self stopBGM];
    [self stopRecord];
    
    if([self mixRecordWithBGM]) {
    }
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Parser
//
// -------------------------------------------------------------------------------------------------------------------

//- (IBAction) parse_parse:(id)sender {
//    NSString *sampleInstruction_str = @"80,78300,/path/to/bgm1,0;90000,91000,/path/to/bgm2,0;900300,910030,/path/to/bgm2,0;";
//    
//    MyAudioMixerInstructionsParser *parser = [[MyAudioMixerInstructionsParser alloc] initWithAudioMixerInstructions:sampleInstruction_str];
//    
//    NSLog(@"Parser.");
//}

- (IBAction) parse_nextInstruction:(id)sender {
    NSString *sampleInstruction_str = @"80,78300,/path/to/bgm1,0;90000,91000,/path/to/bgm2,0;";
    
    MyAudioMixerInstructionsParser *parser = [[MyAudioMixerInstructionsParser alloc] initWithAudioMixerInstructions:sampleInstruction_str];
    
    int index;
    UInt64 bgmOffsetInMs;
    bool needBGM;
    
    [parser getNextInstructionWithMSPostion:20 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];
    [parser getNextInstructionWithMSPostion:50 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];
    [parser getNextInstructionWithMSPostion:5000 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];
    [parser getNextInstructionWithMSPostion:78300 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];
    [parser getNextInstructionWithMSPostion:90000 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];
    [parser getNextInstructionWithMSPostion:100000 bgmIndex:&index bgmOffsetInMS:&bgmOffsetInMs whetherNeedBGM:&needBGM];

    
    NSLog(@"Parser.");
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Complex mix
//
// -------------------------------------------------------------------------------------------------------------------
//- (IBAction) complex_mix:(id)sender {
//    NSString *sampleInstruction_str = [NSString stringWithFormat:@"1000,2000,%@,0;3000,4000,%@,0;5000,8000,%@,0;", [self getBGM2FilePath], [self getBGMFilePath], [self getBGM2FilePath]];
//    NSString *voiceFileUrl = [self getVoiceFilePath];
//    NSString *mixFileUrl = [self getMixURL];
//
//    [MyAudioMixer complexMixFilesWithInstructions:sampleInstruction_str voiceFileUrl:voiceFileUrl mixFileUrl:mixFileUrl];
//
//}

- (IBAction) complex_mix_json_instr:(id)sender {
    NSString *json_instr = [NSString stringWithFormat:@"[{\"startPosition\":100, \"endPosition\":200, \"bgmFileUrl\":\"%@\", \"volumeControl\":[{\"startPosition\":0, \"endPosition\":50, \"volumeLevel\":50},{\"startPosition\":50, \"endPosition\":100, \"volumeLevel\":100}]}, {\"startPosition\":300, \"endPosition\":5000, \"bgmFileUrl\":\"%@\", \"volumeControl\":[{\"startPosition\":0, \"endPosition\":1000, \"volumeLevel\":150},{\"startPosition\":1000, \"endPosition\":2000, \"volumeLevel\":50}]}]", [self getBGMFilePath], [self getBGM2FilePath]];
    
    MyAudioMixerInstructionsParser *parser = [[MyAudioMixerInstructionsParser alloc] initWithAudioMixerInstructionsJSON:json_instr];
    
    NSString *voiceFileUrl = [self getVoiceFilePath];
    NSString *mixFileUrl = [self getMixURL];
    
    [MyAudioMixer complexMixFilesWithInstructions:json_instr voiceFileUrl:voiceFileUrl mixFileUrl:mixFileUrl];
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Editor
//
// -------------------------------------------------------------------------------------------------------------------
- (IBAction)editor_cut_audio:(id)sender {
    NSString *sampleInstructionsString = @"79,579;989,1489;3200,4350;";
    
    UInt64 testTimePosition[15] = {50, 79, 400, 579, 700, 989, 1000, 1489, 1500, 2000, 2500, 4000, 4350, 5000, 6304};
    
    
    MyAudioEditorInstructionParser *editorInstruction = [[MyAudioEditorInstructionParser alloc] initWithAudioEditorInstructionsString:sampleInstructionsString];
    
    for (int i = 0; i < 15; i++) {
        NSLog(@"Should time point %llu be skipped: %hhu", testTimePosition[i] ,[editorInstruction ifNeedSkipAt:testTimePosition[i]]);
    }

    bool res = [MyAudioEditor cutAudioWithInstructions:[self getBGMFilePath] instructions:editorInstruction outputFileUrl:[self getEditedURL]];
    if (!res) {
        NSLog(@"Edit audio failed.");
    }
}

// -------------------------------------------------------------------------------------------------------------------
//
//  Helper functions
//
// -------------------------------------------------------------------------------------------------------------------

- (NSString *) getBGMFilePath {
    return [[NSBundle mainBundle] pathForResource:@"Jazzy-beat-house-music-track.caf" ofType:nil];
}

- (NSString *) getBGM2FilePath {
    return [[NSBundle mainBundle] pathForResource:@"bgm1.caf" ofType:nil];
}

- (NSString *) getVoiceFilePath {
    return [[NSBundle mainBundle] pathForResource:@"voice 1.caf" ofType:nil];

}

- (NSArray *) getMP3s {
    // Find all mp3's in bundle
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.mp3'"];
    NSArray *mp3s = [dirContents filteredArrayUsingPredicate:predicate];
    
    // Convert mp3's to their full paths
    NSMutableArray *fullmp3s = [[NSMutableArray alloc] initWithCapacity:[mp3s count]];
    [mp3s enumerateObjectsUsingBlock:^(NSString *file, NSUInteger idx, BOOL *stop) {
        [fullmp3s addObject:[bundleRoot stringByAppendingPathComponent:file]];
    }];
    
    return fullmp3s;
}

- (NSArray *) getMP4s {
    // Find all mp4's in bundle
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.mp4'"];
    NSArray *mp4s = [dirContents filteredArrayUsingPredicate:predicate];
    
    // Convert mp3's to their full paths
    NSMutableArray *fullmp4s = [[NSMutableArray alloc] initWithCapacity:[mp4s count]];
    [mp4s enumerateObjectsUsingBlock:^(NSString *file, NSUInteger idx, BOOL *stop) {
        [fullmp4s addObject:[bundleRoot stringByAppendingPathComponent:file]];
    }];
    
    return fullmp4s;
}

- (NSArray *) getCAFs: (NSArray *)mp3s {
    NSString *documentDirectory = [self getDeviceDocumentDirectory];
    
    // create caf's from mp3's
    NSMutableArray *cafs = [[NSMutableArray alloc] initWithCapacity:[mp3s count]];
    
//    [mp3s enumerateObjectsUsingBlock:^(NSString *file, NSUInteger idx, bool *stop) {
//        [cafs addObject:[documentDirectory stringByAppendingPathComponent:[[file lastPathComponent] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [file pathExtension]] withString:@".caf"]]];
//    }];
    
    return cafs;
}

- (NSString *) getDeviceDocumentDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (NSArray *) getDefaultTimes: (NSUInteger)count {
    NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (int i = 0 ; i < count; i++) {
        [times addObject:[NSNumber numberWithInt:0]];
    }
    
    return times;
}

- (NSString *) getMixURL {
    return [[self getDeviceDocumentDirectory] stringByAppendingPathComponent:@"Mix.caf"];
}

- (NSString *) getEditedURL {
    return [[self getDeviceDocumentDirectory] stringByAppendingPathComponent:@"Edited.caf"];
}

- (BOOL) playBGM {
    player = [[MyAudioPlayer alloc] initWithAudioFilePath: [self getBGMFilePath]];
    
    NSString *errorMessage;
    if (![player playAudio: errorMessage]) {
        NSLog(@"Play audio record failed due to %@", errorMessage);
        return false;
    }
    
    return true;
}

- (void) stopBGM {
    if (player) {
        NSString *errorMessage;
        if (![player stopPlayingAudio: errorMessage]) {
            NSLog(@"Stop audio playing failed due to %@", errorMessage);
        }
    } else {
        NSLog(@"Stop audio playing failed due to player does not setup properly");
    }
}

- (BOOL) startRecord {
    if (recorder) {
        NSString *errorMessage;
        if (![recorder startRecord: errorMessage]) {
            // start record failed.
        } else {
            return true;
        }
    }
    
    return false;
}

- (BOOL) stopRecord {
    
    if (recorder) {
        NSString *errorMessage;
        if (![recorder stopRecord: errorMessage]) {
            // stop record failed
        } else {
            return true;
        }
    }
    
    return false;
}

- (BOOL) mixRecordWithBGM {
    if (recorder) {
        
        NSString *recordFileUrl = recorder.audioFilePath;
        NSString *bgmFileUrl = [self getBGMFilePath];
        
        NSString *mixUrl = [self getMixURL];
        
        // start to mix
        OSStatus status = [MyAudioMixer mix:recordFileUrl file2:bgmFileUrl offset:0 mixfile:mixUrl bgmMix:true];
        if (status) {
            NSLog(@"Mix files got a status of %d", (int)status);
        } else {
            NSLog(@"Mix done successfully");
            return true;
        }
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Record a voice first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
    return false;

}

@end




















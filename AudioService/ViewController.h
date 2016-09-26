//
//  ViewController.h
//  AudioService
//
//  Created by Jupiter Li on 29/06/2016.
//  Copyright (c) 2016 Jupiter Li. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MyAudioRecorder.h"
#import "MyAudioPlayer.h"
#import "MyAudioConverter.h"
#import "MyAudioMixer.h"

#import "MyAudioMixerInstructionsParser.h"
#import "MyAudioEditorInstructionParser.h"

#import "MyAudioEditor.h"

@interface ViewController : UIViewController {
    MyAudioRecorder *recorder;
    
    MyAudioPlayer *player;
    
    
}


- (IBAction) recorder_startTapped:(id)sender;
- (IBAction) recorder_stopTapped:(id)sender;
- (IBAction) recorder_showPathTapped:(id)sender;
- (IBAction) recorder_deleteTapped:(id)sender;

- (IBAction) player_playRecordTapped:(id)sender;
- (IBAction) player_playBGMTapped:(id)sender;
- (IBAction) player_stopTapped:(id)sender;

- (IBAction) convert_convertTapped:(id)sender;

- (IBAction) mix_converNMixTapped:(id)sender;
- (IBAction) mix_recordNMixBGMTapped:(id)sender;
- (IBAction) mix_record_playBGMTapped:(id)sender;
- (IBAction) mix_stop_mixBGMTapped:(id)sender;

- (IBAction) parse_parse:(id)sender;
- (IBAction) parse_nextInstruction:(id)sender;

- (IBAction) complex_mix:(id)sender;
- (IBAction) complex_mix_json_instr:(id)sender;

- (IBAction) editor_cut_audio:(id)sender;

@end


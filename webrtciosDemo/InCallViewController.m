//
//  InCallViewController.m
//  webrtciosDemo
//
//  Created by 余成海 on 14-2-26.
//  Copyright (c) 2014年 余成海. All rights reserved.
//

#import "InCallViewController.h"
#import "AppXmppModel.h"
#import "AVFoundation/AVAudioSession.h"
#import "AudioToolbox/AudioServices.h"
#import "AVFoundation/AVAudioPlayer.h"

@interface InCallViewController ()

@end

@implementation InCallViewController
{
    AppXmppModel *_model;
    BOOL _isBigVoice;
    BOOL _isMute;
    BOOL _isHold;
    BOOL _isClose;
    AVAudioPlayer *_audioPlayer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _isInCall = NO;
        _isBigVoice = NO;
        _isMute = NO;
        _isHold = NO;
        _isClose = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _model = [AppXmppModel sharedModelManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callFailed) name:notiCallError object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callFailed) name:notiSessionDestroy object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedAccept) name:notiReceivedAccept object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedReject) name:notiReceivedReject object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedBusy) name:notiReceivedBusy object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedUnlive) name:notiReceivedUnLive object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)callFailed
{
   [self performSelectorOnMainThread:@selector(showAlertView:) withObject:@"连接断开，无法和对方正常通话" waitUntilDone:YES];
}

- (void)showAlertView:(NSString*)content
{
    @synchronized(self) {
        if (!_isClose) {
            //手机震动
            _isClose = YES;
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:content
                                                               delegate:self
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (void)receivedAccept
{
    [self performSelectorOnMainThread:@selector(receivedAcceptInMainThread) withObject:nil waitUntilDone:YES];
}

- (void)receivedAcceptInMainThread
{
    //手机震动
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self setTip:@"通话中"];
}

- (void)setTip:(NSString*)msg
{
    _ltip.text = msg;
}

- (void)receivedReject
{
    [self performSelectorOnMainThread:@selector(showAlertView:) withObject:@"对方断开了于您的通话！" waitUntilDone:YES];
}

- (void)receivedBusy
{
    [self performSelectorOnMainThread:@selector(showAlertView:) withObject:@"您拨打的用户正在通话中，请稍后再拨！" waitUntilDone:YES];
}

- (void)receivedUnlive
{
    [self performSelectorOnMainThread:@selector(showAlertView:) withObject:@"您拨打的用户暂时无人接听，请稍后再拨！" waitUntilDone:YES];
}

- (IBAction)acceptClick:(id)sender {
    [_model acceptCall];
    _isInCall = YES;
    [_btnAccept setHidden:YES];
    [self setTip:@"通话中"];
    
    if (_audioPlayer) {
        [_audioPlayer stop];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
}

- (IBAction)closeClick:(id)sender {
    if (_isInCall) {
        [_model closeCall];
    } else {
        [_model declineCall:NO];
    }

    _isClose = YES;
    if (_audioPlayer) {
        [_audioPlayer stop];
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)voiceClick:(id)sender {
    _isBigVoice = !_isBigVoice;
    if (_isBigVoice == YES) {
        [_btnVoice setTitle:@"听筒" forState:UIControlStateNormal];
        [_btnVoice setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    } else {
        [_btnVoice setTitle:@"扬声器" forState:UIControlStateNormal];
        [_btnVoice setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
}

- (IBAction)muteClick:(id)sender {
    _isMute = !_isMute;
    if (_isMute == YES) {
        [_btnMute setTitle:@"开启声音" forState:UIControlStateNormal];
        [_btnMute setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    } else {
        [_btnMute setTitle:@"关闭声音" forState:UIControlStateNormal];
        [_btnMute setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    }
    [_model muteCall:_isMute];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self closeClick:nil];
    }
}

- (IBAction)holdClick:(id)sender {
    _isHold = !_isHold;
    if (_isHold == YES) {
        [_btnHold setTitle:@"开通" forState:UIControlStateNormal];
        [_btnHold setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    } else {
        [_btnHold setTitle:@"保持" forState:UIControlStateNormal];
        [_btnHold setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    }
    [_model holdCall:_isHold];
}

- (BOOL) prepAudio
{
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"loop" ofType:@"mp3"];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return NO;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (!_audioPlayer)
    {
        NSLog(@"Error: %@", [error localizedDescription]);
        return NO;
    }
    [_audioPlayer prepareToPlay];
    [_audioPlayer setNumberOfLoops:-1];
    [_audioPlayer play];
    
    return YES;
}
@end

//
//  InCallViewController.h
//  webrtciosDemo
//
//  Created by 余成海 on 14-2-26.
//  Copyright (c) 2014年 余成海. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InCallViewController : UIViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnAccept;
@property (weak, nonatomic) IBOutlet UILabel *ltip;
@property (weak, nonatomic) IBOutlet UILabel *lusename;
@property (assign, nonatomic) BOOL isInCall;
@property (weak, nonatomic) IBOutlet UIButton *btnVoice;
@property (weak, nonatomic) IBOutlet UIButton *btnMute;
@property (weak, nonatomic) IBOutlet UIButton *btnHold;

- (IBAction)acceptClick:(id)sender;
- (IBAction)closeClick:(id)sender;
- (IBAction)voiceClick:(id)sender;
- (IBAction)muteClick:(id)sender;
- (IBAction)holdClick:(id)sender;

- (BOOL) prepAudio;

@end

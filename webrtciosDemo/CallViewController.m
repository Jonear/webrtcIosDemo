//
//  CallViewController.m
//  webrtcjingle
//
//  Created by 余成海 on 14-2-25.
//
//

#import "CallViewController.h"
#import "AppXmppModel.h"
#import "InCallViewController.h"
#import "AudioToolbox/AudioServices.h"

@interface CallViewController ()

@end

@implementation CallViewController
{
    AppXmppModel *_model;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _model = [AppXmppModel sharedModelManager];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callFailed) name:notiCallError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:_tableView selector:@selector(reloadData) name:notiPresenceArrayUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(someonCallIn:) name:notiCallIn object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)callClick:(id)sender {

    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    
    if (indexPath && (int)_model.presenceArray.count > (int)indexPath.row) {
        [_model call:[_model.presenceArray objectAtIndex:indexPath.row]];
        
        NSString *username = [_model.presenceArray objectAtIndex:indexPath.row];
        username = [username substringToIndex:[username rangeOfString:@"@"].location];
        
        InCallViewController *inCallViewController = [[InCallViewController alloc] initWithNibName:@"InCallViewController" bundle:nil];
        [self presentViewController:inCallViewController animated:NO completion:^{
            inCallViewController.ltip.text = @"拨出中...";
            inCallViewController.lusename.text = username;
            [inCallViewController.btnAccept setHidden:YES];
            inCallViewController.isInCall = YES;
        }];
    } else {
        
    }
}

- (void)callFailed
{
//    NSString *tip = @"拨打失败，对方未在线";
//    [self performSelectorOnMainThread:@selector(setTip:) withObject:tip waitUntilDone:YES];
}

- (void)someonCallIn:(NSNotification *)notify
{

    if (self.presentedViewController) {
        [_model declineCall:YES];
    } else {
        NSDictionary *param = [notify userInfo];
        NSString * username = [param objectForKey:@"remote_jid"];
        
        [self performSelectorOnMainThread:@selector(someonCallInMainThread:) withObject:username waitUntilDone:YES];
    }
}

- (void)someonCallInMainThread:(NSString*)username
{
    NSRange range = [username rangeOfString:@"@"];
    if (range.location != NSNotFound) {
        username = [username substringToIndex:[username rangeOfString:@"@"].location];
    }
    
    InCallViewController *inCallViewController = [[InCallViewController alloc] initWithNibName:@"InCallViewController" bundle:nil];
    
    [self presentViewController:inCallViewController animated:NO completion:^{
        inCallViewController.ltip.text = [NSString stringWithFormat:@"%@ 拨入..",username];
        inCallViewController.lusename.text = username;
        [inCallViewController prepAudio];
    }];
    //手机震动
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _model.presenceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PresenceArrayCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PresenceArrayCell"];
    }
    NSString *username = [_model.presenceArray objectAtIndex:indexPath.row];
    
    NSRange range = [username rangeOfString:@"@"];
    if (range.location != NSNotFound) {
        username = [username substringToIndex:[username rangeOfString:@"@"].location];
    }
    
    cell.textLabel.text = username;
    cell.imageView.image = [UIImage imageNamed:@"defaultAvatar"];
    
    return cell;
}

@end

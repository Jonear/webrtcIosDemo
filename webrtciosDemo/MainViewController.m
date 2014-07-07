//
//  MainViewController.m
//  webrtcjingle
//
//  Created by 余成海 on 14-2-24.
//
//

#import "MainViewController.h"
#import "AppXmppModel.h"
#import "CallViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController
{
    AppXmppModel *_model;
}

@synthesize tfusername=_tfusername;
@synthesize tfpassword=_tfpassword;
@synthesize ltip = _ltip;

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
    
    //本地 xmpp
    [_model setupStream];
    [_tfusername becomeFirstResponder];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:notiloginsuccess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed) name:notiloginFailed object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginClick:(id)sender {
    if (_tfusername.text.length > 0 && _tfpassword.text.length > 0) {

        [_model connect:_tfusername.text withPassword:_tfpassword.text];
        [_tfusername resignFirstResponder];
        [_tfpassword resignFirstResponder];
        
        [self statsUpdate:@"登录中。。"];
    } else {
        [self statsUpdate:@"请输入账号"];
    }

}

- (IBAction)logout:(id)sender{
//    printf("logout");
//#ifdef IOS_XMPP_FRAMEWORK
//    [appDelegate disconnect];
//#else
//    VoiceClientDelegate* vc = VoiceClientDelegate::getInstance();
//    vc->Logout();
//#endif
}

- (void)statsUpdate:(NSString *)stats {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_ltip setText:stats];
    });
}

- (void)loginSuccess
{
    [self statsUpdate:@"登录成功"];
    CallViewController *callViewController = [[CallViewController alloc] initWithNibName:@"CallViewController" bundle:nil];
    [self presentViewController:callViewController animated:NO completion:nil];
}
- (void)loginFailed
{
    [self statsUpdate:@"登录失败，检查用户名密码"];
}
@end

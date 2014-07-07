//
//  MainViewController.h
//  webrtcjingle
//
//  Created by 余成海 on 14-2-24.
//
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tfusername;
@property (weak, nonatomic) IBOutlet UITextField *tfpassword;
@property (weak, nonatomic) IBOutlet UILabel *ltip;

- (IBAction)loginClick:(id)sender;

@end

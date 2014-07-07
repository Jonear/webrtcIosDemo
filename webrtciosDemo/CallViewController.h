//
//  CallViewController.h
//  webrtcjingle
//
//  Created by 余成海 on 14-2-25.
//
//

#import <UIKit/UIKit.h>

@interface CallViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (IBAction)callClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

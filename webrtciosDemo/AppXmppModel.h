//
//  AppXmppModel.h
//  webrtcjingle
//
//  Created by 余成海 on 14-2-25.
//
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@interface AppXmppModel : NSObject <UIApplicationDelegate>


@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property BOOL reconnectAfterClosed;
@property (nonatomic, strong) XMPPJID* myJid;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSMutableArray* presenceArray;

+ (id)sharedModelManager;

- (void)setupStream;
- (void)teardownStream;
- (void)goOnline;
- (void)goOffline;

- (BOOL)connect:(NSString*)userId withPassword:(NSString*)password;
- (void)disconnect;

- (void)call:(NSString*) jid;
- (void)closeCall;
- (void)acceptCall;
- (void)declineCall:(BOOL)busy;
- (void)muteCall:(BOOL)mute;
- (void)holdCall:(BOOL)hold;

@end

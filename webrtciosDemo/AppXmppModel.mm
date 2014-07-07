//
//  AppXmppModel.m
//  webrtcjingle
//
//  Created by 余成海 on 14-2-25.
//
//

#import "AppXmppModel.h"
#import "XmppClientDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@implementation AppXmppModel
{
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
	BOOL isXmppConnected;
    XmppClientDelegate* xmppClientDelegate;
}

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize myJid;
@synthesize password;
@synthesize reconnectAfterClosed;

+ (id)sharedModelManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = [[AppXmppModel alloc] init];});
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        _presenceArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)connect:(NSString*)userId withPassword:(NSString*)passwordt
{
	if ([self.xmppStream isAuthenticated]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notiloginsuccess object:nil];
		return YES;
	}
    
	NSString *myJID = [NSString stringWithFormat:@"%@@%@/%@", userId, OpenfireServerName, ResourceName];
	NSString *myPassword = [NSString stringWithFormat:@"%@", passwordt];
    
    [[NSUserDefaults standardUserDefaults] setObject:myJID forKey:@"keyusername"];
    [[NSUserDefaults standardUserDefaults] setObject:myPassword forKey:@"keypassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
    
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    
    self.myJid = [XMPPJID jidWithString:myJID];
	self.password = myPassword;
    
    [self.xmppStream setMyJID:self.myJid];
    
    NSError *error = nil;
    if ([self.xmppStream isConnected]) {
        if ([[self xmppStream] authenticateWithPassword:self.password error:&error])
        {
            [xmppClientDelegate getVoiceClientDelegate]->Login();
        } else {
            //DDLogError(@"Error authenticating: %@", error);
        }
    } else {
        if (![self.xmppStream connectWithTimeout:5.f error:&error])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                                message:@"See console for error details."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
            
            //		DDLogError(@"Error connecting: %@", error);
            
            return NO;
        }
    }
	return YES;
}

-(void)reconnect
{
//    xmppClientDelegate = [[XmppClientDelegate alloc] init];
//    [xmppClientDelegate activate:self.xmppStream];
//    [xmppClientDelegate getVoiceClientDelegate]->Login();
//    [self.xmppReconnect manualStart];
}

- (void)disconnect
{
	[self goOffline];
	[self.xmppStream disconnect];
}

#pragma mark end

- (void)setupStream
{
	NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
    
	self.xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
		self.xmppStream.enableBackgroundingOnSocket = YES;
#endif

	self.xmppReconnect = [[XMPPReconnect alloc] init];

	[self.xmppReconnect         activate:self.xmppStream];
    
	[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [self.xmppStream setHostName:OpenfireServerUrl];
    [self.xmppStream setHostPort:OpenfireServerPort];
    
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
    
    xmppClientDelegate = [[XmppClientDelegate alloc] init];
    [xmppClientDelegate activate:self.xmppStream];
}

- (void)dealloc
{
	[self teardownStream];
}

- (void)teardownStream
{
	[self.xmppStream removeDelegate:self];
	[self.xmppStream disconnect];
    
	self.xmppStream = nil;
	self.xmppReconnect = nil;
}

- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    [self.xmppStream sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	[self.xmppStream sendElement:presence];
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"SOCKET DID CONNECT");
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
    
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
        
		NSString *expectedCertName = nil;
        
		NSString *serverDomain = self.xmppStream.hostName;
		NSString *virtualDomain = [self.xmppStream.myJID domain];
        
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	isXmppConnected = YES;
    
	NSError *error = nil;
    
	if ([[self xmppStream] authenticateWithPassword:self.password error:&error])
	{
        if ([xmppClientDelegate getVoiceClientDelegate]) {
            [xmppClientDelegate getVoiceClientDelegate]->Login();
        }
	} else {
        //DDLogError(@"Error authenticating: %@", error);
    }

}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self goOnline];
    NSLog(@"SOCKET DID AUTHENTICATE");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notiloginsuccess object:nil];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [[NSNotificationCenter defaultCenter] postNotificationName:notiloginFailed object:nil];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// A simple example of inbound message handling.
}
/*
 <presence xmlns="jabber:client" from="yuchenghai@tl-qd-192.196/xmppios" to="iq19900204@tl-qd-192.196"/>
 <presence xmlns="jabber:client" type="unavailable" from="yuchenghai@tl-qd-192.196/xmppios" to="iq19900204@tl-qd-192.196"/>
 */
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"didReceivePresence:%@", [presence description]);
    if ([presence.type isEqualToString:@"unavailable"]) {
        NSString *userjid = presence.fromStr;
        if ([_presenceArray indexOfObject:userjid] != NSNotFound) {
            [_presenceArray removeObject:userjid];
            [[NSNotificationCenter defaultCenter] postNotificationName:notiPresenceArrayUpdate object:nil];
        }
    } else if ([presence.type isEqualToString:@"available"]){
        NSString *userjid = presence.fromStr;
        if ([_presenceArray indexOfObject:userjid] == NSNotFound
            && ![userjid isEqualToString:myJid.full]) {
            [_presenceArray addObject:userjid];
            [[NSNotificationCenter defaultCenter] postNotificationName:notiPresenceArrayUpdate object:nil];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    //	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	if (!isXmppConnected)
	{
        //		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    [xmppClientDelegate deactivate];
    xmppClientDelegate = nil;
    if (self.reconnectAfterClosed)
    {
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(reconnect) userInfo:nil repeats:NO];
    }
}
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    NSLog(@"xmppStreamConnectDidTimeout");
    
}
//- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
//{
//    NSLog(@"xmppStreamDidDisconnect: %@",error.description);
//    
//}

#pragma mark VoiceClientDelegate section
-(void)call: (NSString*) jid
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->Call([jid cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (void)closeCall
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->EndCall();
    }
}

- (void)acceptCall
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->AcceptCall();
    }
}

- (void)declineCall:(BOOL)busy
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->DeclineCall(busy);
    }
}

- (void)muteCall:(BOOL)mute
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->MuteCall(mute);
    }
}

- (void)holdCall:(BOOL)hold
{
    if (xmppClientDelegate)
    {
        [xmppClientDelegate getVoiceClientDelegate]->HoldCall(hold);
    }
}

@end

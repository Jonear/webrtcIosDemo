//
//  VoiceClientDelegate.cpp
//  webrtcjingle
//
//  Created by Luke Weber on 12/17/12.
//
//
#include "VoiceClientDelegate.h"
#include "talk/p2p/base/session.h"

#ifdef IOS_XMPP_FRAMEWORK
#import "XmppClientDelegate.h"
#import "IOSXmppClient.h"
#import "XmppClientDelegate.h"
#endif

VoiceClientDelegate *VoiceClientDelegate::voiceClientDelegateInstance_ = NULL;

VoiceClientDelegate *VoiceClientDelegate::getInstance(){
    if(VoiceClientDelegate::voiceClientDelegateInstance_ == NULL){
        VoiceClientDelegate::voiceClientDelegateInstance_ = new VoiceClientDelegate();
        VoiceClientDelegate::voiceClientDelegateInstance_->Init();
    }
    return VoiceClientDelegate::voiceClientDelegateInstance_;
}

#ifdef IOS_XMPP_FRAMEWORK
VoiceClientDelegate *VoiceClientDelegate::Create(XmppClientDelegatePtr xmppClientDelegate)
{
    VoiceClientDelegate* result = new VoiceClientDelegate();
    result->xmppClientDelegate_ = xmppClientDelegate;
    result->Init();
    return result;
}
#endif

VoiceClientDelegate::~VoiceClientDelegate()
{
    delete voiceClient_;
    voiceClient_ = NULL;
}

void VoiceClientDelegate::Init(){
    if (voiceClient_ == NULL){
#ifdef IOS_XMPP_FRAMEWORK
        voiceClient_ = new tuenti::VoiceClient(this);
#else
        voiceClient_ = new tuenti::VoiceClient();
#endif
        stun_config_.stun = StunServer;
        stun_config_.turn = TurnServer;
        stun_config_.turn_username = TurnUserName;
        stun_config_.turn_password = TurnPassword;
    }
}

void VoiceClientDelegate::Login(){

//    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"keyusername"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"keypassword"];
    
    voiceClient_->Login([username cStringUsingEncoding:NSUTF8StringEncoding],
                        [password cStringUsingEncoding:NSUTF8StringEncoding],
                        &stun_config_,
                        [OpenfireServerUrl cStringUsingEncoding:NSUTF8StringEncoding],
                        OpenfireServerPort,
                        false,
                        0,
                        false/*isGtalk*/);
}

void VoiceClientDelegate::Logout(){
    voiceClient_->Disconnect();
}

void VoiceClientDelegate::Call(const char *remote_jid){
    voiceClient_->Call(remote_jid);
}

void VoiceClientDelegate::EndCall(){
    voiceClient_->EndCall(call_id_);
}

void VoiceClientDelegate::AcceptCall(){
    voiceClient_->AcceptCall(call_id_);
}

void VoiceClientDelegate::DeclineCall(bool busy){
    voiceClient_->DeclineCall(call_id_, busy);
}

void VoiceClientDelegate::MuteCall(bool mute){
    voiceClient_->MuteCall(call_id_, mute);
}

void VoiceClientDelegate::HoldCall(bool hold){
    voiceClient_->HoldCall(call_id_, hold);
}

void VoiceClientDelegate::OnSignalCallStateChange(int state, const char *remote_jid, int call_id) {
     NSLog(@"------- OnSignalCallStateChange:%d,%s,%d",state,remote_jid,call_id);

    
    switch (state) {
            
        //发起通话1
        case cricket::Session::STATE_SENTINITIATE:
            call_id_ = call_id;
            strcpy(remote_jid_, remote_jid);
            break;
        //对方发来通话2
        case cricket::Session::STATE_RECEIVEDINITIATE:
            call_id_ = call_id;
            strcpy(remote_jid_, remote_jid);
            [[NSNotificationCenter defaultCenter] postNotificationName:notiCallIn object:nil userInfo:@{@"remote_jid": [NSString stringWithUTF8String:remote_jid_]}];
            break;
        //对方同意跟我通话7
        case cricket::Session::STATE_RECEIVEDACCEPT:
            [[NSNotificationCenter defaultCenter] postNotificationName:notiReceivedAccept object:nil];
            break;
            
        //对方正在通话中12
        case cricket::Session::STATE_RECEIVEDBUSY:
            [[NSNotificationCenter defaultCenter] postNotificationName:notiReceivedBusy object:nil];
            break;
            
        //对方不接我的电话15
        case cricket::Session::STATE_SENTTERMINATE:
            [[NSNotificationCenter defaultCenter] postNotificationName:notiReceivedUnLive object:nil];
            break;

       //对方拒接我的电话16
        case cricket::Session::STATE_RECEIVEDTERMINATE:
            [[NSNotificationCenter defaultCenter] postNotificationName:notiReceivedReject object:nil];
            break;

        //通话终止18
        case cricket::Session::STATE_DEINIT:
            [[NSNotificationCenter defaultCenter] postNotificationName:notiSessionDestroy object:nil];
            break;
            
        default:
            break;
    }
}

void VoiceClientDelegate::OnSignalCallTrackingId(int call_id, const char *call_tracker_id) {
    NSLog(@"------- Call Tracker Id %s for call_id %d", remote_jid_, call_id);
}

void VoiceClientDelegate::OnSignalAudioPlayout() {
    NSLog(@"------- OnSignalAudioPlayout");
}

void VoiceClientDelegate::OnSignalCallError(int error, int call_id) {
     NSLog(@"------- OnSignalCallError");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notiCallError object:nil];
}

void VoiceClientDelegate::OnSignalXmppError(int error) {
     NSLog(@"------- OnSignalXmppError");
}

void VoiceClientDelegate::OnSignalXmppSocketClose(int state) {
     NSLog(@"------- OnSignalXmppSocketClose");
}

void VoiceClientDelegate::OnSignalXmppStateChange(int state) {
     NSLog(@"------- OnSignalXmppStateChange");
}

void VoiceClientDelegate::OnPresenceChanged(const std::string& jid, int available, int show) {
     NSLog(@"------- OnPresenceChanged");
}

void VoiceClientDelegate::OnSignalBuddyListRemove(const std::string& jid) {
     NSLog(@"------- OnSignalBuddyListRemove");
}

void VoiceClientDelegate::OnSignalBuddyListAdd(const std::string& jid, const std::string& nick,
		int available, int show) {
     NSLog(@"------- OnSignalBuddyListAdd");
}

void VoiceClientDelegate::OnSignalStatsUpdate(const char *stats) {
    NSLog(@"------- OnSignalStatsUpdate:%s",stats);
}

#ifdef IOS_XMPP_FRAMEWORK
talk_base::Thread* VoiceClientDelegate::GetSignalThread()
{
    return voiceClient_->GetSignalThread();
}
#endif

void VoiceClientDelegate::WriteOutput(const char *bytes, size_t len)
{
    [xmppClientDelegate_ writeOutput:bytes withLenght:len];
}

void VoiceClientDelegate::StartTls(const std::string& domain) {
#if defined(FEATURE_ENABLE_SSL)
    [xmppClientDelegate_ startTLS:domain];
#endif
}

void VoiceClientDelegate::CloseConnection() {
    [xmppClientDelegate_ closeConnection];
    client_->ConnectionClosed(0);
    xmppClientDelegate_ = nil;
    client_ = NULL;
}

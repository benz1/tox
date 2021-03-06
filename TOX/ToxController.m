//
//  ToxController.m
//  TOX
//
//  Created by Daniel Parnell on 4/08/13.
//  Copyright (c) 2013 Daniel Parnell. All rights reserved.
//

#import "ToxController.h"
#import "ToxCore.h"
#import "ToxFriendRequestWindowController.h"
#import "ToxFriend.h"
#import "ToxConversationWindowController.h"
#import "SSKeychain.h"

//#define DEBUG_NOTIFICATIONS

static NSString* kToxService = @"Bane";
static NSString* kToxAccount = @"Account";

static ToxController* instance = nil;

@implementation ToxController {
    NSMutableDictionary* conversations;
}

+ (ToxController*) instance {
    return instance;
}

static NSDictionary* defaults_dict = nil;
+ (NSDictionary*) defaultValues {
    if(defaults_dict == nil) {
        NSString *localizedPath = [[NSBundle mainBundle] pathForResource: @"Defaults" ofType:@"plist"];
        NSData* plistData = [NSData dataWithContentsOfFile:localizedPath];
    
        defaults_dict = [NSPropertyListSerialization propertyListWithData: plistData options: NSPropertyListImmutable format: nil error: nil];
    }
    
    return defaults_dict;
}

- (id)init
{
    self = [super init];
    if (self) {
        instance = self;
        
        conversations = [NSMutableDictionary new];
        _friends = [NSMutableArray new];
        _status_icon = [NSImage imageNamed: @"offline"];
    }
    return self;
}

- (void) awakeFromNib {
    _friends_table.target = self;
    _friends_table.doubleAction = @selector(showConversation:);
    
    [self start];
}

- (void) start {
    NSError* error = nil;
    // Start up the Tox core
    ToxCore* core = [ToxCore instance];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];    
    
#ifdef DEBUG_NOTIFICATIONS
    [center addObserver: self selector: @selector(gotNotification:) name: nil object: core];
#endif
    
    // we want to know when the app will be terminated
    [center addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
    
    [center addObserver: self selector: @selector(connected:) name: kToxConnectedNotification object: core];
    [center addObserver: self selector: @selector(disconnected:) name: kToxDisconnectedNotification object: core];
    [center addObserver: self selector: @selector(gotFriendRequest:) name: kToxFriendRequestNotification object: core];
    [center addObserver: self selector: @selector(friendStatusChanged:) name: kToxFriendStatusChangedNotification object: core];
    [center addObserver: self selector: @selector(friendNickChanged:) name: kToxFriendNickChangedNotification object: core];
    [center addObserver: self selector: @selector(messageFromFriend:) name: kToxMessageNotification object: core];
    [center addObserver: self selector: @selector(actionFromFriend:) name: kToxActionNotification object: core];
    [center addObserver: self selector: @selector(messageRead:) name: kToxMessageReadNotification object: core];
    [center addObserver: self selector: @selector(friendRemoved:) name: kToxFriendRemovedNotification object: core];

    NSData* stateData = [SSKeychain passwordDataForService: kToxService account: kToxAccount];
    if(stateData == nil) {
        stateData = [SSKeychain passwordDataForService: @"TOX" account: kToxAccount];
        if(stateData) {
            // this is an old Project-TOX base state dump
            core.state = stateData;
        }
    } else {
        NSDictionary* dict = [NSKeyedUnarchiver unarchiveObjectWithData: stateData];
        
        core.state = [dict objectForKey: @"Core State"];
        self.friends = [[dict objectForKey: @"Friends"] mutableCopy];
        self.status = [dict objectForKey: @"Status"];
    }
    
    NSArray* dht_hosts = [[ToxController defaultValues] objectForKey: @"DHT Bootstrap Hosts"];
    NSString* dht_host = [dht_hosts objectAtIndex: arc4random() % dht_hosts.count];
    if(![core start: [NSURL URLWithString: dht_host] error: &error]) {
        [self showAlertForError: error];
    }    
}

#pragma mark -
#pragma mark Notifications

#ifdef DEBUG_NOTIFICATIONS
- (void) gotNotification:(NSNotification*)notification {
    NSLog(@"got: %@", notification);
}
#endif

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self saveState];
}

- (void) connected:(NSNotification*) notification {
    self.connected = YES;
    self.status_icon = [NSImage imageNamed: @"online"];
}

- (void) disconnected:(NSNotification*) notification {
    self.connected = NO;
    self.status_icon = [NSImage imageNamed: @"offline"];
}

- (void) gotFriendRequest:(NSNotification*)notifcation {
    NSString* client_id = [[notifcation userInfo] objectForKey: kToxPublicKey];
    if([[ToxCore instance] friendNumber: client_id error: nil] == -1) {
        [ToxFriendRequestWindowController newWithFriendRequest: [notifcation userInfo]];
    }
}

- (void) friendStatusChanged:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    int friend_num = [[dict objectForKey: kToxFriendNumber] intValue];
    NSString* status = [dict objectForKey: kToxNewFriendStatus];
    NSString* kind = [dict objectForKey: kToxNewFriendStatusKind];
    
    ToxFriend* friend = [self friendWithFriendNumber: friend_num];

    if(friend == nil) {
        friend = [ToxFriend newWithFriendNumber: friend_num];
        if(friend) {
            NSIndexSet* index_set = [NSIndexSet indexSetWithIndex: [_friends count]];
            [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
            [_friends addObject: friend];
            [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
        }
    }
    
    if(friend) {
        friend.status_message = status;
        friend.status_kind = kind;
        [friend updateStatusImage];
    }
    
}

- (void) friendNickChanged:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    int friend_num = [[dict objectForKey: kToxFriendNumber] intValue];
    NSString* nick = [dict objectForKey: kToxNewFriendNick];
    if(nick && [nick length]> 0) {
        ToxFriend* friend = [self friendWithFriendNumber: friend_num];
        
        if(friend == nil) {
            friend = [ToxFriend newWithFriendNumber: friend_num];
            if(friend) {
                friend.name = nick;
                NSIndexSet* index_set = [NSIndexSet indexSetWithIndex: [_friends count]];
                [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
                [_friends addObject: friend];
                [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
            }
        } else {
            friend.name = nick;
        }
    }
}

- (void) messageFromFriend:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    NSNumber* friend_number = [dict objectForKey: kToxFriendNumber];
    int friend_num = [friend_number intValue];
    ToxFriend* friend = [self friendWithFriendNumber: friend_num];
    
    if(friend == nil) {
        friend = [ToxFriend newWithFriendNumber: friend_num];
        if(friend) {
            NSIndexSet* index_set = [NSIndexSet indexSetWithIndex: [_friends count]];
            [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
            [_friends addObject: friend];
            [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
        }
    }
    
    ToxConversationWindowController* conversation = [conversations objectForKey: friend_number];
    if(conversation == nil) {
        conversation = [ToxConversationWindowController newWithFriendNumber: friend_num];
        [conversations setObject: conversation forKey: friend_number];
    }
    
    [conversation addMessage: dict];
}

- (void) actionFromFriend:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    NSNumber* friend_number = [dict objectForKey: kToxFriendNumber];
    int friend_num = [friend_number intValue];
    ToxFriend* friend = [self friendWithFriendNumber: friend_num];
    
    if(friend == nil) {
        friend = [ToxFriend newWithFriendNumber: friend_num];
        if(friend) {
            NSIndexSet* index_set = [NSIndexSet indexSetWithIndex: [_friends count]];
            [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
            [_friends addObject: friend];
            [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
        }
    }
    
    ToxConversationWindowController* conversation = [conversations objectForKey: friend_number];
    if(conversation == nil) {
        conversation = [ToxConversationWindowController newWithFriendNumber: friend_num];
        [conversations setObject: conversation forKey: friend_number];
    }
    
    [conversation addAction: dict];
}

- (void) messageRead:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    NSNumber* friend_number = [dict objectForKey: kToxFriendNumber];
    int friend_num = [friend_number intValue];
    ToxFriend* friend = [self friendWithFriendNumber: friend_num];
    
    if(friend == nil) {
        friend = [ToxFriend newWithFriendNumber: friend_num];
        if(friend) {
            NSIndexSet* index_set = [NSIndexSet indexSetWithIndex: [_friends count]];
            [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
            [_friends addObject: friend];
            [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: index_set forKey: @"friends"];
        }
    }
    
    ToxConversationWindowController* conversation = [conversations objectForKey: friend_number];
    if(conversation == nil) {
        conversation = [ToxConversationWindowController newWithFriendNumber: friend_num];
        [conversations setObject: conversation forKey: friend_number];
    }
    
    [conversation messageRead: [dict objectForKey: kToxMessageNumber]];
}

- (void) friendRemoved:(NSNotification*)notification {
    NSDictionary* dict = [notification userInfo];
    NSNumber* friend_number = [dict objectForKey: kToxFriendNumber];
    int friend_num = [friend_number intValue];
    NSUInteger index = [self indexOfFriendWithNumber: friend_num];
    
    NSIndexSet* is = [NSIndexSet indexSetWithIndex: index];
    [self willChange: NSKeyValueChangeRemoval valuesAtIndexes: is forKey: @"friends"];
    [_friends removeObjectAtIndex: index];
    [self didChange: NSKeyValueChangeRemoval valuesAtIndexes: is forKey: @"friends"];
}

#pragma mark -
#pragma mark Alert stuff

- (void) showAlertForError:(NSError*) error {
    [[NSAlert alertWithError: error] beginSheetModalForWindow: self.window
                                                modalDelegate: self
                                               didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:)
                                                  contextInfo: nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [[alert window] orderOut: nil];
}

#pragma mark -
#pragma mark Add sheet methods


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut: self];
}

#pragma mark -
#pragma mark Methods

- (NSUInteger) indexOfFriendWithNumber:(int) friend_number {
    return [_friends indexOfObjectPassingTest:^BOOL(ToxFriend* obj, NSUInteger idx, BOOL *stop) {
        if(obj.friend_number == friend_number) {
            return YES;
        }
        
        return NO;
    }];
}
- (ToxFriend*) friendWithFriendNumber:(int)friend_number {
    NSUInteger index = [self indexOfFriendWithNumber: friend_number];
    
    if(index == NSNotFound) {
        return nil;
    }
    
    return [_friends objectAtIndex: index];
}

- (void) removeConversionWithFriendNumber:(int)friend_number {
    NSNumber* key = [NSNumber numberWithInt: friend_number];
    
    [conversations removeObjectForKey: key];
}

- (void) saveState {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [[ToxCore instance] state], @"Core State",
                          _friends, @"Friends",
                          _status, @"Status",
                          nil];
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject: dict];
    
    [SSKeychain setPasswordData: data forService: kToxService account: kToxAccount];
}

#pragma mark -
#pragma mark properties

- (void) setStatus:(NSString *)status {
    _status = status;
    ToxCore* core = [ToxCore instance];
    core.user_status = status;
}

#pragma mark -
#pragma mark Actions

- (IBAction) copyPublicKeyToClipboard:(id)sender {
    NSPasteboard* pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString: [[ToxCore instance] public_key] forType: NSPasteboardTypeString];
}

- (IBAction) showMainWindow:(id)sender {
    [self.window makeKeyAndOrderFront: sender];
}

- (IBAction) showConversation:(id)sender {
    NSInteger row = _friends_table.selectedRow;
    if(row >= 0) {
        ToxFriend* friend = [_friends objectAtIndex: row];
        int friend_num = friend.friend_number;
        NSNumber* friend_number = [NSNumber numberWithInt: friend_num];
        
        ToxConversationWindowController* conversation = [conversations objectForKey: friend_number];
        if(conversation == nil) {
            conversation = [ToxConversationWindowController newWithFriendNumber: friend_num];
            [conversations setObject: conversation forKey: friend_number];
        }
        
        [conversation.window makeKeyAndOrderFront: self];
    }
}

- (IBAction) addFriend:(id)sender {
    self.add_public_key = @"";
    self.add_message = NSLocalizedString(@"I would like to be your friend", @"Friend message");
    
    [NSApp beginSheet: self.add_panel modalForWindow: self.window modalDelegate: self didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: nil];
}

- (IBAction) performAddFriend:(id)sender {
    NSError* error = nil;
    [NSApp endSheet: _add_panel];
    
    if(![[ToxCore instance] sendFriendRequestTo: _add_public_key message: _add_message error: &error]) {
        [self showAlertForError: error];
    }
}

- (IBAction) cancelAddFriend:(id)sender {
    [NSApp endSheet: _add_panel];
}

@end

//
//  ToxFriend.m
//  TOX
//
//  Created by Daniel Parnell on 4/08/13.
//  Copyright (c) 2013 Daniel Parnell. All rights reserved.
//

#import "ToxFriend.h"
#import "ToxCore.h"

@implementation ToxFriend

+ (ToxFriend*) newWithFriendNumber:(int)friend_number {
    return [[ToxFriend alloc] initWithFriendNumber: friend_number];
}

- (id) initWithFriendNumber:(int)friend_number {
    ToxCore* core = [ToxCore instance];
    
    NSString* client_id = [core clientIdForFriend: friend_number error: nil];
    if(client_id) {
        self = [super init];
        if(self) {
            _public_key = client_id;
            _name = [core friendName: friend_number error: nil];
            _status_message = [core friendStatus: friend_number error: nil];
        }
    
        return self;
    }
    
    return nil;
}

@end
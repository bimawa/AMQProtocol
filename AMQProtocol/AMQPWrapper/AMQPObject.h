
//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "amqp.h"

@interface AMQPObject : NSObject

- (NSString*)errorDescriptionForReply:(amqp_rpc_reply_t)reply;

@end
//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <UIKit/UIKit.h>

@class AMQPConsumerThread;
@class AMQPMessage;

@protocol AMQPConsumerThreadDelegate

- (void)amqpConsumerThreadReceivedNewMessage:(AMQPMessage*)theMessage;
-(void)amqpConsumerThreadLoseConnection;

@end

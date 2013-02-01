
//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "AMQPConsumerThreadDelegate.h"

@class AMQPConnection;
@class AMQPChannel;
@class AMQPQueue;
@class AMQPConsumer;
@class AMQPMessage;

@interface AMQPConsumerThread : NSThread
{
	AMQPConsumer *consumer;

    NSObject<AMQPConsumerThreadDelegate> *delegate;
}

@property (strong) NSObject<AMQPConsumerThreadDelegate> *delegate;

- (id)initWithConsumer:(AMQPConsumer *)theConsumer delegate:(NSObject <AMQPConsumerThreadDelegate> *)deleGate nameThread:(NSString *)name;
- (void)main;

@end

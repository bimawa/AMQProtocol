//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>
#import "amqp.h"

#import "AMQPObject.h"

@class AMQPChannel;
@class AMQPQueue;
@class AMQPMessage;

@interface AMQPConsumer : AMQPObject
{
	AMQPChannel *channel;
	AMQPQueue *queue;
	BOOL isAck;
	amqp_bytes_t consumer;
}

@property (readonly) amqp_bytes_t internalConsumer;
@property (readonly) AMQPChannel *channel;
@property (readonly) AMQPQueue *queue;

- (id)initForQueue:(AMQPQueue *)theQueue onChannel:(__strong AMQPChannel **)theChannel useAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local error:(NSError **)error deepLoop:(int)deep;

- (void)closeConsumer;

- (void)dealloc;

- (AMQPMessage *)popWithTimer:(NSInteger)timeOut;

@end

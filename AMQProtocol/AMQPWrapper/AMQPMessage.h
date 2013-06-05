//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <UIKit/UIKit.h>
#import "amqp.h"
#import "amqp_framing.h"

@class AMQPConsumer;

@interface AMQPMessage : NSObject
{
	NSString *body;
    NSData *rawBody;
	// from properties
	NSString *contentType;
	NSString *contentEncoding;
	amqp_table_t headers;
	uint deliveryMode;
	uint priority;
	NSString *correlationID;
	NSString *replyToQueueName;
	NSString *expiration;
	NSString *messageID;
	uint timestamp;
	NSString *type;
	NSString *userID;
	NSString *appID;
	NSString *clusterID;
	
	//from method
	NSString *consumerTag;
	uint deliveryTag;
	BOOL redelivered;
	NSString *exchangeName;
	NSString *routingKey;
	
	BOOL read;
	NSDate *receivedAt;
}

@property (readonly) NSString *body;

@property (readonly) NSString *contentType;
@property (readonly) NSString *contentEncoding;
@property (readonly) amqp_table_t headers;
@property (readonly) uint deliveryMode;
@property (readonly) uint priority;
@property (readonly) NSString *correlationID;
@property (readonly) NSString *replyToQueueName;
@property (readonly) NSString *expiration;
@property (readonly) NSString *messageID;
@property (readonly) uint timestamp;
@property (readonly) NSString *type;
@property (readonly) NSString *userID;
@property (readonly) NSString *appID;
@property (readonly) NSString *clusterID;

@property (readonly) NSString *consumerTag;
@property (readonly) uint deliveryTag;
@property (readonly) BOOL redelivered;
@property (readonly) NSString *exchangeName;
@property (readonly) NSString *routingKey;

@property BOOL read;
@property (readonly) NSDate *receivedAt;

@property(nonatomic, strong) NSData *rawBody;

+ (AMQPMessage *)messageFromBody:(amqp_bytes_t)theBody withDeliveryProperties:(amqp_basic_deliver_t *)theDeliveryProperties withMessageProperties:(amqp_basic_properties_t *)theMessageProperties receivedAt:(NSDate *)receiveTimestamp;

- (id)initWithBody:(amqp_bytes_t)theBody withDeliveryProperties:(amqp_basic_deliver_t *)theDeliveryProperties withMessageProperties:(amqp_basic_properties_t *)theMessageProperties receivedAt:(NSDate *)receiveTimestamp;
- (id)initWithAMQPMessage:(AMQPMessage*)theMessage;

@end

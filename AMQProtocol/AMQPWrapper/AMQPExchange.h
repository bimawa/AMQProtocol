
//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "amqp.h"

#import "AMQPObject.h"
#import "amqp.h"
#import "amqp_framing.h"

#import "config.h"
#import "AMQPChannel.h"
@class AMQPChannel;

@interface AMQPExchange : AMQPObject
{
	amqp_bytes_t exchange;
	
	AMQPChannel *channel;
}

@property (readonly) amqp_bytes_t internalExchange;

- (id)initExchangeOfType:(NSString*)theType withName:(NSString*)theName onChannel:(AMQPChannel*)theChannel  isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError**)error;
- (id)initDirectExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError**)error;
- (id)initFanoutExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError**)error;
- (id)initTopicExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError**)error;
- (id)initExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel;

- (void)dealloc;

- (BOOL)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey propertiesMessage:(amqp_basic_properties_t)props mandatory:(BOOL)isMandatory immediate:(BOOL)isImmediate error:(NSError **)error;

- (void)destroy;


@end

//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPExchange.h"
#include "amqp.h"


@implementation AMQPExchange {
    AMQPUtilities *utilities;
}

@synthesize internalExchange = exchange;

- (id)initExchangeOfType:(NSString*)theType withName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
    *error=nil;
	if(self = [super init])
    {
        channel = theChannel;
        if (![channel isOpen])
        {

            channel = [channel.connection openChannelError:error];
            if (*error != nil)
            {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Failed to declare wxchange channel is closed:"
                               forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-17 userInfo:errorDetail];
                [channel setIsOpen:NO];
                return nil;
            }
        }
        amqp_exchange_declare(channel.connection.internalConnection, channel.internalChannel,
                amqp_cstring_bytes([theName UTF8String]), amqp_cstring_bytes([theType UTF8String]), passive,
                durable,
                autoDelete, AMQP_EMPTY_TABLE);
        if ([channel.connection checkLastOperation:@"Failed to declare exchange"])
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return nil;
        }
        exchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
        channel = theChannel;
    }
	return self;
}
- (id)initDirectExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
	return [self initExchangeOfType:@"direct" withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete error:error];
}
- (id)initFanoutExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
	return [self initExchangeOfType:@"fanout" withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete  error:error];
}
- (id)initTopicExchangeWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
	return [self initExchangeOfType:@"topic" withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete  error:error];
}

- (id)initExchangeWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel error:(NSError **)error
{
    *error=nil;
    if(self = [super init])
	{
		exchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
        if ([theChannel isOpen])
        {
            channel = theChannel;
        }else{
            channel = [[theChannel connection] openChannelError:error];
            if (*error!= nil)
            {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Failed to open channel:" forKey:NSLocalizedDescriptionKey];
                *error= [NSError errorWithDomain:NSStringFromClass([self class]) code:-5 userInfo:errorDetail];
                [channel setIsOpen:NO];
                return nil;
            }
        }

	}
	
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(exchange);
}

- (BOOL)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey propertiesMessage:(amqp_basic_properties_t)props mandatory:(BOOL)isMandatory immediate:(BOOL)isImmediate error:(NSError **)error
{
    *error=nil;
    if (![channel isOpen])
    {
        [channel.connection openChannelError:error];
        if (*error != nil)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare wxchange channel is closed:" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-17 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return NO;
        }
    }
    amqp_basic_publish(channel.connection.internalConnection, channel.internalChannel, exchange,
            amqp_cstring_bytes([theRoutingKey UTF8String]), isMandatory, isImmediate, &props,
            amqp_cstring_bytes([body UTF8String]));
    if ([channel.connection checkLastOperation:@"Failed to publish message"])
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to publish message:" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-10 userInfo:errorDetail];
        [channel setIsOpen:NO];
        return NO;
    }
    return YES;
}

- (BOOL)publishMessageData:(NSData *)data usingRoutingKey:(NSString *)theRoutingKey propertiesMessage:(amqp_basic_properties_t)props mandatory:(BOOL)isMandatory immediate:(BOOL)isImmediate error:(NSError **)error{
    *error=nil;
    if (![channel isOpen])
    {
        [channel.connection openChannelError:error];
        if (*error != nil)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare wxchange channel is closed:" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-17 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return NO;
        }
    }
    amqp_bytes_t amqp_data;
    amqp_data.len = [data length];
    amqp_data.bytes = [data bytes];

    amqp_basic_publish(channel.connection.internalConnection, channel.internalChannel, exchange,
            amqp_cstring_bytes([theRoutingKey UTF8String]), isMandatory, isImmediate, &props,
            amqp_data);
    if ([channel.connection checkLastOperation:@"Failed to publish message"])
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to publish message:" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-10 userInfo:errorDetail];
        [channel setIsOpen:NO];
        return NO;
    }
    return YES;
}

-(void)destroy {
    amqp_exchange_delete(channel.connection.internalConnection, channel.internalChannel, exchange, 0,0);
}
@end

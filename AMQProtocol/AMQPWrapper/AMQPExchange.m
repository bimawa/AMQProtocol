//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPExchange.h"



@implementation AMQPExchange {
    AMQPUtilities *utilities;
}

@synthesize internalExchange = exchange;

- (id)initExchangeOfType:(NSString*)theType withName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
	if(self = [super init]) {
        utilities = [AMQPUtilities new];
        __block ERRORCODE isCompliete = ERRORCODE_NORESPONSE;
        __block NSError *errorInformer = *error;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (theChannel == nil) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Chanel has Null!" forKey:NSLocalizedDescriptionKey];
                errorInformer = [NSError errorWithDomain:NSStringFromClass([self class]) code:-5 userInfo:errorDetail];
                isCompliete = ERRORCODE_HASERROR;
                return;
            }
            amqp_exchange_declare(theChannel.connection.internalConnection, theChannel.internalChannel, amqp_cstring_bytes([theName UTF8String]), amqp_cstring_bytes([theType UTF8String]), passive, durable, autoDelete, AMQP_EMPTY_TABLE);
            if ([channel.connection checkLastOperation:@"Failed to declare exchange"]) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
                errorInformer = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
                isCompliete = ERRORCODE_HASERROR;
                return;
            }
            exchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
            channel = theChannel;
            isCompliete = ERRORCODE_NORMAL;
            return;
        });
        NSError *timerError=nil;
        [utilities waitingRespondsInSec:.1 forKey:(ERRORCODE **) &isCompliete exitAfterTryCounter:10 error:&timerError];
        if (isCompliete==ERRORCODE_HASERROR){
            if (errorInformer== nil){
                *error=timerError;
            }else{
                *error=errorInformer;
            }
        }
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
-(id)initExchangeWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel{
    if(self = [super init])
	{
		exchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
		channel = theChannel;
	}
	
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(exchange);
}

- (BOOL)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey propertiesMessage:(amqp_basic_properties_t)props mandatory:(BOOL)isMandatory immediate:(BOOL)isImmediate error:(NSError **)error {

    amqp_basic_publish(channel.connection.internalConnection, channel.internalChannel, exchange, amqp_cstring_bytes([theRoutingKey UTF8String]), isMandatory, isImmediate, &props, amqp_cstring_bytes([body UTF8String]));

    if ([channel.connection checkLastOperation:@"Failed to publish message"]) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to publish message:" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-10 userInfo:errorDetail];
        return false;
    }
    return true;
}

-(void)destroy {
    amqp_exchange_delete(channel.connection.internalConnection, channel.internalChannel, exchange, 0,0);
}
@end

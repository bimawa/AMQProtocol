//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPQueue.h"
#import "amqp_framing.h"

#import "AMQPChannel.h"
#import "AMQPExchange.h"

@implementation AMQPQueue {
    AMQPUtilities *utilities;
}

@synthesize internalQueue = queueName;

- (id)initWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isExclusive:(BOOL)exclusive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError **)error
{
	if(self = [super init])
	{
        utilities = [AMQPUtilities new];
        __block int isReadyData=0;
        __block amqp_queue_declare_ok_t *declaration;
        declaration = amqp_queue_declare((theChannel).connection.internalConnection, (theChannel).internalChannel, amqp_cstring_bytes([theName UTF8String]), passive, durable, exclusive, autoDelete, AMQP_EMPTY_TABLE);
        if([channel.connection checkLastOperation:@"Failed to declare queue"]||declaration==nil){
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare queue" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-8 userInfo:errorDetail];
            return nil;
        }
		queueName = amqp_bytes_malloc_dup(declaration->queue);
		channel =theChannel;
	}
	
	return self;
}
-(id)initWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel{
    if(self = [super init])
	{
        queueName = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
		channel = theChannel;
	}
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(queueName);
}

- (BOOL)bindToExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError **)error
{

	amqp_queue_bind(channel.connection.internalConnection, channel.internalChannel, queueName, theExchange.internalExchange, amqp_cstring_bytes([bindingKey UTF8String]), AMQP_EMPTY_TABLE);
	if([channel.connection checkLastOperation:@"Failed to bind queue to exchange"]){
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"Failed to bind queue to exchange" forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-7 userInfo:errorDetail];
		return false;
	}
	return true;
}
- (BOOL)unbindFromExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError **)error
{

	amqp_queue_unbind(channel.connection.internalConnection, channel.internalChannel, queueName, theExchange.internalExchange, amqp_cstring_bytes([bindingKey UTF8String]), AMQP_EMPTY_TABLE);
	if([channel.connection checkLastOperation:@"Failed to unbind queue from exchange"]){
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"Failed to unbind queue from exchange" forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-6 userInfo:errorDetail];
		return false;
	}
	return true;
}
-(void)destroy{
    amqp_queue_delete(channel.connection.internalConnection, channel.internalChannel, queueName, 0, 0);
}

@end

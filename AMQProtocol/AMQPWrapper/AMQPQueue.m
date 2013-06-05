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
    *error=nil;
	if(self = [super init])
    {
        channel = theChannel;
        if (![theChannel isOpen])
        {
            channel = [[theChannel connection] openChannelError:error];
            if (*error != nil)
            {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
                [channel setIsOpen:NO];
                return nil;
            }
        }
        utilities = [AMQPUtilities new];
        amqp_queue_declare_ok_t *declaration;
        declaration = amqp_queue_declare(channel.connection.internalConnection, channel.internalChannel,
                amqp_cstring_bytes([theName UTF8String]), passive, durable, exclusive, autoDelete, AMQP_EMPTY_TABLE);
        if ([channel.connection checkLastOperation:@"Failed to declare queue"] || declaration == nil)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare queue" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-8 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return nil;
        }
        queueName = amqp_bytes_malloc_dup(declaration->queue);
    }
	return self;
}

- (id)initWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel error:(NSError **)error
{
    if(self = [super init])
	{
        channel = theChannel;
        if (![channel isOpen])
        {
            channel = [[theChannel connection] openChannelError:error];
            if (*error != nil)
            {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
                [channel setIsOpen:NO];
                return nil;
            }
        }
        queueName = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
	}
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(queueName);
}

-(BOOL)purgeNoWait:(BOOL)noWait error:(NSError **)error
{
    *error = nil;
    amqp_queue_purge(channel.connection.internalConnection, channel.internalChannel, queueName,
            noWait);

    if([channel.connection checkLastOperation:@"Failed to unbind queue from exchange"]){
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to unbind queue from exchange" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-6 userInfo:errorDetail];
        [channel setIsOpen:NO];

    }
    if (*error != nil)
    {
        return NO;
    }
    return YES;
}

- (BOOL)bindToExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError **)error
{
    if (![channel isOpen])
    {
        channel = [[channel connection] openChannelError:error];
        if (*error != nil)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return nil;
        }
    }
    amqp_queue_bind(channel.connection.internalConnection, channel.internalChannel, queueName, theExchange.internalExchange, amqp_cstring_bytes([bindingKey UTF8String]), AMQP_EMPTY_TABLE);
    if([channel.connection checkLastOperation:@"Failed to bind queue from exchange"]){
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to unbind queue from exchange" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-7 userInfo:errorDetail];
        [channel setIsOpen:NO];
        return NO;
    }
    return YES;
}
- (BOOL)unbindFromExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError **)error
{
    if (![channel isOpen])
    {
        channel = [[channel connection] openChannelError:error];
        if (*error != nil)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to declare exchange:" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-13 userInfo:errorDetail];
            [channel setIsOpen:NO];
            return nil;
        }
    }

    amqp_queue_unbind(channel.connection.internalConnection, channel.internalChannel, queueName, theExchange.internalExchange, amqp_cstring_bytes([bindingKey UTF8String]), AMQP_EMPTY_TABLE);
    if([channel.connection checkLastOperation:@"Failed to unbind queue from exchange"]){
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to unbind queue from exchange" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-6 userInfo:errorDetail];
        [channel setIsOpen:NO];

    }
    if (*error != nil)
    {

        channel=[channel.connection openChannelError:error];
        return NO;
    }
    return YES;
}
-(void)destroy{
    amqp_queue_delete(channel.connection.internalConnection, channel.internalChannel, queueName, 0, 0);
}

@end



#import <UIKit/UIKit.h>

#import "amqp.h"

#import "AMQPObject.h"

@class AMQPChannel;
@class AMQPExchange;
@class AMQPConsumer;
@class AMQPMessage;

@interface AMQPQueue : AMQPObject
{
	amqp_bytes_t queueName;
	
	AMQPChannel *channel;
}

@property (readonly) amqp_bytes_t internalQueue;

- (id)initWithName:(NSString*)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isExclusive:(BOOL)exclusive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete error:(NSError**)error;

- (id)initWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel error:(NSError **)error;

//No declare
- (void)dealloc;

- (BOOL)purgeNoWait:(BOOL)noWait error:(NSError **)error;

- (BOOL)bindToExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError**)error;
- (BOOL)unbindFromExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey error:(NSError**)error;

- (void)destroy;


@end

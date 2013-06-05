//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "AMQPChannel.h"
#import "amqp_framing.h"
@implementation AMQPChannel

@synthesize internalChannel = channel;
@synthesize connection;

@synthesize isOpen;

- (id)init
{
	if(self = [super init])
	{
		channel = (amqp_channel_t) -1;
		connection = nil;
        utilities = [AMQPUtilities new];
        isOpen=NO;
	}
	
	return self;
}

- (void)openChannel:(unsigned int)theChannel onConnection:(AMQPConnection *)theConnection error:(NSError **)error
{
    *error=nil;
    channel=theChannel;
    connection = theConnection;
    amqp_channel_open(connection.internalConnection, channel);
    if ([connection checkLastOperation:@"Failed to open a channel"])
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to open a channel" forKey:NSLocalizedDescriptionKey];
        *error= [NSError errorWithDomain:NSStringFromClass([self class]) code:-5 userInfo:errorDetail];
        [self setIsOpen:NO];
        return;
    }
    [self setIsOpen:YES];
    return;
}
- (void)setupBasicQOS{
    amqp_basic_qos(connection.internalConnection, channel, 0, 5,0);
}
- (void)close
{
    [self setIsOpen:NO];
    amqp_channel_close(connection.internalConnection, channel, AMQP_REPLY_SUCCESS);
}
@end

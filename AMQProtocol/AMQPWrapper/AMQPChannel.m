//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "AMQPChannel.h"

#import "amqp.h"
#import "amqp_framing.h"

@implementation AMQPChannel

@synthesize internalChannel = channel;
@synthesize connection;

- (id)init
{
	if(self = [super init])
	{
		channel = -1;
		connection = nil;
	}
	
	return self;
}
/*- (void)dealloc {
    NSLog(@"Connection in Chanel?>>>>>>>>:%@ channel: %d", connection,channel);
//    [self close];
}*/
- (BOOL)openChannel:(unsigned int)theChannel onConnection:(AMQPConnection*)theConnection error:(NSError **)error
{
	connection = theConnection;
	channel = theChannel;
    if (connection == nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:@"Failed Connection is Lost"] forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-14 userInfo:errorDetail];
        return false;
    }
	amqp_channel_open(connection.internalConnection, channel);
	if([connection checkLastOperation:@"Failed to open a channel"]){
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"Failed to open a channel" forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-5 userInfo:errorDetail];
		return false;
	}
	return true;
}
- (void)close
{
    amqp_channel_close(connection.internalConnection, channel, AMQP_REPLY_SUCCESS);
}
+(void)closeChanelByNumber:(uint)channelNum connection:(AMQPConnection *)connect{
    amqp_channel_close(connect.internalConnection, channelNum, AMQP_REPLY_SUCCESS);
}
@end

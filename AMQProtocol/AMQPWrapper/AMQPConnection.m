//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <sys/socket.h>
#import "AMQPConnection.h"

#import "amqp.h"
#import "amqp_framing.h"
#import "unistd.h"

#import "AMQPChannel.h"

@implementation AMQPConnection

@synthesize internalConnection = connection,nextChannel_=nextChannel;

- (id)init
{
	if(self = [super init])
	{
		connection = amqp_new_connection();
		nextChannel = 1;

	}
	
	return self;
}
- (void)dealloc
{
	NSError *error=nil;
	[self disconnectError:&error];
	if(error!=nil){
		NSLog(@"Error disconnect from server: %@",error);
		return;
	}
	amqp_destroy_connection(connection);

}

- (BOOL)connectToHost:(NSString*)host onPort:(int)port error:(NSError **)error
{

    socketFD = amqp_open_socket([host UTF8String], port);
	
	if(socketFD < 0)
	{
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:[NSString stringWithFormat:@"Unable to open socket to host %@ on port %d", host, port] forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-4 userInfo:errorDetail];
		return false;
	}
    amqp_set_sockfd(connection, socketFD);
    return true;
}
- (BOOL)loginAsUser:(NSString*)username withPasswort:(NSString*)password onVHost:(NSString*)vhost error:(NSError **)error {
    if (connection == nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed Connection is Lost", @"Failed Connection is Lost")] forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-14 userInfo:errorDetail];
        return false;
    }
    amqp_rpc_reply_t reply = amqp_login(connection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);

    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed to login on server.", @"Failed to login on server.")] forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-3 userInfo:errorDetail];
        return false;
    }

    return true;
}
- (BOOL)disconnectError:(NSError **)error
{
    if (connection == nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed Connection is Lost", @"Failed Connection is Lost")] forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-14 userInfo:errorDetail];
        return false;
    }
	amqp_rpc_reply_t reply = amqp_connection_close(connection, AMQP_REPLY_SUCCESS);
	
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:[NSString stringWithFormat:@"Unable to disconnect from host: %@", [self errorDescriptionForReply:reply]] forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-2 userInfo:errorDetail];

        close(socketFD);
        return false;
	}
	close(socketFD);
	return true;
}

- (BOOL)checkLastOperation:(NSString*)context
{
	BOOL result=false;

	amqp_rpc_reply_t reply = amqp_get_rpc_reply(connection);
	
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		result=true;
		NSLog(@"AMQPException: %@: %@", context, [self errorDescriptionForReply:reply]);
	}
	return result;
}

- (AMQPChannel*)openChannel
{

    AMQPChannel *channel = [[AMQPChannel alloc] init];
	NSError *error=nil;
	[channel openChannel:nextChannel onConnection:self error:&error];
	if (error!=nil){
		NSLog(@"%@",error);
        nextChannel++;
		return nil;
	}
	nextChannel++;

	return channel;
}

@end

//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "AMQPConnection.h"
#import "amqp_framing.h"
#import "AMQPChannel.h"

@implementation AMQPConnection

@synthesize internalConnection = connection;

- (id)init
{
	if(self = [super init])
	{
		connection = amqp_new_connection();
		nextChannel = 1;
        utilities = [AMQPUtilities new];
        lock = [NSLock new];
	}
	return self;
}
- (void)dealloc
{
	NSError *error=nil;
	[self disconnectError:&error];
	if(error!=nil){
		NSLog(@"TCLib>> Error disconnect from server: %@",error);
		return;
	}
	amqp_destroy_connection(connection);

}

- (void)connectToHost:(NSString *)host onPort:(int)port error:(NSError **)error
{
    *error=nil;
    socketFD = amqp_open_socket([host UTF8String], port);
    if(socketFD < 0)
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:@"Unable to open socket to host %@ on port %d", host, port] forKey:NSLocalizedDescriptionKey];
        *error= [NSError errorWithDomain:NSStringFromClass([self class]) code:-4 userInfo:errorDetail];
        return;
    }
    amqp_set_sockfd(connection, socketFD);
}
- (void)loginAsUser:(NSString *)username withPasswort:(NSString *)password onVHost:(NSString *)vhost error:(NSError **)error {
    *error=nil;
    amqp_rpc_reply_t reply = amqp_login(connection, [vhost UTF8String], 0, 131072/*131072*/, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed to login on server.", @"Failed to login on server.")] forKey:NSLocalizedDescriptionKey];
        *error= [NSError errorWithDomain:NSStringFromClass([self class]) code:-3 userInfo:errorDetail];
        return;
    }
    return;
}
- (void)disconnectError:(NSError **)error
{
    *error=nil;
    amqp_rpc_reply_t reply = amqp_connection_close(connection, AMQP_REPLY_SUCCESS);
    if(reply.reply_type != AMQP_RESPONSE_NORMAL)
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:@"Unable to disconnect from host: %@", [self errorDescriptionForReply:reply]] forKey:NSLocalizedDescriptionKey];
        *error= [NSError errorWithDomain:NSStringFromClass([self class]) code:-2 userInfo:errorDetail];
        return;
    }else
    {
        close(socketFD);
    }
}

- (BOOL)checkLastOperation:(NSString *)context {
	//TODO: Мульти треди возможно и не нужен функция amqp_get_rpc_reply просто читает состояние у стурктуры.
    BOOL result=false;
	amqp_rpc_reply_t reply = amqp_get_rpc_reply(connection);
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		result=true;
        switch(reply.reply_type ){
            case AMQP_RESPONSE_NONE:
		        NSLog(@"TCLib>> AMQPException AMQP_RESPONSE_NONE: %@: %@", context, [self errorDescriptionForReply:reply]);
                break;
            case AMQP_RESPONSE_NORMAL:
		        NSLog(@"TCLib>> AMQPException AMQP_RESPONSE_NORMAL: %@: %@", context, [self errorDescriptionForReply:reply]);
                break;
            case AMQP_RESPONSE_LIBRARY_EXCEPTION:
		        NSLog(@"TCLib>> AMQPException AMQP_RESPONSE_LIBRARY_EXCEPTION: %@: %@", context, [self errorDescriptionForReply:reply]);
                break;
            case AMQP_RESPONSE_SERVER_EXCEPTION:
		        NSLog(@"TCLib>> AMQPException AMQP_RESPONSE_SERVER_EXCEPTION: %@: %@", context, [self errorDescriptionForReply:reply]);
                break;
        }
	}
	return result;
}

- (AMQPChannel *)openChannelError:(NSError **)errorOpenChannel {
    *errorOpenChannel=nil;
    AMQPChannel *channel = [[AMQPChannel alloc] init];
//    [lock lock];

    [channel openChannel:nextChannel++ onConnection:self error:errorOpenChannel];
    if (*errorOpenChannel!=nil){
        NSLog(@"TCLib>> open channel error: %@",*errorOpenChannel);
        return nil;
    }
//    [lock unlock];
    return channel;
}

@end

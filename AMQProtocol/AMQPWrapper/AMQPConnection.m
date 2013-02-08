//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "AMQPConnection.h"
#import "amqp_framing.h"
#import "AMQPChannel.h"

@implementation AMQPConnection

@synthesize internalConnection = connection,nextChannel_=nextChannel;

- (id)init
{
	if(self = [super init])
	{
		connection = amqp_new_connection();
		nextChannel = 1;
        utilities = [AMQPUtilities new];
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

- (void)connectToHost:(NSString *)host onPort:(int)port error:(NSError **)error
{
    __block ERRORCODE isCompliete=ERRORCODE_NORESPONSE;
    __block NSError *errorInformer= nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        socketFD = amqp_open_socket([host UTF8String], port);
        if(socketFD < 0)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat:@"Unable to open socket to host %@ on port %d", host, port] forKey:NSLocalizedDescriptionKey];
            errorInformer = [NSError errorWithDomain:NSStringFromClass([self class]) code:-4 userInfo:errorDetail];
            isCompliete=ERRORCODE_HASERROR;
            return;
        }
        isCompliete=ERRORCODE_NORMAL;
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
    }else{
        amqp_set_sockfd(connection, socketFD);
    }

}
- (void)loginAsUser:(NSString *)username withPasswort:(NSString *)password onVHost:(NSString *)vhost error:(NSError **)error {
    __block ERRORCODE isCompliete=ERRORCODE_NORESPONSE;
    __block NSError *errorInformer= nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        amqp_rpc_reply_t reply = amqp_login(connection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
        if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed to login on server.", @"Failed to login on server.")] forKey:NSLocalizedDescriptionKey];
            errorInformer= [NSError errorWithDomain:NSStringFromClass([self class]) code:-3 userInfo:errorDetail];
            isCompliete=ERRORCODE_HASERROR;
            return;
        }
        isCompliete=ERRORCODE_NORMAL;
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
- (void)disconnectError:(NSError **)error
{

    __block ERRORCODE isCompliete =ERRORCODE_NORESPONSE;
    __block NSError *errorInformer=nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        amqp_rpc_reply_t reply = amqp_connection_close(connection, AMQP_REPLY_SUCCESS);
        if(reply.reply_type != AMQP_RESPONSE_NORMAL)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat:@"Unable to disconnect from host: %@", [self errorDescriptionForReply:reply]] forKey:NSLocalizedDescriptionKey];
            errorInformer = [NSError errorWithDomain:NSStringFromClass([self class]) code:-2 userInfo:errorDetail];
            isCompliete =ERRORCODE_HASERROR;
            return;
        }
        close(socketFD);
        isCompliete =ERRORCODE_NORMAL;
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

- (BOOL)checkLastOperation:(NSString*)context
{
	//TODO: Мульти треди возможно и не нужен функция amqp_get_rpc_reply просто читает состояние у стурктуры.
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
        [channel openChannel:nextChannel++ onConnection:self error:&error];
        if (error!=nil){
            NSLog(@"%@",error);
            return nil;
        }
        return channel;
}

@end

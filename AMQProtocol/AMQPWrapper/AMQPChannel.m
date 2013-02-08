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
		channel = (amqp_channel_t) -1;
		connection = nil;
        utilities = [AMQPUtilities new];
	}
	
	return self;
}
/*- (void)dealloc {
    NSLog(@"Connection in Chanel?>>>>>>>>:%@ channel: %d", connection,channel);
//    [self close];
}*/
- (void)openChannel:(unsigned int)theChannel onConnection:(AMQPConnection *)theConnection error:(NSError **)error
{
    connection = theConnection;
	channel = (amqp_channel_t) theChannel;
    __block ERRORCODE isCompliete =ERRORCODE_NORESPONSE;
    __block NSError *errorInformer=*error;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        amqp_channel_open(connection.internalConnection, channel);
        if([connection checkLastOperation:@"Failed to open a channel"]){
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to open a channel" forKey:NSLocalizedDescriptionKey];
            errorInformer = [NSError errorWithDomain:NSStringFromClass([self class]) code:-5 userInfo:errorDetail];
            isCompliete =ERRORCODE_HASERROR;
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
- (void)close
{
    amqp_channel_close(connection.internalConnection, channel, AMQP_REPLY_SUCCESS);
}
+(void)closeChanelByNumber:(uint)channelNum connection:(AMQPConnection *)connect{
    amqp_channel_close(connect.internalConnection, channelNum, AMQP_REPLY_SUCCESS);
}
@end

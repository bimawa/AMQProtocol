//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <sys/socket.h>
#import "AMQPConsumer.h"
#import "amqp_framing.h"
#import "AMQPChannel.h"
#import "AMQPQueue.h"
#import "AMQPMessage.h"

@implementation AMQPConsumer

@synthesize internalConsumer = consumer;
@synthesize channel;
@synthesize queue;

- (id)initForQueue:(AMQPQueue *)theQueue onChannel:(__strong AMQPChannel **)theChannel useAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local error:(NSError **)error deepLoop:(int)deep {
	if(self = [super init])
	{
        *error=nil;
        channel = *theChannel;
		queue = theQueue;
		isAck=ack;
        AMQPConnection *connect=channel.connection;
        if ([channel isOpen])
        {
            amqp_basic_consume_ok_t *response = amqp_basic_consume(channel.connection.internalConnection, channel.internalChannel, queue.internalQueue, AMQP_EMPTY_BYTES, !local, !ack, exclusive);
            while([connect checkLastOperation:@"Failed to start consumer"]){
                [NSThread sleepForTimeInterval:.1];
                if (deep<=0){
                    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                    [errorDetail setValue:@"Failed to start consumer timeout has lemited:" forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-9 userInfo:errorDetail];
                    [channel setIsOpen:NO];
                    *theChannel = channel;
                    return nil;
                }
                channel= [connect openChannelError:error];
                if (*error != nil) {
                    return nil;
                }
                response = amqp_basic_consume(channel.connection.internalConnection, channel.internalChannel, queue.internalQueue, AMQP_EMPTY_BYTES, !local, !ack, exclusive);
                deep--;
            }
            *theChannel=channel;
            consumer = amqp_bytes_malloc_dup(response->consumer_tag);
        }
	}
	return self;
}
-(void)closeConsumer{
    NSLog(@"TCLib>> CloseConsumer...");
    if (![channel isOpen])
    {
        NSError *channelError=nil;
        channel = [channel.connection openChannelError:&channelError];
        if (channelError != nil)
        {
            NSLog(@"TCLib>> Consumer ERROR close consumer no internet connection");
            return;
        }
    }else{
        NSError *erroChannel = nil;
        if (erroChannel != nil) {
            NSLog(@"TCLib>> Consumer ERROR cab't open channel, close consumer error");
            return;
        }
        amqp_channel_close(channel.connection.internalConnection, channel.internalChannel, 1);
        if([channel.connection checkLastOperation:@"Failed to stop consumer"]){
            NSLog(@"TCLib>> Consumer ERROR close consumer");
            [channel setIsOpen:NO];
            return;
        }
        NSLog(@"TCLib>> Consumer Closed!");
    }
}
- (void)dealloc
{
	amqp_bytes_free(consumer);
}

- (AMQPMessage *)popWithTimer:(NSInteger)timeOut
{
    @synchronized (self) {
	amqp_frame_t frame;
	int result = 0;
	size_t receivedBytes = 0;
	size_t bodySize = (size_t) -1;
	amqp_bytes_t body;
	amqp_basic_deliver_t *delivery;
	amqp_basic_properties_t *properties;
	
	AMQPMessage *message = nil;

	while(!message)
	{
		// a complete message delivery consists of at least three frames:
		amqp_maybe_release_buffers(channel.connection.internalConnection);
		// Frame #1: method frame with method basic.deliver
        result = amqp_simple_wait_frame(channel.connection.internalConnection, &frame, timeOut);

		
		if(result < 0) { return nil; }
		
		if(frame.frame_type != AMQP_FRAME_METHOD || frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD) { continue; }
		
		delivery = (amqp_basic_deliver_t*)frame.payload.method.decoded;
		
		// Frame #2: header frame containing body size
		result = amqp_simple_wait_frame(channel.connection.internalConnection, &frame, timeOut);
		if(result < 0) { return nil; }
		
		if(frame.frame_type != AMQP_FRAME_HEADER)
		{
			return nil;
		}
		
		properties = (amqp_basic_properties_t*)frame.payload.properties.decoded;
		
		bodySize = (size_t) frame.payload.properties.body_size;
		receivedBytes = 0;
		body = amqp_bytes_malloc(bodySize);
		
		// Frame #3+: body frames
		while(receivedBytes < bodySize)
		{
			result = amqp_simple_wait_frame(channel.connection.internalConnection, &frame, timeOut);
			if(result < 0) { return nil; }

			if(frame.frame_type != AMQP_FRAME_BODY)
			{
				return nil;
			}

			receivedBytes += frame.payload.body_fragment.len;
			memcpy(body.bytes, frame.payload.body_fragment.bytes, frame.payload.body_fragment.len);

		}
		message = [AMQPMessage messageFromBody:body withDeliveryProperties:delivery withMessageProperties:properties
                                    receivedAt:[NSDate date]];
        if (isAck) {
            amqp_basic_ack(channel.connection.internalConnection, channel.internalChannel, message.deliveryTag, NO);
        }
		amqp_bytes_free(body);
	}
	
	return message;
    }
}
@end

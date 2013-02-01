//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPObject.h"

#import <stdio.h>
#import "amqp.h"
#import "amqp_framing.h"

#define AMQP_BYTES_TO_NSSTRING(x) [[NSString alloc] initWithBytes:x.bytes length:x.len encoding:NSUTF8StringEncoding]

@implementation AMQPObject

- (NSString*)errorDescriptionForReply:(amqp_rpc_reply_t)reply
{
	switch (reply.reply_type)
	{
		case AMQP_RESPONSE_NORMAL:
			return @"";
			break;
		case AMQP_RESPONSE_NONE:
			return @"missing RPC reply type";
			break;
			
		case AMQP_RESPONSE_LIBRARY_EXCEPTION:
			if(reply.library_error)
			{
				return [NSString stringWithUTF8String:strerror(reply.library_error)];
			}
			else
			{
				return @"(end-of-stream)";
			}
			break;
		case AMQP_RESPONSE_SERVER_EXCEPTION:
			switch (reply.reply.id)
			{
				case AMQP_CONNECTION_CLOSE_METHOD:
				{
					amqp_connection_close_t *connectionClose = (amqp_connection_close_t *) reply.reply.decoded;
					return AMQP_BYTES_TO_NSSTRING(connectionClose->reply_text);
					break;
				}
				case AMQP_CHANNEL_CLOSE_METHOD:
				{
					amqp_channel_close_t *channelClose = (amqp_channel_close_t *) reply.reply.decoded;
					return AMQP_BYTES_TO_NSSTRING(channelClose->reply_text);
					break;
				}
				default:
					return [NSString stringWithFormat:@"unknown error %d", reply.reply.id];
					break;
			}
			break;
	}
}

@end
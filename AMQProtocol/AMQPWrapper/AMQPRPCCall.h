//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "amqp.h"
#include <stdlib.h>
#import "AMQPObject.h"
#import "amqp_framing.h"
#import "AMQPConsumer.h"
#import "AMQPExchange.h"
#import "AMQPQueue.h"

#define AMQP_BYTES_TO_NSSTRING(x) [[NSString alloc] initWithBytes:x.bytes length:x.len encoding:NSUTF8StringEncoding]
@interface AMQPRPCCall :AMQPObject
- (id)initWithConnection:(AMQPConnection *)connection rpcName:(NSString *)qName error:(NSError **)error;

- (AMQPMessage *)callWithBody:(NSString *)body;


@end
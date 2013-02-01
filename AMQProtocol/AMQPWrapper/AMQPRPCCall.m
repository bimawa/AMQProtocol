//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPWrapper.h"
#import "amqp_framing.h"
@implementation AMQPRPCCall {
    amqp_basic_properties_t props;
    AMQPConsumer *consumer;
    NSString *rpcFunctionName;
    NSString *corr_id;
    AMQPExchange *exchange;
    AMQPQueue *queueForReplyTo;
}
- (id)initWithConnection:(AMQPConnection *)connection rpcName:(NSString *)qName error:(NSError **)error {
    rpcFunctionName=qName;
    if (connection == nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:[NSString stringWithFormat:@"Failed Connection is Lost"] forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-14 userInfo:errorDetail];
        return nil;
    }
    AMQPChannel *channel= [connection openChannel];
    if (channel==nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to declare queue" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-8 userInfo:errorDetail];
        return nil;
    }
    NSError *queueAndConsumerError =nil;
    AMQPQueue *queue = [[AMQPQueue alloc] initWithName:@"" onChannel:channel isPassive:NO isExclusive:YES isDurable:NO getsAutoDeleted:YES error:&queueAndConsumerError];
    exchange = [[AMQPExchange alloc] initExchangeWithName:@"" onChannel:channel];
    consumer= [[AMQPConsumer alloc] initForQueue:queue onChannel:&channel useAcknowledgements:NO isExclusive:YES receiveLocalMessages:YES error:&queueAndConsumerError deepLoop:5];
    if (queueAndConsumerError ==nil){
        queueForReplyTo=queue;
        corr_id=[[NSNumber numberWithInt:arc4random() % 1000] stringValue];
    }else{
        *error= queueAndConsumerError;
    }
    return self;
}

- (AMQPMessage *)callWithBody:(NSString *)body {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault,uuidRef);
    NSString *uuidStr =(__bridge_transfer NSString *)uuidString;
    uuidStr=[uuidStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSRange stringRange = {0, MIN([uuidStr length], 12)};
    stringRange = [uuidStr rangeOfComposedCharacterSequencesForRange:stringRange];
    NSString *shortString = [uuidStr substringWithRange:stringRange];
    CFRelease((CFTypeRef) uuidRef);
    NSError *error=nil;
    corr_id=[shortString lowercaseString];
    props._flags= AMQP_BASIC_REPLY_TO_FLAG| AMQP_BASIC_CORRELATION_ID_FLAG| AMQP_BASIC_DELIVERY_MODE_FLAG| AMQP_FILE_CONTENT_TYPE_FLAG;
    props.reply_to= [queueForReplyTo internalQueue];
    props.correlation_id=amqp_cstring_bytes([corr_id UTF8String]);
    props.delivery_mode = 2;
    [exchange publishMessage:body usingRoutingKey:rpcFunctionName propertiesMessage:props mandatory:YES immediate:NO error:&error];
    if(error!=nil) {
        //TODO: parse error
        NSLog(@"Excepshen RPC!!!%@", [error localizedDescription]);
    }
    AMQPMessage *message=[consumer pop];
    return message;
}
@end
//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPConsumerThread.h"

#import "AMQPConsumer.h"
#import "AMQPMessage.h"

@implementation AMQPConsumerThread{
    NSString *nameThread;

}

@synthesize delegate;

- (id)initWithConsumer:(AMQPConsumer *)theConsumer delegate:(NSObject <AMQPConsumerThreadDelegate> *)deleGate nameThread:(NSString *)name {
    if(self = [super init])
	{
		consumer = theConsumer;
        nameThread=name;
        [self setDelegate:deleGate];
	}
	return self;
}

- (void)main
{
    [[NSThread currentThread] setName:nameThread];
    if ([self isCancelled]) {
        NSLog(@"Thread %@ is cancel.", [NSThread currentThread]);
        [NSThread exit];
    }
    int countTry=3;
    while(![self isCancelled])
	{
        AMQPMessage *message = [consumer pop];
		if(message) {
            [delegate performSelector:@selector(amqpConsumerThreadReceivedNewMessage:) withObject:message];
        }else {
            countTry--;
            if (countTry==0){
                NSLog(@"Consumer lose Connection: %@",[NSThread currentThread]);
                [delegate performSelector:@selector(amqpConsumerThreadLoseConnection) withObject:nil];
                [NSThread exit];
            }
            NSLog(@"NO messsage for consumer: %@",[NSThread currentThread]);
            [NSThread sleepForTimeInterval:5];
        }
        if ([self isCancelled])NSLog(@"Thread %@ is cancel.", [NSThread currentThread]);
	}
    [NSThread exit];
}

@end

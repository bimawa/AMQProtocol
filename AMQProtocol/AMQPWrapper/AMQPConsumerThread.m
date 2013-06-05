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
    BOOL isLoopMode;
}
@synthesize delegate;

- (id)initWithConsumer:(AMQPConsumer *)theConsumer delegate:(NSObject <AMQPConsumerThreadDelegate> *)deleGate nameThread:(NSString *)name persistentListen:(BOOL)isLoop
{
    if(self = [super init])
	{
		consumer = theConsumer;
        nameThread=name;
        isLoopMode = isLoop;
        [self setDelegate:deleGate];
	}
	return self;
}

-(void)closeConsumer
{
    [consumer closeConsumer];
}
- (void)main
{
    [[NSThread currentThread] setName:nameThread];
    if ([self isCancelled]) {
        NSLog(@"TCLib>> Thread %@ is cancel. UPER", [NSThread currentThread]);
        [NSThread exit];
    }
    int countTry=3;
    if (isLoopMode){
        while(![self isCancelled])
        {
            AMQPMessage *message = [consumer popWithTimer:0];
            if(message) {
                [delegate performSelector:@selector(amqpConsumerThreadReceivedNewMessage:) withObject:message];
            }else {
                countTry--;
                if (countTry==0){
                    NSLog(@"TCLib>> Consumer lose Connection: %@",[[NSThread currentThread] name]);
                    [delegate performSelector:@selector(amqpConsumerThreadLoseConnection) withObject:nil];
                    [NSThread exit];
                }
                NSLog(@"TCLib>> NO messsage for consumer: %@",[[NSThread currentThread] name]);
//                [NSThread sleepForTimeInterval:5];
            }
            if ([self isCancelled])NSLog(@"TCLib>> Thread %@ is cancel.", [NSThread currentThread]);
        }
        NSLog(@"TCLib>> Thread %@ is cancel. MIDLE", [NSThread currentThread]);
        [NSThread exit];
    }else{
        AMQPMessage *message = [consumer popWithTimer:15];
        [consumer closeConsumer];
        [delegate performSelector:@selector(amqpConsumerThreadReceivedNewMessage:) withObject:message];
        NSLog(@"TCLib>> Thread %@ is cancel. BOTTM", [[NSThread currentThread]name]);
        [NSThread exit];
    }
}

@end

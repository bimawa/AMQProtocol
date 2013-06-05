//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "amqp.h"

#import "AMQPConnection.h"
#import "AMQPObject.h"


@interface AMQPChannel : AMQPObject
{
	@public
	amqp_channel_t channel;
	AMQPConnection *connection;
    AMQPUtilities *utilities;
    BOOL isOpen;

}

@property (readonly) amqp_channel_t internalChannel;
@property (readonly, retain) AMQPConnection *connection;

@property(nonatomic) BOOL isOpen;

- (id)init;
- (void)openChannel:(unsigned int)theChannel onConnection:(AMQPConnection *)theConnection error:(NSError**)error;

- (void)setupBasicQOS;

- (void)close;
@end

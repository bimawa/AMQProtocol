//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "amqp.h"

#import "AMQPObject.h"
#import "AMQPUtilities.h"
@class AMQPChannel;

@interface AMQPConnection : AMQPObject
{
	__block amqp_connection_state_t connection;
	__block int socketFD;
    AMQPUtilities *utilities;
	uint nextChannel;
    NSLock *lock;

}
@property (readonly) amqp_connection_state_t internalConnection;

- (id)init;
- (void)dealloc;

- (void)connectToHost:(NSString *)host onPort:(int)port error:(NSError**)error;
- (void)loginAsUser:(NSString *)username withPasswort:(NSString *)password onVHost:(NSString *)vhost error:(NSError**)error;
- (void)disconnectError:(NSError**)error; // all channels have to be closed before closing the connection

- (BOOL)checkLastOperation:(NSString *)context;

- (AMQPChannel *)openChannelError:(NSError **)errorOpenChannel;

@end

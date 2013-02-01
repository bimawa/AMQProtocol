//
// Created by tradechat on 02.10.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>

#import "amqp.h"

#import "AMQPObject.h"

@class AMQPChannel;

@interface AMQPConnection : AMQPObject
{
	amqp_connection_state_t connection;
	int socketFD;
	
	unsigned int nextChannel;
}
@property (readonly) uint nextChannel_;
@property (readonly) amqp_connection_state_t internalConnection;

- (id)init;
- (void)dealloc;

- (BOOL)connectToHost:(NSString*)host onPort:(int)port error:(NSError**)error;
- (BOOL)loginAsUser:(NSString*)username withPasswort:(NSString*)password onVHost:(NSString*)vhost error:(NSError**)error;
- (BOOL)disconnectError:(NSError**)error; // all channels have to be closed before closing the connection

- (BOOL)checkLastOperation:(NSString*)context;

- (AMQPChannel*)openChannel;

@end

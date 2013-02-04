//
//  AMQProtocolTests.m
//  AMQProtocolTests
//
//  Created by Maksim Bunkow on 01.02.13.
//
//

#import "AMQProtocolTests.h"
#import "AMQProtocol.h"
@implementation AMQProtocolTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    NSString *const GENERAL_S_EXCH_NAME = @"_S";
    NSString *const GENERAL_G_EXCH_NAME = @"_G";
    NSString *const GENERAL_ACTUAL_EXCH_NAME = @"_ACTUAL";
    NSString *const GENERAL_STATUS_EXCH_NAME = @"_STATUS";
    NSString *const GENERAL_SUSPEND_EXCH_NAME = @"_SUSPEND";
    NSString *const UNAUTH_LOGIN=@"x";
    NSString *const UNAUTCH_PASSWORD=@"Yz7qn2Isb92gS4tWjn1";
    int const SERVER_PORT=5672;
    NSString *const VIRTUAL_HOST=@"/";
    NSString *const SERVER_HOST=@"192.168.0.210";
    
    AMQPConnection *connection = [[AMQPConnection alloc] init];
    NSError *error= nil;
    [connection connectToHost:@"localhost" onPort:SERVER_PORT error:&error];
    if (error != nil){
        STFail(@"Error connection: %@", error);
        return;
    }
    [connection loginAsUser:@"guest" withPasswort:@"guest" onVHost:VIRTUAL_HOST error:&error];
    if (error != nil){
        STFail(@"Error logined: %@", error);
        return;
    }
    AMQPExchange *exchange = [[AMQPExchange alloc] initTopicExchangeWithName:@"TestExchange" onChannel:[connection openChannel] isPassive:NO isDurable:NO getsAutoDeleted:YES error:&error];
    if (error != nil){
        STFail(@"Error declareExchange: %@", error);
        return;
    }
    amqp_basic_properties_t props;
    props._flags= AMQP_BASIC_CLASS;
    props.type = amqp_cstring_bytes([@"typeOfMessage" UTF8String]);
    props.priority = 1;
    [exchange publishMessage:@"Hi max i tested message" usingRoutingKey:@"#" propertiesMessage:props mandatory:NO immediate:NO error:&error];
    if (error != nil){
        STFail(@"Error declareExchange: %@", error);
        return;
    }
}

@end

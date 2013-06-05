//
// Created by tradechat on 04.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface AMQPUtilities : NSObject
typedef enum{
    ERRORCODE_NORESPONSE,
    ERRORCODE_HASERROR,
    ERRORCODE_NORMAL
}ERRORCODE;

- (void)waitingRespondsInForKey:(ERRORCODE **)key error:(NSError **)error;

@end
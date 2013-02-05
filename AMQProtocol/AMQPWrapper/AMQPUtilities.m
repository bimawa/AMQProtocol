//
// Created by tradechat on 04.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMQPUtilities.h"


@implementation AMQPUtilities {
}

- (void)waitingRespondsInSec:(NSTimeInterval)sec forKey:(ERRORCODE **)key exitAfterTryCounter:(NSInteger)tryCounter error:(NSError **)error{
    NSInteger countTry=0;
    while(*key== (ERRORCODE *) ERRORCODE_NORESPONSE){
        if (tryCounter==countTry){
            *key= (ERRORCODE *) ERRORCODE_HASERROR;
            if (*error==nil){
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Connection refuse" forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-16 userInfo:errorDetail];
            }
            return;
        }else{
            countTry++;
            [NSThread sleepForTimeInterval:sec];
        }

    }
}
@end
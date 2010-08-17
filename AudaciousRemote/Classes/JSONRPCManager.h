//
//  JSONRPC.h
//  request
//
//  Created by Maykel Moya on 25/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

#define JSONRPCErrorDomain @"JSONRPCErrorDomain"

#ifndef REQUEST_TIMEOUT
#define REQUEST_TIMEOUT 4
#endif

#define array_(__args...) [NSArray arrayWithObjects:__args, nil]
#define dict_(__args...) [NSDictionary dictionaryWithObjectsAndKeys:__args, nil]

typedef enum {
    JSONRPCErrorResultMissingOrNotADictionary = -1000,
    JSONRPCErrorResponseNotADictionary = -1001,
} JSONRPCErrorCodes;

@interface JSONRPCManager : NSObject {
    NSMutableDictionary *currentConnections;
    NSString *serviceURL;
}

@property (readonly) NSDictionary *currentConnections;

- (id)init:(NSString *)aServiceURL;

- (void)rpc:(NSString *)method
       args:(NSArray *)anArgs
   delegate:(id)aDelegate
   callback:(SEL)aCallback
    errback:(SEL)anErrback;

- (void)cancelAllConnections;

@end

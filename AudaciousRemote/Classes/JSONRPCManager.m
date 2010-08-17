//
//  JSONRPC.m
//  request
//
//  Created by Maykel Moya on 25/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "JSONRPCManager.h"
#import "JSON.h"

@implementation JSONRPCManager

@synthesize currentConnections;

static inline NSString *uuid1() {
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    return [uuidString autorelease];
}

- (id)init:(NSString *)aServiceURL
{
    self = [super init];
    if (self) {
        currentConnections = [[NSMutableDictionary alloc] initWithCapacity:1];
        serviceURL = [aServiceURL retain];
    }
    return self;
}

- (NSDictionary *)getConnDict:(NSURLConnection *)connection
{
    NSValue *connValue = [NSValue valueWithNonretainedObject:connection];
    NSDictionary *connDict = [currentConnections objectForKey:connValue];

    return connDict;
}

- (void)cancelAllConnections
{
    for (id key in currentConnections) {
        NSURLConnection *connection = [(NSValue *)key nonretainedObjectValue];
        NSDictionary *connDict = [self getConnDict:connection];
        NSString *uuid = [connDict objectForKey:@"uuid"];
        NSString *method = [connDict objectForKey:@"method"];

#ifdef DLog
        DLog(@"rpcManager: cancelling request %@ id=%@", method, uuid);
#endif

        NSTimer *timer = [connDict objectForKey:@"timer"];
        if ([timer isValid])
            [timer invalidate];

        [connection cancel];

        // TODO: send errback with connectionCancelled error to all delegates

        NSDictionary *userInfo = dict_(uuid, @"uuid",
                                       method, @"method",
                                       @"Cancelled", @"NSLocalizedDescription");
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCancelled
                                         userInfo:userInfo];

        id delegate = [connDict objectForKey:@"delegate"];
        NSValue *errbackValue = [connDict objectForKey:@"errback"];
        SEL errback = [errbackValue pointerValue];

#ifdef DLog
        DLog(@"rpcManager: sending %@ to %@ with object <%@: 0x%x>",
             NSStringFromSelector(errback), delegate, [error class], error);
#endif
        [delegate performSelector:errback withObject:error];
    }
    [currentConnections removeAllObjects];
}

- (void)rpc:(NSString *)method
       args:(NSArray *)anArgs
   delegate:(id)aDelegate
   callback:(SEL)aCallback
    errback:(SEL)anErrback
{

    NSString *uuid = uuid1();

    NSDictionary *methodCall = dict_(method, @"method", anArgs, @"params", uuid, @"id");
    SBJSON *sbJson = [[SBJSON alloc] init];
    NSString *post = [sbJson stringWithObject:methodCall];
    [sbJson release];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc]
                                initWithURL:[NSURL URLWithString:serviceURL]];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
    [req setTimeoutInterval:REQUEST_TIMEOUT];

    NSMutableDictionary *connDict = [[NSMutableDictionary alloc] initWithCapacity:7];

    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:req
                                                                   delegate:self
                                                           startImmediately:FALSE] autorelease];
    NSValue *connValue = [NSValue valueWithNonretainedObject:connection];
#ifdef DLog
    DLog(@"rpcManager: %@ request id=%@ connection=<%@: 0x%x>",
         method, uuid, [connection class], connection);
#endif

    [connDict setObject:uuid
                 forKey:@"uuid"];
    [connDict setObject:method
                 forKey:@"method"];
    [connDict setObject:[NSMutableData dataWithLength:0]
                 forKey:@"data"];
    [connDict setObject:[NSValue valueWithPointer:aCallback]
                 forKey:@"callback"];
    [connDict setObject:[NSValue valueWithPointer:anErrback]
                 forKey:@"errback"];
    [connDict setObject:aDelegate
                 forKey:@"delegate"];

    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval:REQUEST_TIMEOUT
                                             target:self
                                           selector:@selector(connectionDidTimeout:)
                                           userInfo:connValue
                                            repeats:TRUE];
    [connDict setObject:timer
                 forKey:@"timer"];

    [currentConnections setObject:connDict
                           forKey:connValue];
    [connDict release];

    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSDefaultRunLoopMode];
    [connection start];

    [req release];
}

#pragma mark -
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSValue *connValue = [NSValue valueWithNonretainedObject:connection];
    NSDictionary *connDict = [currentConnections objectForKey:connValue];
    NSMutableData *responseData = [connDict objectForKey:@"data"];
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSValue *connValue = [NSValue valueWithNonretainedObject:connection];
    NSDictionary *connDict = [currentConnections objectForKey:connValue];

    NSString *uuid = [connDict objectForKey:@"uuid"];
    NSString *method = [connDict objectForKey:@"method"];
#ifdef DLog
    DLog(@"rpcManager: %@ completed id=%@", method, uuid);
#endif

    NSTimer *timer = [connDict objectForKey:@"timer"];
    [timer invalidate];

    id delegate = [connDict objectForKey:@"delegate"];
    NSData *data = [connDict objectForKey:@"data"];
    NSValue *callbackValue = [connDict objectForKey:@"callback"];
    SEL callback = [callbackValue pointerValue];

    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error = nil;
    SBJSON *sbJson = [[SBJSON alloc] init];
    id ret = [sbJson objectWithString:dataStr error:&error];
    [sbJson release];
    [dataStr release];

    if (ret && [ret isKindOfClass:[NSDictionary class]]) {
        id resultRepr = [ret objectForKey:@"result"];
        if (resultRepr) {
#ifdef DLog
            DLog(@"rpcManager: sending %@ to %@ with object <%@: 0x%x>",
                 NSStringFromSelector(callback), delegate, [ret class], ret);
#endif
            [delegate performSelector:callback withObject:ret];
            [currentConnections removeObjectForKey:connValue];
        }
        else {
#ifdef DLog
            DLog(@"rpcManager: parsed response doesn't have \"result\" key");
#endif
            NSDictionary *userInfo = dict_(uuid, @"uuid",
                                           method, @"method",
                                           @"Response 'result' key missing or not a dictionary",
                                           @"NSLocalizedDescription");
            NSError *error = [NSError errorWithDomain:JSONRPCErrorDomain
                                                 code:JSONRPCErrorResultMissingOrNotADictionary
                                             userInfo:userInfo];

            NSValue *errbackValue = [connDict objectForKey:@"errback"];
            SEL errback = [errbackValue pointerValue];

            [delegate performSelector:errback withObject:error];
            [currentConnections removeObjectForKey:connValue];
        }
    }
    else {
#ifdef DLog
        DLog(@"rpcManager: parsed response is not a NSDictionary");
#endif

        NSDictionary *userInfo = dict_(uuid, @"uuid",
                                       method, @"method",
                                       @"Response is not a NSDictionary",
                                       @"NSLocalizedDescription");
        NSError *error = [NSError errorWithDomain:JSONRPCErrorDomain
                                             code:JSONRPCErrorResponseNotADictionary
                                         userInfo:userInfo];

        NSValue *errbackValue = [connDict objectForKey:@"errback"];
        SEL errback = [errbackValue pointerValue];

        [delegate performSelector:errback withObject:error];
        [currentConnections removeObjectForKey:connValue];
    }

    [currentConnections removeObjectForKey:connValue];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSValue *connValue = [NSValue valueWithNonretainedObject:connection];
    NSDictionary *connDict = [currentConnections objectForKey:connValue];

    NSString *uuid = [connDict objectForKey:@"uuid"];
    NSString *method = [connDict objectForKey:@"method"];

#ifdef DLog
    DLog(@"rpcManager: %@ failed id=%@", method, uuid);
    DLog(@"%@", error);
    DLog(@"%@", [error userInfo]);
#endif

    NSTimer *timer = [connDict objectForKey:@"timer"];
    if ([timer isValid])
        [timer invalidate];

    id delegate = [connDict objectForKey:@"delegate"];
    NSValue *errbackValue = [connDict objectForKey:@"errback"];
    SEL errback = [errbackValue pointerValue];

#ifdef DLog
    DLog(@"rpcManager: sending %@ to %@ with object <%@: 0x%x>",
         NSStringFromSelector(errback), delegate, [error class], error);
#endif
    [delegate performSelector:errback withObject:error];
    [currentConnections removeObjectForKey:connValue];
}

- (void)connectionDidTimeout:(NSTimer *)theTimer
{
    NSValue *connValue = theTimer.userInfo;
    NSDictionary *connDict = [currentConnections objectForKey:connValue];

    [theTimer invalidate];

    NSURLConnection *connection = [connValue nonretainedObjectValue];
    [connection cancel];

    NSString *uuid = [connDict objectForKey:@"uuid"];
    NSString *method = [connDict objectForKey:@"method"];
#ifdef DLog
    DLog(@"rpcManager: %@ timed out id=%@", method, uuid);
#endif

    NSDictionary *userInfo = dict_(
        uuid, @"uuid",
        method, @"method",
        [NSString stringWithFormat:@"Request %@ [%@] did timeout", method, uuid],
        @"NSLocalizedDescription"
    );
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorTimedOut
                                     userInfo:userInfo];

    [self connection:connection didFailWithError:error];
}

#pragma mark -

- (void)dealloc
{
    [currentConnections release];
    [serviceURL release];
    [super dealloc];
}

@end

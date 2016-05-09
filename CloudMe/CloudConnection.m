/*
 Copyright (C) 2015 Orange
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "CloudConnection.h"
#import "CloudConfig.h"




@interface OIDCConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, copy) OIDCCompletionHandler handler;
@property (nonatomic) NSHTTPURLResponse * response;
@property (nonatomic) NSURLRequest * redirectRequest;
@property (nonatomic) NSString * redirectURI;

@end

@implementation OIDCConnection


+ (void)sendAsynchronousRequest:(NSURLRequest *)request redirectURI:(NSString *)redirectURI completionHandler:(OIDCCompletionHandler)handler {
    OIDCConnection * oidcConnection = [[OIDCConnection alloc] init];
    //oidcConnection.startingDate = [NSDate date];
    oidcConnection.redirectURI = redirectURI;
    oidcConnection.handler = handler;
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:oidcConnection];
}


#pragma mark - NSURLConnectionData delegate
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    //NSLog (@"Got a redirect: %@", request);
    if ([request.URL.absoluteString hasPrefix:self.redirectURI]) {
        self.redirectRequest = request;
        //NSLog (@"GOT REDIRECT CALLBACK !!! %@", request.URL.absoluteString);
        return nil;
    }
    //    if (redirectResponse) {
    //        // we don't use the new request built for us, except for the URL
    //        return redirectResponse;
    //    } else {
    //        return request;
    //    }
    return request;
}

#pragma mark - NSURLConnection delegate
// the follwing three callbacks are used ONLY when a self signed certificate is set on teh authentication server. This should not be used in production mode
// http://stackoverflow.com/questions/11573164/uiwebview-to-view-self-signed-websites-no-private-api-not-nsurlconnection-i


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.response = response;
}

//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    //NSLog (@"***** didReceiveResponse");
//    [self.responseData appendData:data];
//}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError * error = nil;
    NSUInteger code = self.response.statusCode;
    if (code != 200 && code != 201 && code != 202 && code != 204) {
        error = [NSError errorWithDomain:@"Orange Cloud" code:self.response.statusCode userInfo:nil];
    } else {
        //        if (self.message) {
        //            float contentSize = self.responseData.length / 1024.0;
        //            NSTimeInterval downloadTime = -[self.startingDate timeIntervalSinceNow];
        //            NSLog (@"[CLOUD USAGE] %@: %g kB in %g s => %g kB/s", self.message, contentSize, downloadTime, floor((10*contentSize)/downloadTime)/10.0);
        //        }
    }
    self.handler (self.redirectRequest, error);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //NSLog (@"***** didFailWithError");
    // The request has failed for some reason!
    // Check the error var
    self.handler (nil, error);
}

@end


@interface CloudConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, copy) ProgressHandler progressHandler;
@property (nonatomic, copy) CompletionHandler completionHandler;
@property (nonatomic) NSHTTPURLResponse * response;
@property (nonatomic) NSMutableData * responseData;

@end

@interface CloudConnection ()
@property (nonatomic) NSDate * startingDate; // used only for tracing bandwidth usage
@property (nonatomic) NSString * message; // if not nil, bandwidth usage is display with this message as prefix

@end

static NSOperationQueue * operationQueue = nil;
static NSMutableArray * pendingRequests = nil;
@implementation CloudConnection


+ (void) load {
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 1;
    pendingRequests = [[NSMutableArray alloc] initWithCapacity:128];
}

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue message:(NSString*)message completionHandler:(CompletionHandler) completionHandler {
    [self sendAsynchronousRequest:request queue:queue message:message progressHandler:nil completionHandler:completionHandler];
}

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue message:(NSString*)message progressHandler:(ProgressHandler)progressHandler
              completionHandler:(CompletionHandler) completionHandler {
    CloudConnection * cloudConnection = [[CloudConnection alloc] init];
    cloudConnection.startingDate = [NSDate date];
    cloudConnection.message = message;
    cloudConnection.progressHandler = progressHandler;
    cloudConnection.completionHandler = completionHandler;
    if (FORCE_SERIAL_REQUESTS) {
        NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:cloudConnection startImmediately:NO];
        @synchronized(pendingRequests) {
            [pendingRequests addObject:@[connection, cloudConnection]];
            if (pendingRequests.count == 1) {
                [connection start];
            }
        }
    } else {
        (void)[[NSURLConnection alloc] initWithRequest:request delegate:cloudConnection];
    }
}


#pragma mark - NSURLConnection delegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.response = response;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    float value = (1.0 * totalBytesWritten)/totalBytesExpectedToWrite;
    if (self.progressHandler != nil) {
        self.progressHandler (value);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError * error = nil;
    NSUInteger code = self.response.statusCode;
    if (code != 200 && code != 201 && code != 202 && code != 204) {
        error = [NSError errorWithDomain:@"Orange Cloud" code:self.response.statusCode userInfo:nil];
    } else {
        if (self.message) {
            float contentSize = self.responseData.length / 1024.0;
            NSTimeInterval downloadTime = -[self.startingDate timeIntervalSinceNow];
            NSLog (@"[CLOUD USAGE] %@: %g kB in %g s => %g kB/s", self.message, contentSize, downloadTime, floor((10*contentSize)/downloadTime)/10.0);
        }
    }
    if (FORCE_SERIAL_REQUESTS) {
        // start new one
        @synchronized(pendingRequests) {
            [pendingRequests removeObjectAtIndex:0];
            if (pendingRequests.count > 0) {
                NSArray * array = [pendingRequests objectAtIndex:0];
                NSURLConnection * connection = array[0];
                CloudConnection * cloudConnection = array[1];
                cloudConnection.startingDate = [NSDate date];
                [connection start];
            }
        }
    }
    if (self.completionHandler) {
        self.completionHandler (self.response, self.responseData, error);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    if (self.completionHandler != nil) {
        self.completionHandler (self.response, nil, error);
    }
}

// the following  callbacks are used ONLY when a self signed certificate is set on the authentication server. This should not be used in production mode
// http://stackoverflow.com/questions/11573164/uiwebview-to-view-self-signed-websites-no-private-api-not-nsurlconnection-i


//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    if ([challenge previousFailureCount] == 0) { // grant the connection
//        //self.authorizationChecked = YES; // don't fake athorization next time a redirect happen
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
//        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
//    } else {
//        [[challenge sender] cancelAuthenticationChallenge:challenge];
//    }
//}
//
//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
//    //NSLog (@"***** canAuthenticateAgainstProtectionSpace");
//    // accept authentication
//    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
//}

@end


@implementation CloudUtil

+ (id) pack:(id) obj {
    if ([obj isKindOfClass:[NSString class]]) {
        int maxLen = 64;
        NSString * string = (NSString*)obj;
        if (string.length > maxLen) {
            return [NSString stringWithFormat:@"%@...%@", [string substringToIndex:maxLen/2], [string substringFromIndex:string.length-maxLen/2]];
        }
        return string;
    }
    return obj;
}
/** utility method to dump a request using a curl syntax
 */
+ (void) dumpAsCurl:(NSURLRequest*)request withMessage:(NSString*)message {
    if (TRACE_API_CALL) {
        NSMutableString * command = [[NSMutableString alloc] initWithCapacity:2048];
        [command appendFormat:@"[CLOUD API] %@:\n", message];
        [command appendFormat:@"curl -X %@", [request HTTPMethod]];
        NSDictionary * headerDict = [request allHTTPHeaderFields];
        [headerDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [command appendFormat:@" -H \"%@: %@\"", key , [self pack:obj]];
        }];
        if ([request HTTPBody] != nil) {
            [command appendFormat:@" --data-binary \"%@\"", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]];
        }
        [command appendFormat:@" %@", request.URL.absoluteString];
        NSLog (@"%@", command);
    }
}

+ (void) dumpAsJSON:(NSDictionary*)dictionary withMessage:(NSString*)message {
    if (TRACE_API_CALL) {
        NSMutableString * command = [[NSMutableString alloc] initWithCapacity:2048];
        NSData * data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
        [command appendFormat:@"[CLOUD API] %@:\n%@", message, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        NSLog (@"%@\n", command);
    }
}


+ (CloudStatus) statusFromConnection:(NSURLResponse*)response data:(NSData*)data {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*)response;
        int statusCode = (int)httpResponse.statusCode;
        NSObject * jsonObject = nil;
        int errorCode = 0;
        NSString * errorMessage = @"NO_LABEL";
        NSString * errorDescription = @"NO_LABEL";
        if (data != nil) {
            NSError * error = nil;
            jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary * errorDict = ((NSDictionary*)jsonObject)[@"error"];
                errorCode = [((NSNumber*)errorDict[@"code"]) intValue];
                errorDescription = errorDict[@"description"];
                errorMessage = errorDict[@"message"];
                if (errorDescription == nil) { // fallback to old system
                    errorDescription = errorDict[@"details"];
                    errorMessage = errorDict[@"label"];
                }
            } else {
                NSLog (@"ERROR: unexpected non dictionary result: %@", jsonObject);
            }
        }
        if (TRACE_API_CALL) {
            NSLog (@"[CLOUD API] http error %d (%@)", statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
            if (data != nil) {
                NSError * error = nil;
                NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                NSLog (@"Error message %@", jsonObject);
            }
        }
        
        if (statusCode == 200) { // HTTP ok
            return StatusOK;
        } else if (statusCode == 400) { // HTTP Bad Request
            if (errorCode == 20) {
                return InvalidURL;
            }
        } else if (statusCode == 401) { // HTTP Unauthorized
            if (errorCode == 41) {
                return CloudErrorSessionExpired;
            }
        } else if (statusCode == 403) { // HTTP forbidden
            if ([errorMessage isEqualToString:@"CGU_NOT_ACCEPTED"]) {
                return CloudErrorCGUNotAccepted;
            } else if ([errorMessage isEqualToString:@"USER_NOT_ELIGIBLE"]){
                return CloudErrorNotEligible;
            }
            return ForbiddenAccess;
        } else if (statusCode == 404) { // HTTP not found
            return CloudErrorNotFound;
        } else if (statusCode == 405) { // HTTP not found
            return CloudErrorMethodNotAllowed;
        } else if (statusCode == 500) {
            if ([errorMessage isEqualToString:@"SESSION_EXPIRED"]) {
                return CloudErrorSessionExpired;
            } else if ([errorMessage isEqualToString:@"TOO_BIG_FILE"]) {
                return CloudErrorFileTooBig;
            } else if ([errorMessage isEqualToString:@"NO_SPACE_LEFT"]) {
                return CloudErrorNoSpaceLeft;
            } else {
                return CloudErrorUnknown;
            }
        } else if (statusCode == 501) {
            return CloudCountryNotSupported;
        } else if (statusCode == 800) {
            return CloudAlreadyExists;
        }
    }
    return CloudErrorUnknown;
}

@end

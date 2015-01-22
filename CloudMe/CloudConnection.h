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


#import <Foundation/Foundation.h>
#import "CloudStatus.h"


typedef void (^OIDCCompletionHandler) (NSURLRequest *, NSError *);

/** A class similar to manage OpenID connections */
@interface OIDCConnection : NSObject

+ (void)sendAsynchronousRequest:(NSURLRequest *)request redirectURI:(NSString *)redirectURI completionHandler:(OIDCCompletionHandler)handler;

@end

typedef void (^CompletionHandler) (NSHTTPURLResponse *, NSData *, NSError *);

typedef void (^ProgressHandler) (float);

/** A class similar to manage cloud connections */
@interface CloudConnection : NSObject

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue message:(NSString*)message completionHandler:(CompletionHandler)completionHandler;

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue message:(NSString*)message progressHandler:(ProgressHandler)progressHandler completionHandler:(CompletionHandler)completionHandler;

@end

/** utility class to outpu debug information on connections */
@interface CloudUtil : NSObject 

+ (id) pack:(id) obj;

+ (void) dumpAsCurl:(NSURLRequest*)request withMessage:(NSString*)message;

+ (void) dumpAsJSON:(NSDictionary*)dictionary withMessage:(NSString*)message;

+ (CloudStatus) statusFromConnection:(NSURLResponse*)response data:(NSData*)data;


@end
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


#import "CloudManager.h"
#import "CloudItem.h"
#import "CloudConnection.h"
#import <Foundation/NSURLError.h>
#import "OIDCManager.h"

@implementation CloudError
- (id) initWithStatus:(CloudStatus)status {
    self = [super init];
    if (self) {
        self.status = status;
    }
    return self;
}
@end


@interface CloudManager ()

// the OpenID Connect manager to delagete use authentication to
@property (nonatomic) OIDCManager * oidcManager;

@property (nonatomic) NSString * cloudServer;
@property (nonatomic) NSString * contentServer;
@property (nonatomic) NSString * esid;
@property (nonatomic) NSDateFormatter * dateFormatter;
@property (nonatomic) NSString * verbSession;
@property (nonatomic) NSString * verbListFolder;
@property (nonatomic) NSString * verbCreateFolder;
@property (nonatomic) NSString * verbUpload;
@property (nonatomic) NSString * verbFileInfo;
@property (nonatomic) NSString * verbFreespace;
@property (nonatomic) NSString * verbDeleteFolder;
@property (nonatomic) NSString * verbDeleteFile;
@property (nonatomic) NSString * verbMoveFolder;
@property (nonatomic) NSString * verbMoveFile;

/** these alerts are used when user has not accepted end user licence agreements */
@property (nonatomic) UIAlertView * alertEULA;
@property (nonatomic) UIAlertView * alertSubscribe;

@end

typedef void (^RequestCallback)(NSURLResponse *response, NSData * data, NSError * error);


@implementation CloudManager

+ (CloudManager*)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


/** This delegate method deals with most common connection issues by redirecting user to the right WEB page */
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIApplication * application = [UIApplication sharedApplication];
    if (alertView == self.alertEULA) {
        NSURL * externAppUrl = [NSURL URLWithString:@"com.orange.fr.myco://"]; // official Orange Cloud application for iOS that let user accept CGU
        if ([application canOpenURL:externAppUrl]) {
            [application openURL:externAppUrl]; // lauch the offcial Orange Cloud app
        } else {
            [application openURL:[NSURL URLWithString:@"http://lecloud.orange.fr/?status=elu&api=cloud_fr_product"]];
        }
    } else if (alertView == self.alertSubscribe) {
        [application openURL:[NSURL URLWithString:@"http://lecloud.orange.fr/?status=eligible&api=cloud_fr_product"]];
    }
}

- (BOOL) canShowAlertFromStatus:(CloudStatus)status {
    if (status == CloudErrorCGUNotAccepted) {
        self.alertEULA = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"To connect to your Orange Cloud, thanks to first validate the service Terms & Conditions"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
        [self.alertEULA show];
        return YES;
    } else if (status == ForbiddenAccess) {
        self.alertSubscribe = [[UIAlertView alloc] initWithTitle:@""
                                                         message:@"You do not have an Orange Cloud. For further information, please connect to the Orange Cloud website"
                                                        delegate:self
                                               cancelButtonTitle:@"More information"
                                               otherButtonTitles:nil];
        [self.alertSubscribe show];
        return YES;
    } else {
        return NO;
    }
}
//#define BETA

- (id) initWithAppKey:(NSString*)appKey appSecret:(NSString*) appSecret redirectURI:(NSString*)redirectURI {
    self = [super init];
    if (self != nil) {
        
#ifdef BETA
        NSString * version = @"beta";
        NSString * mediaServer = @"http://alpha-api.orange.fr/cloud/beta";
        
#else
        NSString * version = @"v1";
        NSString * mediaServer = @"https://cloudapi.orange.com";
        
#endif
        // setup production servers
        self.cloudServer = @"https://api.orange.com";
        self.contentServer = mediaServer;

        // setup verbs to use
        self.verbSession = [NSString stringWithFormat:@"/cloud/%@/session", version];
        self.verbListFolder = [NSString stringWithFormat:@"/cloud/%@/folders/", version];
        self.verbCreateFolder = [NSString stringWithFormat:@"/cloud/%@/folders", version];
        self.verbUpload = [NSString stringWithFormat:@"/cloud/%@/files/content", version];
        self.verbFileInfo = [NSString stringWithFormat:@"/cloud/%@/files/", version];
        self.verbFreespace = [NSString stringWithFormat:@"/cloud/%@/freespace", version];
        self.verbDeleteFile = [NSString stringWithFormat:@"/cloud/%@/files/", version];
        self.verbDeleteFolder = [NSString stringWithFormat:@"/cloud/%@/folders/", version];
        self.verbMoveFolder = [NSString stringWithFormat:@"/cloud/%@/folders/", version];
        self.verbMoveFile = [NSString stringWithFormat:@"/cloud/%@/files/", version];

        // configure internal properties
        self.timeout = 60.0;
        _token = @"unvalidToken";
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
        [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        _isConnected = NO;
        
        // create the authent manager
        self.oidcManager = [[OIDCManager alloc] initWithAppKey:appKey appSecret:appSecret redirectURI:redirectURI];
        [self.oidcManager addScope:GrantScopeCloud];
        
    }
    return self;
}

+ (NSString*) statusString:(CloudStatus)status {
    switch (status) {
            case StatusOK:
            return @"Status ok";
            case InternalError:
            return @"internal error";
            case ServiceTemporarilyUnavailable:
            return @"service temporarily unavailable";
            case ServiceOverCapacity:
            return @"service over capacity";
            case InvalidURL:
            return @"invalid URL";
            case MissingBody:
            return @"missing body";
            case InvalidBody:
            return @"invalid body";
            case MissingBodyField:
            return @"missing body field";
            case InvalidBodyField:
            return @"invalid body field";
            case MissingHeader:
            return @"missing header";
            case InvalidHeaderValue:
            return @"invalid header value";
            case MissingQueryStringParameter:
            return @"missing query-string parameter";
            case InvalidQueryStringParameterValue:
            return @"invalid query-string parameter value";
            case MissingCredentials:
            return @"missing credentials";
            case InvalidCredentials:
            return @"invalid credentials";
            case ExpiredCredentials:
            return @"expired credentials";
            case AccessDenied:
            return @"access denied";
            case ForbiddenRequester:
            return @"forbidden requester";
            case ForbiddenUser:
            return @"forbidden requester";
            case TooManyRequests:
            return @"too many requests";
            case ResourceNotFound:
            return @"resource not found";
            case MethodNotAllowed:
            return @"method not allowed";
            case NotAcceptable:
            return @"header not acceptable";
            case RequestTimeOut:
            return @"request timeout";
            case LengthRequired:
            return @"length required";
            case PreconditionFailed:
            return @"precondition failed";
            case RequestEntityTooLarge:
            return @"request entity too large";
            case RequestURITooLong:
            return @"request URI too long";
            
            case AuthenticationOK:
            return @"successful";
            case AuthenticationErrorBadCredential:
            return @"bad credentials";
            case AuthenticationErrorBadRedirectURI:
            return @"bad redirect URI";
            case AuthenticationErrorNotGranted:
            return @"authorization not granted";
            case AuthenticationErrorResponseMalformed:
            return @"error in response";
            case AuthenticationErrorUnknown:
            return @"unknown error";

            
        case CloudErrorResponseMalformed:
            return @"malformed response";
        case CloudErrorListFolderFailed:
            return @"listing forlder failed";
        case CloudErrorSessionFailed:
            return @"opening session failed";
            case ForbiddenAccess:
            return @"Forbidden access";
        case CloudErrorNotEligible:
            return @"Not eligible";
        case CloudErrorCGUNotAccepted:
            return @"CGU not accepted";
        case CloudCountryNotSupported:
            return @"Country not supported";
        case CloudErrorBadParameter:
            return @"Bad parameter";
        case CloudErrorFileTooBig:
            return @"File too big";
        case CloudErrorMethodNotAllowed:
            return @"Method not allowed";
        case CloudErrorNetworkError:
            return @"Network error";
        case CloudErrorNoSpaceLeft:
            return @"No space left";
        case CloudErrorNotAFile:
            return @"Not a file";
        case CloudErrorSessionExpired:
            return @"Session has expired";
        case CloudInvalidToken:
            return @"Invalid token";
        case CloudMissingToken:
            return @"Missing token";
        case CloudAlreadyExists:
            return @"Already exists";
        case CloudErrorNotFound:
            return @"File not found";
        case CloudErrorUnknown:
            return [NSString stringWithFormat:@"%@ (%d)", @"unknown error", status];
    }
}

- (NSMutableURLRequest*) requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint {
    NSString * urlString;
    if ([endpoint hasPrefix:@"https://"]) {
        urlString = endpoint;
    } else if ([endpoint hasPrefix:@"http://"]) {
        urlString = endpoint;
    } else {
        urlString = [NSString stringWithFormat:@"%@%@", self.cloudServer, endpoint];
    }
    NSURL * sessionUrl = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:sessionUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.timeout];
    [request setHTTPMethod:method];
    [request setValue:[@"Bearer " stringByAppendingString:self.token] forHTTPHeaderField:@"Authorization"];
//    if (self.esid != nil) {
//        [request setValue:self.esid forHTTPHeaderField:@"X-Orange-CA-ESID"];
//    }
    return request;
}

- (NSMutableURLRequest *) postRequestWithEndpoint:(NSString*)endpoint filename:(NSString*)filename data:(NSData *)filedata folder:(NSString*)folderID {
    NSString *boundary = @"UploadBoundary";
    NSMutableURLRequest * request = [self requestWithMethod:@"POST" endpoint:[NSString stringWithFormat:@"%@%@", self.contentServer, endpoint]];
    
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData * body = [[NSMutableData alloc] init];
    
    // add header
    NSDictionary * dict = @{
                            @"name" : filename,
                            @"size" : [NSString stringWithFormat:@"%d", (int)filedata.length],
                            @"folder" : folderID,
                            };
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"description\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@", @"image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:filedata];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];

    return request;
}

- (void) addJSON:(NSString*)jsonString toRequest:(NSMutableURLRequest*) request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: [jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) sendRequest:(NSURLRequest*)request info:(NSString*)info completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))completionHandler {
    [self sendRequest:request info:info progressHandler:nil completionHandler:completionHandler];
}

- (void) sendRequest:(NSURLRequest*)request info:(NSString*)info progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))completionHandler {
    [CloudUtil dumpAsCurl:request withMessage:info];
    [CloudConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] message:TRACE_BANDWIDTH_USAGE ? info : nil progressHandler:progressHandler completionHandler:completionHandler];
}

- (void) openSessionFrom:(UIViewController*) parentController result:(ResultBlock)result {
    [self.oidcManager authenticateFrom:parentController completion:^(CloudStatus status, NSString *token, NSTimeInterval duration) {
        if (status == AuthenticationOK) {
            self.token = token;
            _isConnected = YES;

            result (StatusOK);
            //[self openSessionWithToken:token result:result];
        } else {
            result(status);
        }
    }];

}

- (void) logout {
    [self.oidcManager revokeCurrentAuthentication];
    _isConnected = NO;
}
- (BOOL)handleOpenURL:(NSURL *)url {
    return [self.oidcManager handleOpenURL:url];
}

- (void) setUseRefreshToken:(BOOL) useRefreshToken {
    self.oidcManager.useRefreshToken = useRefreshToken;
}

- (void) setForceLogin:(BOOL) forceLogin {
    self.oidcManager.forceLogin = forceLogin;
}

- (void) setForceConsent:(BOOL) forceConsent {
    self.oidcManager.forceConsent = forceConsent;
}

- (void) setUseWebView:(BOOL) useWebView {
    self.oidcManager.forceAuthentInWebView = useWebView;
}

- (void) addScope:(GrantScope)scope {
    [self.oidcManager addScope:scope];
}

- (void) openSessionWithToken:(NSString*)token result:(ResultBlock)result {
    self.token = token;
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" endpoint:self.verbSession];
    [self sendRequest:request info:@"openSession" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                CloudStatus status = [CloudUtil statusFromConnection:response data:data];
                result (status);
            } else if ([jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                [CloudUtil dumpAsJSON:dictionary withMessage:@"got token"];
//                self.esid = dictionary[@"esid"];
//                if (self.esid == nil) {
//                    result (CloudErrorResponseMalformed);
//                } else {
//                    _isConnected = YES;
//                    result(StatusOK);
//                }
            }
        } else {
            result ([CloudUtil statusFromConnection:response data:data]);
        }
    }];

}


- (void) reopenSession:(ResultBlock)result {
    _isConnected = NO;
    [self openSessionWithToken:self.token result:result];
}

- (void)rootFolder:(FileInfoBlock)result {
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:[self.verbListFolder stringByAppendingString:@"?restrictedmode"]];
    [self sendRequest:request info:@"listFolder" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                [CloudUtil dumpAsJSON:dictionary withMessage:@"root folder content"];
                result ([[CloudItem alloc] initWithDictionary:dictionary], StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"rootFolderWithSuccess: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self rootFolder:result]; }];
                //[self reopenSessionWithFailure:failure success:^{ [self rootFolderWithSuccess:success failure:failure]; }];
            } else {
                result (nil, status);
            }
        }
    }];

}

- (NSString*) getFilterName:(FilterType)type {
    return @"other";
}

- (void)listFolder:(CloudItem * _Nonnull)folderCloudItem
    restrictedMode:(BOOL)restrictedMode
    showThumbnails:(BOOL)showThumbnails
            filter:(FilterType)filter
              flat:(BOOL)flat
              tree:(BOOL)tree
             limit:(int)limit
            offset:(int)offset
            result:(ListFolderBlock _Nonnull)result {
    NSMutableURLRequest *request;

    NSString * endPoint = self.verbListFolder;

    NSString * prefix = @"?";
    
    if (folderCloudItem != nil) {
        endPoint = [endPoint stringByAppendingFormat:@"%@", folderCloudItem.identifier];
    }

    if (restrictedMode) {
        endPoint = [endPoint stringByAppendingFormat:@"%@restrictedmode", prefix];
        prefix = @"&";
    }
    if (showThumbnails) {
        endPoint = [endPoint stringByAppendingFormat:@"%@showthumbnails", prefix];
        prefix = @"&";
    }
    if (filter != FilterTypeAll) {
        endPoint = [endPoint stringByAppendingFormat:@"%@%@", prefix, [self getFilterName:filter]];
        prefix = @"&";
    }
    
    request = [self requestWithMethod:@"GET" endpoint:endPoint];
    [self sendRequest:request info:@"listFolder" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                [CloudUtil dumpAsJSON:dictionary withMessage:@"got folder content"];
                NSArray * fileArray = dictionary[@"files"];
                NSArray * dirArray = dictionary[@"subfolders"];
                NSMutableArray * files = [[NSMutableArray alloc] initWithCapacity:fileArray.count + dirArray.count];
                for (NSDictionary * dictionary in fileArray) {
                    [files addObject:[[CloudItem alloc] initWithDictionary:dictionary]];
                }
                for (NSDictionary * dictionary in dirArray) {
                    [files addObject:[[CloudItem alloc] initWithDictionary:dictionary]];
                }
                result (files, StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to reopen the session et relauch the request
                NSLog (@"listFolder: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self listFolder:folderCloudItem result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void)listFolder:(CloudItem * _Nonnull)folderCloudItem result:(ListFolderBlock _Nonnull)result {
    [self listFolder:folderCloudItem restrictedMode:NO showThumbnails:NO filter:FilterTypeAll flat:NO tree:NO limit:0 offset:0 result:result];
}

- (void) fileInfo:(CloudItem *)cloudFile result:(FileInfoBlock)result  {
    if (cloudFile.isDirectory == YES || cloudFile.identifier == nil) {
        result (nil, CloudErrorBadParameter);
        return;
    }
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:[self.verbFileInfo stringByAppendingString:cloudFile.identifier]];
    [self sendRequest:request info:@"fileInfo" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSMutableDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSMutableDictionary * dictionary = (NSMutableDictionary*)jsonObject;
                [CloudUtil dumpAsJSON:dictionary withMessage:@"got file info"];
                NSDate * date = [self.dateFormatter dateFromString:dictionary[@"creationDate"]];
                dictionary[@"creationDate"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
                [cloudFile setExtraInfo:dictionary];
                result (cloudFile, StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"fileInfo: session expired, retrying");
                [self reopenSession:^(CloudStatus status) { [self fileInfo:cloudFile result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void) getThumbnail:(CloudItem *)cloudFile result:(DataBlock)result  {
    if (cloudFile.thumbnailURL == nil) {
        result (nil, CloudErrorBadParameter);
        return;
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:cloudFile.thumbnailURL];
    [self sendRequest:request info:@"getThumbnail" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            result (data, StatusOK);
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"getThumbnail: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self getThumbnail:cloudFile result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void) getPreview:(CloudItem *)cloudFile result:(DataBlock)result {
    if (cloudFile.previewURL == nil) {
        result (nil, CloudErrorBadParameter);
        return;
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:cloudFile.previewURL];
    [self sendRequest:request info:@"getPreview" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            result (data, StatusOK);
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"getPreview: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self getPreview:cloudFile result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void) getFileContent:(CloudItem *)cloudFile result:(DataBlock)result  {
    if (cloudFile.downloadURL == nil) {
        result (nil, CloudErrorBadParameter);
        return;
    }
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:cloudFile.downloadURL];
    [self sendRequest:request info:@"getFileContent" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            result (data, StatusOK);
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"getFileContent: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self getFileContent:cloudFile result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void) createFolder:(NSString*)folderName parent:(CloudItem*)parentCloudItem result:(FileInfoBlock)result {
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" endpoint:self.verbCreateFolder];
    NSString * bodyString;
    if (parentCloudItem == nil) {
        bodyString = [NSString stringWithFormat:@"{ \"name\":\"%@\" }", folderName];
    } else {
        bodyString = [NSString stringWithFormat:@"{ \"name\":\"%@\", \"parentFolderId\":\"%@\" }", folderName, parentCloudItem.identifier];
    }
    [self addJSON:bodyString toRequest:request];
    [self sendRequest:request info:@"createFolder" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                CloudItem * folder = [[CloudItem alloc] initWithDictionary:dictionary];
                result (folder, StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open the session et relauch the request
                NSLog (@"createFolder: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self createFolder:folderName parent:parentCloudItem result:result]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}

- (void) getFreeSpace:(FreeSpaceBlock)result {
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" endpoint:self.verbFreespace];
    [self sendRequest:request info:@"freespace" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                result (-1, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                NSNumber * number = dictionary[@"freespace"];
                long size =  [number integerValue];
                result (size, StatusOK);
            }
        } else {
            result (-1, [CloudUtil statusFromConnection:response data:data]);
        }
    }];
}

- (void) uploadData:(NSData*)data filename:(NSString*)filename folderID:(NSString*)folderID progress:(ProgressBlock)progress result:(FileInfoBlock)result {
    NSMutableURLRequest * request = [self postRequestWithEndpoint:self.verbUpload filename:filename data:data folder:folderID];
    NSDate * startingDate = [NSDate date];
    float contentSize = data.length / 1024.0;
    [self sendRequest:request info:@"uploadData" progressHandler:progress completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            if (TRACE_BANDWIDTH_USAGE) {
                NSTimeInterval downloadTime = -[startingDate timeIntervalSinceNow];
                NSLog (@"***** Download of %g kB in %g s => %g kB/s", contentSize, downloadTime, floor(contentSize/downloadTime));
            }
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                CloudItem * file = [[CloudItem alloc] init];
                file.identifier = dictionary[@"fileId"];
                file.name = dictionary[@"fileName"];
                file.type = CloudTypeFile;
                result (file, StatusOK);
            }
        } else {
            result (nil, [CloudUtil statusFromConnection:response data:data]);
        }
    }];
}

- (void) deleteFolder:(CloudItem*)folderCloudItem result:(ResultBlock)result {
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE" endpoint:[self.verbDeleteFolder stringByAppendingString:folderCloudItem.identifier]];
    [self sendRequest:request info:@"deleteFolder" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            if (error != nil) {
                result (CloudErrorResponseMalformed);
            } else {
                result (StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"deleteFolder: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self deleteFolder:folderCloudItem result:result]; }];
            } else {
                result (status);
            }
        }
    }];
}

- (void) deleteFile:(CloudItem*)fileCloudItem result:(ResultBlock)result {
    if (fileCloudItem.identifier == nil) {
        result (CloudErrorNotAFile);
        return;
    }
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE" endpoint:[self.verbDeleteFile stringByAppendingString:fileCloudItem.identifier]];
    [self sendRequest:request info:@"deleteFile" completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            if (error != nil) {
                result (CloudErrorResponseMalformed);
            } else {
                result (StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open teh session et relauch the request
                NSLog (@"deleteFile: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self deleteFile:fileCloudItem result:result]; }];
            } else {
                result (status);
            }
        }
    }];
}

- (NSMutableURLRequest*) makeMoveRequest:(CloudItem * _Nonnull)item {
    NSString * verb = item.isDirectory ? self.verbMoveFolder : self.verbMoveFile;
    NSString * endPoint = [verb stringByAppendingString:item.identifier];
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" endpoint:endPoint];
    return request;
}

- (void) renameAux:(NSMutableURLRequest *)request bodyString:(NSString*) bodyString item:(CloudItem*)item result:(FileInfoBlock _Nonnull)result info:(NSString*)info {
    [self addJSON:bodyString toRequest:request];
    [self sendRequest:request info:info completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                result (nil, CloudErrorResponseMalformed);
            } else {
                NSDictionary * dictionary = (NSDictionary*)jsonObject;
                CloudItem * folder = [[CloudItem alloc] initWithDictionary:dictionary];
                folder.type = item.type;
                result (folder, StatusOK);
            }
        } else {
            CloudStatus status = [CloudUtil statusFromConnection:response data:data];
            if (status == CloudErrorSessionExpired || status == ExpiredCredentials) { // try to open the session et relauch the request
                NSLog (@"createFolder: session expired, retrying");
                [self reopenSession:^(CloudStatus status){ [self renameAux:request bodyString:bodyString item:item result:result info:info]; }];
            } else {
                result (nil, status);
            }
        }
    }];
}


- (void) rename :(CloudItem * _Nonnull)item newName:(NSString * _Nonnull)newName result:(FileInfoBlock _Nonnull)result {
    NSString * bodyString = [NSString stringWithFormat:@"{ \"name\":\"%@\" }", newName];
    [self renameAux:[self makeMoveRequest:item] bodyString:bodyString item:item result:result info:@"rename"];
}

- (void) move :(CloudItem * _Nonnull)item destination:(CloudItem * _Nonnull)destination result:(FileInfoBlock _Nonnull)result {
    NSString * bodyString = [NSString stringWithFormat:@"{ \"parentFolderId\":\"%@\" }", destination.identifier];
    [self renameAux:[self makeMoveRequest:item] bodyString:bodyString item:item result:result info:@"move"];
}

- (void) copy :(CloudItem * _Nonnull)item destination:(CloudItem * _Nonnull)destination result:(FileInfoBlock _Nonnull)result {
    NSString * bodyString = [NSString stringWithFormat:@"{ \"parentFolderId\":\"%@\", \"clone\" : true }", destination.identifier];
    [self renameAux:[self makeMoveRequest:item] bodyString:bodyString item:item result:result info:@"copy"];
}

@end

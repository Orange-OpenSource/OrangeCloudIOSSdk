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

#import "OIDCManager.h"
#import "CloudConnection.h"
#import "CloudConfig.h"

static NSString * kRefreshToken = @"refreshTokenKey";
static NSString * kAuthenticationRevoked = @"authenticationRevokedKey";

@interface OIDCManager () <UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    // the completion block to execute when authentication is done through a web page or using native external browser (safari)
    AuthenticationCompletion asyncCompletion;
}

/** the client id provided during the app registration */
@property (nonatomic) NSString * client_id;

/** the client secret provided during the app registration */
@property (nonatomic) NSString * client_secret;

/** the client redirect URI provided during the app registration */
@property (nonatomic) NSString * redirect_uri;

/** an arbitrary string that will associated with this authentication. This string is passed back when calling redirect URI */
@property (nonatomic) NSString * state;

/** Set to YES when the application needs to "logout" a user
 * Once set to YES, all calls to teh authent endpoint will have "login consent" in the prompt field.
 * This flag is set to NO when a new login is sucessful.
 */
@property (nonatomic) BOOL authenticationRevoked;

// properties used internally
@property (nonatomic) NSString * authentServer;  // server to use for authentication
@property (nonatomic) NSString * authentEndpoint; // endpoint for retrieving authorization code
@property (nonatomic) NSString * tokenEndpoint;   // endpoint to retreive a token from authorization
@property (nonatomic) NSString * response_type;
@property (nonatomic) NSString * prompt;

/** the refresh token retrieved during the first login/passwd authentication */
@property (nonatomic) NSString * refreshToken;

// the web view used for the registration process
@property (nonatomic) UIWebView * webView;

// flag to avoid trying to reconnect when coming back from safari
@property (nonatomic) BOOL connectingExternally;

/** a space separated list of rights to be granted by the user. This is build by teh addCope method */
@property (nonatomic) GrantScope scopes;

@end


@implementation OIDCManager


//- (void) setScope:(NSString *)scope {
//    _scope = [@"openid+" stringByAppendingString:scope];
//}

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret redirectURI:(NSString *)redirectURI {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.client_id = appKey;
        self.client_secret = appSecret;
        self.redirect_uri = [self consolidateURL:redirectURI];
        self.authentServer = @"https://api.orange.com";  // prod
        self.authentEndpoint = @"/oauth/v2/authorize";
        self.tokenEndpoint = @"/oauth/v2/token";
        self.scopes = GrantScopeOpenID;
        self.response_type = @"code";
        self.state = @"state";

        NSUserDefaults * defaults= [NSUserDefaults standardUserDefaults];
        _authenticationRevoked = [defaults boolForKey:kAuthenticationRevoked];
        _refreshToken = [defaults valueForKey:kRefreshToken];
        self.connectingExternally = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =  [UIColor whiteColor];
}

- (void) addScope:(GrantScope)scope {
    self.scopes |= scope;
}

- (NSString*) stringFromScopes {
    NSString * result = @"openid";
    if ((self.scopes & GrantScopeCloud) != 0) {
        result = [result stringByAppendingString:@"+cloud"];
    }
    if ((self.scopes & GrantScopeUserDetails) != 0) {
        result = [result stringByAppendingString:@"+details"];
    }
    if ((self.scopes & GrantScopeOfflineAccess) != 0) {
        result = [result stringByAppendingString:@"+offline_access"];
    }
    if ((self.scopes & GrantScopeFullRead) != 0) {
        result = [result stringByAppendingString:@"+cloudfullread"];
    }
    return result;
}

/** Build the URL string used to start the authentication process by appending all needed parameters to the server name end end point.
 * @return an url suitable for initiating the authication process
 */
- (NSString*) createAuthenticationUrlStringWithConsent:(BOOL)useConsent {
    // build the prompt string option
    self.prompt = @"";
    if (self.authenticationRevoked) {
        self.prompt = @"login consent";
    } else if (useConsent) {
        if (self.forceConsent) {
            if (self.forceLogin) {
                self.prompt = @"login consent";
            } else {
                self.prompt = @"consent";
            }
        } else if (self.forceLogin) {
            self.prompt = @"login";
        }
    } else {
        self.prompt = @"none";
    }
    if (self.useRefreshToken && self.refreshToken == nil) {
        [self addScope:GrantScopeOfflineAccess];
    }
    NSString * urlString = [NSString stringWithFormat:@"%@%@?", self.authentServer, self.authentEndpoint]; // create the full url like http://server/path?
    urlString = [urlString stringByAppendingFormat:@"scope=%@", [self stringFromScopes]];
    urlString = [urlString stringByAppendingFormat:@"&response_type=%@", self.response_type];
    urlString = [urlString stringByAppendingFormat:@"&client_id=%@", self.client_id];
    urlString = [urlString stringByAppendingFormat:@"&prompt=%@", self.prompt];
    urlString = [urlString stringByAppendingFormat:@"&state=%@", self.state];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlString = [urlString stringByAppendingFormat:@"&redirect_uri=%@", encodeToPercentEscapeString(self.redirect_uri)];
    return urlString;
}

NSString* encodeToPercentEscapeString(NSString *string) {
    return (NSString *)  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) string, NULL, (CFStringRef) @":/]", kCFStringEncodingUTF8));
}

/** The main entry point to start authentication. It will check silently if user is already authenticated and if so will retreive an athorization code and then a valid token.
 * This token can be used later on to open a cloud session. If a refresh token has been previously retreived, it is used instead authorization code to get the token.
 * @param parentController a view controller from wich to display a web view if needed
 * @param completion a user provided block called when authentication has been done
 */
- (void) authenticateFrom:(UIViewController*)parentController completion:(AuthenticationCompletion)completion {
    // if the case below is true, that means that we try to reconnect while coming back from safari and thus we should just ignore
    // this call as the process will continue in handleURL, but we have to unset it for next time
    NSLog (@"authenticateFrom %@", parentController);
    if (self.connectingExternally) {
        self.connectingExternally = NO;
        return;
    }
    // check if authent is not forced or revoked
    if (self.forceConsent == NO && self.forceLogin == NO && self.authenticationRevoked == NO) {
        if (self.refreshToken != nil) {
            [self getTokenOfType:RefreshToken code:self.refreshToken completion:completion];
        } else {
            [self checkForAuthenticationAlreadyDone:^(NSString * authorizationCode) {
                if (authorizationCode != nil) {
                    [self getTokenOfType:AuthorizationCode code:authorizationCode completion:completion];
                } else {
                    if (TRACE_API_CALL) { NSLog (@"[INFO] No authorization code: displaying login page"); }
                    [self displayLoginFrom:parentController completion:completion];
                }
            }];
        }
    } else { // force user authentication bu requesting a login, password and consent
        [self displayLoginFrom:parentController completion:completion];
    }
}


/** Display the login page from OpenID Connect. It opens either safari if the redirect_uri starts with a custom scheme or a inlined web view if teh redirect_uri starts with http or https.
 * @note the define FORCE_AUTHENT_IN_WEBVIEW can be set to YES in CloudCOnfig.h to force login in a webview
 * @param parentController a view controller from wich to display a web view if needed
 * @param completion a user provided block called when authentication has been done
 */

- (void) displayLoginFrom:(UIViewController*)parentController completion:(AuthenticationCompletion)completion {
    //NSLog (@"displayLoginFrom inwebview: %d", self.forceAuthentInWebView);
    asyncCompletion = completion; // record the block to call back when asynchronous login is done
    if (self.forceAuthentInWebView || [self.redirect_uri hasPrefix:@"http://"] || [self.redirect_uri hasPrefix:@"https://"]) {
        NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:[self createAuthenticationUrlStringWithConsent:YES]]];
        if (TRACE_API_CALL) { NSLog (@"[API CALL] display authentication web page:\n%@", request.URL); }
        if (self.webView == nil) {
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height)];
            self.webView.delegate = self;
            [self.view addSubview:self.webView];
        }
        [self.webView loadRequest:request];
        
        if (self.presentingViewController == NULL) {
            [parentController presentViewController:self animated:YES completion:^{ }];
        }

    } else { // we have a custom scheme, so we must use Safari to handle the authentication process
        // warning: this will obviously work only if the custom scheme used if the redirect uri (ie NOT http) is also declared in THIS app as a supported scheme
        NSString * url = [self createAuthenticationUrlStringWithConsent:YES];
        if (TRACE_API_CALL) { NSLog (@"[API CALL] open authentication web page in external web browser: %@", url); }
        self.connectingExternally = YES;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

- (void) checkForAuthenticationAlreadyDone:(AuthenticationCheck) checkCompletion {
    
        NSString * authentString = [self createAuthenticationUrlStringWithConsent:NO];
        NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:authentString]];
        [OIDCManager dumpAsCurl:request withMessage:@"authorize"];
        [OIDCConnection sendAsynchronousRequest:request redirectURI:self.redirect_uri completionHandler:^(NSURLRequest *request, NSError *connectionError) {
            if (TRACE_API_CALL) { NSLog (@"checkForAuthenticationAlreadyDone: response=%@, error=%@", request, connectionError); }
            checkCompletion ([self extractAuthorizationCodeFromURL:request.URL]);
        }];
}


- (void) setRefreshToken:(NSString *)refreshToken {
    _refreshToken = refreshToken;
    NSUserDefaults * defaults= [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.refreshToken forKey:kRefreshToken];
    [defaults synchronize];
}

- (void) setAuthenticationRevoked:(BOOL)authenticationRevoked {
    _authenticationRevoked = authenticationRevoked;
    NSUserDefaults * defaults= [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.authenticationRevoked forKey:kAuthenticationRevoked];
    [defaults synchronize];
}

- (void) revokeCurrentAuthentication {
    self.authenticationRevoked = YES;
    self.refreshToken = nil; // prevent reusing refreshToken next time
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView loadRequest:request];
}

/** Create a base64 encoded credentials needed when requesting the token.
 * It basically encode in base64 the concatenation of client_id and client_secret, separated by the single char ':'
 * @return the base 64 encoded credentials
 */
- (NSString *) encodedCredentials {
    NSString * credentials = [NSString stringWithFormat:@"%@:%@", self.client_id, self.client_secret];
    return [[credentials dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

typedef enum {
    AuthorizationCode,
    RefreshToken
} GrantType;

/** create a request to retrieve a token , either using an authorization code or using a refresh token 
 * @param grantType must be either AUthorizationCode or RefreshToken
 * @param code either the authorization code or teh refresh token, depending on grantType
 */

- (NSURLRequest*) createGetTokenRequestWidthType:(GrantType)grantType code:(NSString*)code {
    NSURL * tokenUrl = [NSURL URLWithString:[self.authentServer stringByAppendingString:self.tokenEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    
    // set the header with the autorization
    [request setValue:[NSString stringWithFormat:@"Basic %@", [self encodedCredentials]] forHTTPHeaderField:@"Authorization"];
    
    // build and set the request body content, which is a list of name=value, separater by '&':
    NSString * bodyString = [@"grant_type=" stringByAppendingString:grantType == AuthorizationCode ? @"authorization_code" : @"refresh_token"];
    bodyString = [bodyString stringByAppendingFormat:@"&%@=%@", grantType == AuthorizationCode ? @"code" : @"refresh_token", code];
    bodyString = [bodyString stringByAppendingFormat:@"&redirect_uri=%@", self.redirect_uri];
    
    if (TRACE_API_CALL) {
        NSLog (@"[API CALL] ask for token:\ncurl -X POST -D -H \"Authorization: Basic %@\" -d \"%@\" %@", [self encodedCredentials], bodyString, request.URL);
    }
    [request setHTTPBody: [bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

/** Retreive a token, either based on existing refresh token or once the authorization code has been obtained.
 * @param grantType must be either AUthorizationCode or RefreshToken
 * @param code either the authorization code or the refresh token, depending on grantType
 * @param completion the block to call whith etither the toen or the error code when process has failed
 */
- (void) getTokenOfType:(GrantType)grantType code:(NSString*)code completion:(AuthenticationCompletion)completion {
    // create the request to retreive the token from the authorization code
    NSURLRequest * request = [self createGetTokenRequestWidthType:grantType code:code];
    
    // make the request asynchronously
    [CloudConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] message:TRACE_BANDWIDTH_USAGE ? @"Get Token" : nil completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (connectionError == nil) {
                // no error, so the token should be there,
                NSError * error;
                NSObject * jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil || [jsonObject isKindOfClass:[NSDictionary class]] == NO) {
                    completion (AuthenticationErrorResponseMalformed, nil, 0);
                } else {
                    NSDictionary * dictionary = (NSDictionary*)jsonObject;
                    if (TRACE_API_CALL) {
                        NSLog (@"[API CALL] got token answer:\n%@", dictionary);
                    }
                    if (grantType == AuthorizationCode) {
                        self.refreshToken = dictionary[@"refresh_token"];
                    }
                    NSString * accessToken = dictionary[@"access_token"];
                    if (accessToken == nil) {
                        completion (AuthenticationErrorBadCredential, nil, 0);
                    } else {
                        completion (AuthenticationOK, accessToken, (NSTimeInterval)[dictionary[@"expires_in"] doubleValue]);
                    }
                }
            } else {
                // call delegate with error code
                if (TRACE_API_CALL) {
                    NSLog (@"[API CALL] error: %@", connectionError);
                    if (data != nil) {
                        NSLog(@"[API_CALL] error data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                    } else {
                        NSLog(@"[API_CALL] error no data");
                    }
                }
                completion (AuthenticationErrorBadCredential, nil, 0);
                
            }
        }];
    }];
    
}

/** Split an url that is supposed to be a redirect URL call coming from the OAuth V2 process and extract the attached authorization code if any/
 * @url an url coming potentially from the end of the OAuth process and thsu containing the application redirect_uri and an authorization code
 * @return the authorization code if any, nil otherwize
 */
- (NSString*)extractAuthorizationCodeFromURL:(NSURL*)url {
    // form is http://www.mycloudapp.com/?code=<Authorization code>&state=<state>&LANG=en
    NSArray * parameters = [url.query componentsSeparatedByString:@"&"];
    for (NSString * parameter in parameters) {
        if ([parameter hasPrefix:@"code="]) {
            return [parameter substringFromIndex:@"code=".length];
        }
    }
    return nil;
}

- (CloudStatus)extractErrorFromURL:(NSURL*)url {
    // form is http://www.mycloudapp.com/?error=<error>&description=<error description>&state=<state>&LANG=en
    NSArray * parameters = [url.query componentsSeparatedByString:@"&"];
    for (NSString * parameter in parameters) {
        if ([parameter hasPrefix:@"error_description="]) {
            NSString * message = [parameter substringFromIndex:@"error_description=".length];
            if ([message isEqualToString:@"consent denied"]) {
                return AuthenticationErrorNotGranted;
            }
        }
    }
    return AuthenticationErrorBadCredential;
}

- (BOOL) handleOpenURL:(NSURL*)url {
    return [self isRedirectURL:url];
}

- (NSString*) consolidateURL: (NSString*)url {
    NSArray * array = [url componentsSeparatedByString:@"://"];
    if (array.count == 2) {
        return [NSString stringWithFormat:@"%@://%@", [array[0] lowercaseString], array[1]];
    } else {
        return url;
    }
}

- (BOOL) isRedirectURL:(NSURL*)url {
    NSString * targetURL = [self consolidateURL:url.absoluteString];
    if ([targetURL hasPrefix:self.redirect_uri]) {
        if (TRACE_API_CALL) {
            NSLog (@"[API CALL] got redirect URI: \n%@", targetURL);
        }
        NSString * authorizationCode = [self extractAuthorizationCodeFromURL:url];
        if (authorizationCode != nil) {
            if (self.authenticationRevoked == YES) {
                self.authenticationRevoked = NO;
            }
            // here we start asynchronous token retrieval and return yes to stop web page loading
            [self getTokenOfType:AuthorizationCode code:authorizationCode completion:asyncCompletion];
        } else {
            asyncCompletion ([self extractErrorFromURL:url], nil, 0);
        }
        [self dismissViewControllerAnimated:YES completion:^{}];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - UIWebView delegate

/** this web view delegate method is used to trap redirect calls made internally in the web view.
 * In particular, when the redirection starts with the redirect URI, the web page should not be displayed but rather teh URL must be only used 
 * to extract the authentication code needed to retreive the token.
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self isRedirectURL:request.URL]) { // check whether we have the redirect URI
        return NO; // we do have the redirect URI, so dwe must NOT load the page
    }
    return YES; // probably an internal redirect during teh authentication process
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //NSLog (@"Webview loaded with %@", [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"]);
}

- (NSURLRequest *)connection: (NSURLConnection *)connection
             willSendRequest: (NSURLRequest *)request
            redirectResponse: (NSURLResponse *)redirectResponse {
    if (redirectResponse) {
        if ([self isRedirectURL:request.URL]) {
            [connection cancel];
        }
    }
    return request;
}

#pragma mark - 

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** utility method to pack a string to 64 chars for better lisibility in the debug console */
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

/** utility method to dump a NSURLRequest using the curl syntax, mostly for debugging purposes */
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

//+ (NSString*) statusString:(AuthenticationStatus)status {
//    switch (status) {
//        case AuthenticationOK:
//            return @"successful";
//        case AuthenticationErrorBadCredential:
//            return @"bad credentials";
//        case AuthenticationErrorBadRedirectURI:
//            return @"bad redirect URI";
//        case AuthenticationErrorNotGranted:
//            return @"authorization not granted";
//        case AuthenticationErrorResponseMalformed:
//            return @"error in response";
//        case AuthenticationErrorUnknown:
//            return @"unknown error";
//    }
//}

@end

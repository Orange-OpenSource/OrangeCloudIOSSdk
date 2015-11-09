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


#import <UIKit/UIKit.h>
#import "CloudStatus.h"

///** List of error codes that are used when an error occured during the authentication phase.
// */
//typedef enum {
//    /** Authentication has been successful */
//    AuthenticationOK,
//    
//    /** Incorrect credentials. Mostly occurs when either the client id or the client secret are not correct. Make sure to use the one declared during application registration*/
//    AuthenticationErrorBadCredential,
//        
//    /** an error occurent during the user grant process. Most likeley, user did not grant the rights proposed */
//    AuthenticationErrorNotGranted,
//    
//    /** the redirect url provided was incorrect. Make sure to use the one declared during application registration */
//    AuthenticationErrorBadRedirectURI,
//    
//    /** the server returned a malformed answer. Probably not so much to do at this point except retrying the authentication */
//    AuthenticationErrorResponseMalformed,
//
//    /** a generic error when something really unexpected occurred. Probably the best is to retry the authentication */
//    AuthenticationErrorUnknown,
//
//} AuthenticationStatus;
//

typedef void (^AuthenticationCompletion)(CloudStatus status, NSString * token, NSTimeInterval duration);
typedef void (^AuthenticationCheck)(NSString * authorizationCode);


/** This class is in charge of authenticating a user, given an application credentials. This results in a token that can be reused in other APIs like the Orange Cloud.
 * You stat the authentication process by either presenting a controller provided by this manager or by triggering extern authentication is safari.
 * In consequence it is mandatory to set all relevant information before calling either method.
 * Before requesting authentication, you can verify that
 * @warning The provided controller will dismiss itsel automatically whenever the authentication process is done.
 * @note client_id, client_secret and redirect_uri are provided by the registration platform when during the application creation process.
 * It is also very important to set the delegate object before pushing this controller in order to be sure to be informed of teh authentication result.
 */

@interface OIDCManager : UIViewController


/** Add a scope (i.e. feature) to the list of permissions the user must grant access.
 * The defaut scope is OpenID  to enable connection with user login/password. You must add all scopes relevant for your application 
 * and you will probably need to check the documentation of teh API you have registered to.
 * @warning this method must be called before authenticateFrom:
 * @see GrantScope
 * @param scope the new scope to be added in the grant list
 */
- (void) addScope:(GrantScope)scope;

/** if set to YES, the login screen is forced to be displayed even if user is already logged in. Default value is NO. */
@property (nonatomic) BOOL forceLogin;

/** if set to YES, the consent screen is forced to be displayed even if user has already given its consent. Default value is NO. */
@property (nonatomic) BOOL forceConsent;

/** When your application has been registered with offline access, you should set this property to yes. This wil result in requesting a special token that can be reused for following connections */
@property (nonatomic) BOOL useRefreshToken;

/** Usually when a redirectURI starts with a custom scheme, the authentication process is done externnaly, inside a web browser (i.e. Safari). For any reason, if you want to have this stpes done inside the application, you can set the property below to YES before calling authenticateFrom:completion:. Default value is NO */
@property (nonatomic) BOOL forceAuthentInWebView;

/** create a connection manager with your application credential
 * @param appKey the application key you got when your register your application
 * @param appSecret the application secret you got when your register your application
 * @param redirectURI the redirect URI you set when you register your application
 */
- (id) initWithAppKey:(NSString*)appKey appSecret:(NSString*) appSecret redirectURI:(NSString*)redirectURI;

/** Start the whole authentication process. This method should be called only when an error occured but can be fixed before restarting the process.
 * It is mostly a convenience method to avoid poping and pushing back this controller.
 */
- (void) authenticateFrom:(UIViewController*)parentController completion:(AuthenticationCompletion)completion;


/** Return whether the url is compatible with the current authent and if so, continue the connection process.
 * It is typically called from AppDelegate application:openURL:sourceApplication:annotation: 
 * @param a url that triggered 
 * @return YES if the parameter is compatible with teh actual authentication process
 */
- (BOOL)handleOpenURL:(NSURL *)url;


/** This function must be used when you want to revoke the current authentication, that is, you want to log out the current user.
 * All subsequent authorization requests will first trigger the authentication page display, prompting for login/password.
 */
- (void) revokeCurrentAuthentication;


///** This convenience method returns a message string given an error code
// *@param error the error code, usually passed to the delegate when connection failed
// *@return a human readable message corresponding to the error code
// */
//+ (NSString*)statusString:(AuthenticationStatus)status;
//


@end

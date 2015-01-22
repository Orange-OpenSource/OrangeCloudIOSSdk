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


#ifndef CloudMeSDK_CloudStatus_h
#define CloudMeSDK_CloudStatus_h
/** List of error codes that are used when an error occured during the connection with the cloud.
 */
typedef enum {
    /** 200: the command was successful */
    StatusOK = 0,
    
    /** 500: Generic failure message, used if no more precise code can be provided */
    InternalError = 1,
    
    /** 503: The service in charge of the requested endpoint is temporarily unavailable or unreachable */
    ServiceTemporarilyUnavailable = 5,
    
    /** 503: The service faces too much requests and can not handle the call */
    ServiceOverCapacity = 6,
    
    /** 400: One or more parameters in the URL are invalid values */
    InvalidURL = 20,
    
    /** 400: The server was expecting a body to be sent within the request */
    MissingBody = 21,
    
    /** 400: The posted body is not well-formed and thus can not be parsed */
    InvalidBody = 22,
    
    /** 400: Some required body fields are missing*/
    MissingBodyField = 23,
    
    /** 400: Some body fields contain invalid values */
    InvalidBodyField = 24,
    
    /** 400: One or more headers are missing */
    MissingHeader = 25,
    
    /** 400: One or more header contain invalid values */
    InvalidHeaderValue = 26,
    
    /** 400: One or more query-string parameters are missing */
    MissingQueryStringParameter = 27,
    
    /** 400: One or more query-string parameters contain invalid values */
    InvalidQueryStringParameterValue = 28,
    
    /** 401: The requested service needs credentials, but none were provided */
    MissingCredentials = 40,
    
    /** 401: The requested service needs credentials, but the ones provided were invalid */
    InvalidCredentials = 41,
    
    /** 410: The requested service needs credentials, and the ones provided were out-of-date */
    ExpiredCredentials = 42,
    
    /** 403: The application that makes the request is not authorized to access this endpoint */
    AccessDenied = 50,
    
    /** 403: The application that makes the request has been blocked */
    ForbiddenRequester = 51,
    
    /** 403: The application has made a request on behalf of a user that has been blocked */
    ForbiddenUser = 52,
    
    /** 403: The application has made too many calls and has exceeded the rate limit for this service */
    TooManyRequests = 53,
    
    /** 404: The requested URI or the requested resource does not exist */
    ResourceNotFound = 60,
    
    /** 405: The URI does not support the requested method */
    MethodNotAllowed = 61,
    
    /** 406: The Accept incoming header does not match any available content-type */
    NotAcceptable = 62,
    
    /** 408: The server timed out waiting for the incoming request*/
    RequestTimeOut = 63,
    
    /** 411: The request did not specify a Content-Length header, which is required by the requested resource*/
    LengthRequired = 64,
    
    /** 412: One of the precondition request headers failed to match.*/
    PreconditionFailed = 65,
    
    /** 413: The body of a request (PATCH, POST and PUT methods) is larger than the server is willing or able to process */
    RequestEntityTooLarge = 66,
    
    /** 414: The URI provided was too long for the server to process */
    RequestURITooLong = 67,
    
    /** Authentication has been successful */
    AuthenticationOK,

    /** Incorrect credentials. Mostly occurs when either the client id or the client secret are not correct. Make sure to use the one declared during application registration*/
    AuthenticationErrorBadCredential,
    
    /** an error occurent during the user grant process. Most likeley, user did not grant the rights proposed */
    AuthenticationErrorNotGranted,
    
    /** the redirect url provided was incorrect. Make sure to use the one declared during application registration */
    AuthenticationErrorBadRedirectURI,
    
    /** the server returned a malformed answer. Probably not so much to do at this point except retrying the authentication */
    AuthenticationErrorResponseMalformed,
    
    /** a generic error when something really unexpected occurred. Probably the best is to retry the authentication */
    AuthenticationErrorUnknown,

    /** a generic error when something really unexpected occurred. Probably the best is to retry the request */
    CloudErrorUnknown,
    
    /** The session cannot be open. Most likely that the token used is not correct*/
    CloudErrorSessionFailed,
    
    /** The session has expired. a cloud session mut be reopen. @see openSessionWithToken */
    CloudErrorSessionExpired,
    
    /** The CGU has not been accepted */
    CloudErrorCGUNotAccepted,
    
    /** Not allowed to access the ressource */
    ForbiddenAccess,
    
    /** Not Eligible to access the service (probably require a subscription) */
    CloudErrorNotEligible,
    
    /** Ressource not found */
    CloudErrorNotFound,
    
    /** The command list folder failed. Most likely that the root directory is not valid*/
    CloudErrorListFolderfailed,
    
    /** The server returned a malformed answer. Probably not so much to do at this point except retrying the authentication */
    CloudErrorResponseMalformed,
    
    /** A network error occured, probably not so much to do at this point except retry later */
    CloudErrorNetworkError,
    
    /** An expected parameter is incorrect (nil, bad value, ...) */
    CloudErrorBadParameter,
    
    /** An expected file parameter is actually a directory */
    CloudErrorNotAFile,
    
    /** The actual country has no cloud support*/
    CloudCountryNotSupported,
    
    /** The token used is invalid */
    CloudMissingToken,
    
    /** A token is needed to perform the call */
    CloudInvalidToken,
    
    /** The call of the method was not authorized*/
    CloudErrorMethodNotAllowed,
    
    /** The size of the latest  uploaded file was bigger that the maximum allowed size */
    CloudErrorFileTooBig,
    
    /** not enough space available with th ecurrent account to upload the file */
    CloudErrorNoSpaceLeft,
    
    
} CloudStatus;


#endif

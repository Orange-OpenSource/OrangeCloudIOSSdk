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
#import "CloudItem.h"
#import "CloudConfig.h"
#import "CloudStatus.h"

@interface CloudError : NSError
@property (nonatomic) CloudStatus status;
- (nonnull id) initWithStatus:(CloudStatus)status;
@end

/** The list of available filter options when listing a folder. Only one is applicable at a time. Use FilterTypeAll to get all the files.
 * @see listFolder
 */
typedef NS_ENUM(NSInteger, FilterType) {
    FilterTypeAll,
    FilterTypeImage,
    FilterTypeVideo,
    FilterTypeAudio,
    FilterTypeOther
};


/** a block type used when a remote operation has completed. On success, status is statusOK */
typedef __strong void (^ResultBlock) (CloudStatus status);

/** a block type used when a list of files and folders is available after a remote directory listing. On success, status is StatusOK and entries is non null. */
typedef __strong void (^ListFolderBlock) (NSArray * _Nullable entries, CloudStatus status);

/** a block type used when a list of files and folders is available after a remote directory listing. On success, status is StatusOK and cloudItem is non null. */
typedef __strong void (^FileInfoBlock) (CloudItem * _Nullable cloudItem, CloudStatus status);

/** a block type used to follow the progress of an operation such as uploding a file. 0 means that operation has just started and 1 is sent when opration was completed*/
typedef __strong void (^ProgressBlock) (float progress);

/** a block type used when content has been fetched from servers. Can be used when retrieving thumbnail of file content. On success, status is StatusOK and data is non null.*/
typedef __strong void (^DataBlock) ( NSData * _Nullable data, CloudStatus status);

/** a block type used when free space has been requested. On success, status is StatusOK and size > 0.*/
typedef __strong void (^FreeSpaceBlock) (long size, CloudStatus status);


/** This class encapsulates the Orange Cloud Web API with method calls, taking care of the low levels aspects, such as authorizations.
 * Due to the asynchronous nature of cloud requests, these methosd will generally not return a value directly but rather
 * will take a block as parameter that will be called upon success or failure of the underlying network operation. The status of the network operation is passed
 * as one of the block parameter, along with the request result.
 * A typical usage is to create an instance with the appd ID, secret and callback URL as defined in the Orange Partner portal. Once created this object can open a connection
 * with the Cloud Api using the connect method. then various methods provide means to interact with teh users cloud storage (folder listing, upload, download, ...)
 * @note during the connection phase, user is asked for his/her login and password, then is asked to grant the application access to resources. The specification of 
 * which resource will have granted acess is done through scopes. Please refer to the portal for more information and an up to date list of scopes
 */
@interface CloudManager : NSObject


/** This property reflects the connection state to the Orange Cloud. A value of YES means that 
 the connection is active and that all operations can be performed (list filen upload, donwload, ... */
@property (nonatomic, readonly) BOOL isConnected;

/** This is the token used to retrieve */
@property (nonatomic) NSString * _Nullable token;

/** The network sessions timeout, in case you want to adjust it for special purposes. Default value is 60 seconds */
@property (nonatomic) CGFloat timeout;

/** Utility method that returns a readable string version of an error.
 * @param error the error code to be converted into a readable string.
 * @return a string representation of the error, suitable to be presented to a user.
 */
+ (NSString * _Nonnull) statusString:(CloudStatus)status;


/** create a cloud session with your application credential
 * @param appKey the application key you got when your register your application
 * @param appSecret the application secret you got when your register your application
 * @param redirectURI the redirect URI you set when you register your application
 */
- (id _Nonnull) initWithAppKey:(NSString * _Nonnull)appKey appSecret:(NSString*_Nonnull) appSecret redirectURI:(NSString*_Nonnull)redirectURI;

/** Add a scope (i.e. feature) to the list of permissions the user must grant access.
 * The defaut scopes are OpenID and Cloud, to enable connection with user login/password and access to the private part of 
 * the cloud the app is allowed to read and write.
 * @warning this method must be called before openSessionFrom:
 * @see GrantScope
 * @param scope the new scope to be added in the grant list
 */
- (void) addScope:(GrantScope)scope;


/** Use this method to configure the connection behavior when your application has been registered with offline access. In this case you should call this method with YES.
 * This wil result in requesting a special token that can be reused for subsequent connections.
 * @warning this method must be called before openSessionFrom:
 */
- (void) setUseRefreshToken:(BOOL) useRefreshToken;


/** Use this method when you want to force display of the authentication page. User will have to enter his/her credentials during the connect step.
 * @note default value is NO
 * @warning this method must be called before openSessionFrom:
 */
- (void) setForceLogin:(BOOL) forceLogin;


/** Use this method when you want to force display of the consent page. User will have to give his/her consent during the connect step.
 * @warning this method must be called before openSessionFrom:
 * @note default value is NO
 */
- (void) setForceConsent:(BOOL) forceConsent;


/** Use this method when you want to force display the login page in a web view instead of calling the native web browser. This is useful only if your redirect uri
 * is not a custom scheme your app has registered.
 * @note default value is NO
 * @warning this method must be called before openSessionFrom:
 */
- (void) setUseWebView:(BOOL) useWebView;


/** Open a cloud session. You must call this method first to be able to access to cloud information. No parameter is returned, rather a bloc of code is called
 * when either the session was successfully open or failed. The authentication phase is auomatically handled during this call by either asking
 * user credentials or resuing stored persistents tokens.
 * @param parentController a valid UIViewController from which a webview can be open, if needed
 * @param result a block of code called when the session is open or failed. The status of the connection is passed as the parameter
 *
 @code
 [self.cloudSession openSessionFrom:rootController result:^(CloudStatus status) {
     if (status == StatusOK) {
         NSLog (@"Session successfully open!");
         // start using other cloud methods
     } else {
         NSLog (@"Error while opening session: %@", [CloudSession statusString:status]);
     }
 }];
 @endcode
 */
- (void) openSessionFrom:(UIViewController* _Nonnull) parentController result:(ResultBlock _Nonnull)result;


/** Close the current cloud session. You will need to call openSessionFrom: again to open a new session with either the same or another user.
 * @note Despite the REST API is stateless, and thus have no close verb, you may need to ensure, in your application, that the user has been disconnect.
 * This is achieved with this utility method.
 */
- (void) logout;

/** Return whether the url is compatible with the current authent and if so, continue the connection process.
 * It is typically called from AppDelegate application:openURL:sourceApplication:annotation: When this method returns YES, a token has been extracted 
 * from the url and your appication can start access teh user's cloud.
 * @param url the url that triggered activation of the application from an external process, typically Safari.
 * @note You must have added a custom scheme management in your application and used it as the callback URL in order to use this mechanism.
 * @see setUseWebView:
 * @return YES if the url is compatible with the actual authentication process and a token has been successfully extracted
 */
- (BOOL)handleOpenURL:(NSURL * _Nonnull)url;

/** When opening a session failed, there are a few cases related to the Cloud management itself and requiring secific user actions.
 * The following method will handle these cases and display an alert popup that can lead to the proper action upon user agreement.
 * You will typically call this method in the failure block of the openSessionWithToken method.
 * @param error the error status passed as a parameter in the failure block of the openSessionWithToken method
 * @return true if the alert is related to Orange CLoud internal management (and thus an alert has been displayed). False is returned when teh error is not
 * directtly related to Orange Cloud (network issue for instance)
 */
 
- (BOOL) canShowAlertFromStatus:(CloudStatus)error;

/** Return the root folder. This is useful when you are in restricted mode and you don't know the root forlder that has been assign to your application.
 * This is typically the first API call after openSession. In the success callback, you may want to call listFolder, for example.
 * @param result a block of code called with the cloud file object representing the root folder and StatusOK, or nil and the error code if a problem occurred.
 @code
 [[CloudManager sharedInstance] rootFolderWithSuccess:^(CloudItem * cloudItem) {
     // list all files and folders at "root" level
     [[CloudManager sharedInstance] listFolder:cloudItem.identifier success ^(NSArray * items){
         for (CloudItem * item in items) {
             NSLog (@"got item :%@", item.identifier);
         }
     }];
 } failure:^(CloudStatus error) {
     NSLog (@"Error while getting root folder: %@", [CloudManager errorString:error]);
 }];
@endcode
 */
- (void)rootFolder:(FileInfoBlock _Nonnull)success;

/** List the content of a folder. You must call this method first to be able to access to cloud information. No parameter is returned, rather a bloc of code is called
 * when either the session was successfully open or failed.
 * @param folderCloudItem the cloud item of a folder, previously retrieved from the cloud, with a previous call to this listFolder method. if @c folderID is nil, the root folder is listed.
 * @param restrictedMode if true, the application folder will be considered as the root folder, even in full mode.
 * @param showThumbnails if true, the response will contain the thumbnail/preview/download urls for every listed file.
 * @param filter if not FilterTypeAll, restricts the result to a specified universe. See filterType for possible values.
 * @param flat if true, the folder will be browsed recursively and the full content will be returned.
 * @param tree if true, only subfolders will be returned.
 * @param limit specifies the maximum number of elements to be listed. No limit is specified with 0.
 * @param offset Specifies the offset of the first element to be listed. Typically use 0 if no limits are specified.
 * @param result a block of code called with the list of files contained in the folder and StatusOK, or nil and the error code if a problem occurred.
 * @note You probably need to first get the root folder content, using nil as the folderID. Then you can browse recursively the user file tree using this method.
 */
- (void)listFolder:(CloudItem * _Nonnull)folderCloudItem
    restrictedMode:(BOOL)restrictedMode
    showThumbnails:(BOOL)showThumbnails
            filter:(FilterType)filter
              flat:(BOOL)flat
              tree:(BOOL)tree
             limit:(int)limit
             offset:(int)offset
            result:(ListFolderBlock _Nonnull)result;

/** Convenient method to list a folder with default option values :
 * restrictedMode, showThumbnails, flat, tree are false, filter is FilterTypeAll, limit and offset are zero
 * @warning the download url is not fetched using this set of default parameters. This may have an impact on existing code. You should probably use the other listFolder call with showThumnails set to TRUE. 
 */
- (void)listFolder:(CloudItem* _Nonnull)folderCloudItem result:(ListFolderBlock _Nonnull)result;

/** Get more information about a file. In particular, the following information is returned: size, creation time, thumbnail and download URL.
 * @note the cloud file object passed to the @i success callback is the one passed as first parameter, with new field values.
 * @param cloudFile an object returned by listFolder.
 * @param result a block of code called with the initial cloud file object augmented with new field values (like size, creation time, thumbnail and download URL) and StatusOK, or nil and the error code if a problem occurred..
 */
- (void) fileInfo:(CloudItem * _Nonnull)cloudFile result:(FileInfoBlock _Nonnull)result;

/** Get the available space of the current account.
 * @param result a block of code called with the available free space, in bytes and StatusOK, or nil and the error code if a problem occurred.
 */
- (void) getFreeSpace:(FreeSpaceBlock _Nonnull) result;

/** Fetch the thumbnail data associated with file stored in the cloud. A thumbnail is a small and square graphical (around 144x144) representation of the content data.
 * The data returned in the @i success callback are suitable to be decoded as an image, like below:
@code
[CloudManager sharedInstance] getThumbnail:cloudFile result:^(NSData*data, CloudStatus status) {
    if (status == StatusOK) {
        imageView.image = [UIImage imageWidthData:data];
    } else {
        imageView.image = defaultImage;
    }
 }];
@endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the thumbnail URL.
 * @param result a block of code called with the data associated with the thumbnail and StatusOK, or nil and the error code if a problem occurred.
 */
- (void) getThumbnail:(CloudItem * _Nonnull)cloudFile result:(DataBlock _Nonnull)result;

/** Get the preview image associated with file stored in the cloud. A preview is a small version of the graphical 
 * representation of the content data, suitable to be displayed on a mobile phone screen.
 * The data returned in the @i success callback are suitable to be decoded as an image, like below:
 @code
 [CloudManager sharedInstance] getPreview:cloudFile success:^(NSData*data, CloudStatus status) {
    if (status == StatusOK) {
        imageView.image = [UIImage imageWidthData:data];
    } else {
        imageView.image = defaultImage;
    }
 }];
 @endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the thumbnail URL.
 * @param success a block of code called with the data associated with the preview and StatusOK, or nil and the error code if a problem occurred.
 */
- (void) getPreview:(CloudItem * _Nonnull)cloudFile result:(DataBlock _Nonnull)result;

/** Create a new folder.
 * @note The parent folder identifier is typically retreived with a listFolder call.
 * @param folderName the name of the folder to be created.
 * @param parentCloudItem the cloud item of the folder to be created.
 * @param result a block of code called with the new folder info and StatusOK, or nil and the error code if a problem occurred.
 */
- (void) createFolder:(NSString*_Nonnull)folderName parent:(CloudItem*_Nonnull)parentCloudItem result:(FileInfoBlock _Nonnull)result;

/** Retrieve the file content stored in the cloud.
 * The data returned in the @i success callback is the exact content of the file. For instance, if the file is an image, its usage is pretty similar to getThumbnail:
 @code
 [CloudManager sharedInstance] getFileContent:cloudFile success:^(NSData*data, CloudStatus status) {
    if (status == StatusOK) {
        imageView.image = [UIImage imageWidthData:data];
    } else {
        imageView.image = defaultImage;
    }
 }];
 @endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the download URL.
 * @param result a block of code called with the file content data and StatusOK, or nil and the error code if a problem occurred.
 */
- (void) getFileContent:(CloudItem * _Nonnull)cloudFile result:(DataBlock _Nonnull)result;

/** Rename a file or a folder
 * @param cloudFile the cloud file object to rename.
 * @param newName the new name to use for the cloud object
 * @param result a block of code called with the new file/folder info and StatusOK, or nil and the error code if a problem occurred.
 * @warning the id of renamed the file will have probably changed
 */
- (void) rename :(CloudItem * _Nonnull)cloudFile newName:(NSString * _Nonnull)newName result:(FileInfoBlock _Nonnull)result;

/** Move a file or a folder
 * @param cloudFile the cloud file object to rename.
 * @param destination the cloud item for the destination
 * @param result a block of code called with the new file/folder info and StatusOK, or nil and the error code if a problem occurred.
 * @warning the id of renamed the file will have probably changed
 */
- (void) move :(CloudItem * _Nonnull)cloudFile destination:(CloudItem * _Nonnull)destination result:(FileInfoBlock _Nonnull)result;

/** Copy a file or a folder
 * @param cloudFile the cloud file object to rename.
 * @param destination the cloud item that will contain the copy
 * @param result a block of code called with the new file/folder info and StatusOK, or nil and the error code if a problem occurred.
 * @warning the id of renamed the file will have probably changed
 */
- (void) copy :(CloudItem * _Nonnull)cloudFile destination:(CloudItem * _Nonnull)destination result:(FileInfoBlock _Nonnull)result;

/** Upload data content in a new file inside a folder
 * @param data the data to upload. This can be arbitrary data, like text or binary image compressed data.
 * @param filename the name of file that will be created and that will contain data.
 * @param folderID the identifier of the folder that will contain the newly created file (typically destinationCloudItem.identifier).
 * @param progress a block of code called whenever a chunk of data has been uploaded. The parameter is teh download percentage, from 0 to 1.
 * @param result a block of code called when data has been succesfully uploaded or when a problem occurred.
 */
- (void) uploadData:(NSData*_Nonnull)data filename:(NSString*_Nonnull)filename folderID:(NSString*_Nonnull)folderID progress:(ProgressBlock _Nullable)progress result:(FileInfoBlock _Nonnull)result;

/** Delete a folder and all its files and subfolders. You should really pay attention when calling this method as files will be permanentely deleted.
 * @param folderCloudItem the cloudItem of the folder that is to be deleted.
 * @param result a block of code called when folder has been succesfully deleted or when a problem occurred.
 */
- (void) deleteFolder:(CloudItem * _Nonnull)folderCloudItem result:(ResultBlock _Nonnull)result;

/** Delete permanentely a single file.
 * @param fileCloudItem the cloudItem of the folder that is to be deleted.
 * @param result a block of code called when file has been succesfully deleted or when a problem occurred.
 */
- (void) deleteFile:(CloudItem * _Nonnull)fileCloudItem result:(ResultBlock _Nonnull)result;

@end

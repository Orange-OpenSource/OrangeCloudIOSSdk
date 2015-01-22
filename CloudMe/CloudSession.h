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


/** a block type used when an operation when no output parameter has been successful. */
typedef __strong void (^SuccessBlock) ();

/** a block type used when an error occured during a remote operation. */
typedef __strong void (^FailureBlock) (CloudStatus status);

/** a block type used when a list of files and folders is available after a remote directory listing. */
typedef __strong void (^ListFolderBlock) (NSArray * entries);

/** a block type used when a list of files and folders is available after a remote directory listing. */
typedef __strong void (^FileInfoBlock) (CloudItem * cloudFile);

/** a block type used to follow the progress of an operation such as uploding a file. 0 means that operation has just started and 1 is sent when opration was completed*/
typedef __strong void (^ProgressBlock) (float progress);

/** a block type used when content has been fetched from servers. Can be used when retrieving thumbnail of file content. */
typedef __strong void (^DataBlock) (NSData * data);

/** a block type used when free space has been requested. */
typedef __strong void (^FreeSpaceBlock) (long size);

/** This class encapsulates the cloud management with method calls, taking care of the low levels aspects, such as authorizations.
 * Due to the asynchronous nature of cloud requests, these methos will generally not return a value directly but rather 
 * will take blocks as parameters that will be called upon success of failure of the underlying network operation.
 */
@interface CloudSession : NSObject


/** This property reflects the connection state to the Orange Cloud. A value of YES means that 
 the connection is active and that all operations can be performed (list filen upload, donwload, ... */
@property (nonatomic, readonly) BOOL isConnected;

/** The network sessions timeout, in case you want to adjust it for special purposes. Default value is 60 seconds */
@property (nonatomic) CGFloat timeout;

/** Utility method that returns a readable string version of an error.
 * @param error the error code to be converted into a readable string.
 * @return a string representation of the error, suitable to be presented to a user.
 */
+ (NSString*) statusString:(CloudStatus)status;


/** create a cloud session with your application credential
 * @param appKey the application key you got when your register your application
 * @param appSecret the application secret you got when your register your application
 * @param redirectURI the redirect URI you set when you register your application
 */
- (id) initWithAppKey:(NSString*)appKey appSecret:(NSString*) appSecret redirectURI:(NSString*)redirectURI;

/** Open a cloud session. You must call this method first to be able to access to cloud information. No parameter is returned, rather a bloc of code is called
 * when either the session was successfully open or failed. The authentication phase is auomatically handled during this call by either asking
 * user credentials or resuing stored persistents tokens.
 * @param parentController a valid UIViewController from which a webview can be open, if needed
 * @param success a block of code called when the session is open.
 * @param failure a block of code called when the session failed.
 *
 @code
 [self.cloudSession openSessionFrom:rootController success:^{
 NSLog (@"Session successfully open!");
 // start using other cloud methods
 } failure:^(CloudStatus status) {
 NSLog (@"Error while opening session: %@", [CloudSession statusString:status]);
 }];
 @endcode
 */
- (void) openSessionFrom:(UIViewController*) parentController success:(SuccessBlock)success failure:(FailureBlock)failure;

/** Use this method to configure the connection behavior when your application has been registered with offline access. In this case you should call this method with YES.
 * This wil result in requesting a special token that can be reused for following connections.
 * @warning this method must be called before openSessionFrom:
 */
- (void) setUseRefreshToken:(BOOL) useRefreshToken;

/** Use this method when you want to force display of the authentication page.
 * @warning this method must be called before openSessionFrom:
 */
- (void) setForceLogin:(BOOL) forceLogin;

/** Use this method when you want to force display of the consent page.
 * @warning this method must be called before openSessionFrom:
 */
- (void) setForceConsent:(BOOL) forceConsent;

/** Use this method when you want to force display the login page in a web view instead of calling the native web browser. This is useful only if your redirect uri
 * is not a custom scheme your app has registered.
 * @warning this method must be called before openSessionFrom:
 */
- (void) setUseWebView:(BOOL) useWebView;

/** close the current cloud session. You will need to call openSessionFrom: to open a new session with either the same or another user*/
- (void) logout;

/** Return whether the url is compatible with the current authent and if so, continue the connection process.
 * It is typically called from AppDelegate application:openURL:sourceApplication:annotation:
 * @param a url that triggered
 * @return YES if the parameter is compatible with teh actual authentication process
 */
- (BOOL)handleOpenURL:(NSURL *)url;

/** When opening a session failed, there are a few cases related to the Cloud management itself and requiring secific user actions.
 * The following method will handle these cases and display an alert popup that can lead to the proper action upon user agreement.
 * You will typically call this method in the failure block of the openSessionWithToken method.
 * @param error teh error status passed as a parameter in the failure block of the openSessionWithToken method
 */
 
- (BOOL) canShowAlertFromStatus:(CloudStatus)error;

/** Return the root folder. This is useful when you are in restricted mode and you don't know the root forlder that has been assign to your application.
 * This is typically the first API call after openSession. In the success callback, you may want to call listFolder, for example.
 * @param success a block of code called with the cloud file object representing the root folder.
 * @param failure a block of code called when the request failed with corresponding CloudStatus error
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
- (void)rootFolderWithSuccess:(FileInfoBlock)success failure:(FailureBlock)failure;

/** List the content of the root . You must call this method first to be able to access to cloud information. No parameter is returned, rather a bloc of code is called
 * when either the session was successfully open or failed.
 * @param folderCloudItem the cloud item of a folder, previously retrieved from the cloud, with a previous call to this listFolder method. if @c folderID is nil, the root folder is listed.
 * @param success a block of code called with the list of files contained in the folder.
 * @param failure a block of code called when the request failed.
 * @note You probably need to first get the root folder content, using nil as the folderID. Then you can browse recursively the user file tree using.
 */
- (void)listFolder:(CloudItem*)folderCloudItem success:(ListFolderBlock)success failure:(FailureBlock)failure;

/** Get more information about a file. In particular, the following information is returned: size, creation time, thumbnail and download URL.
 * @note the cloud file object passed to the @i success callback is the one passed as first parameter, with new field values.
 * @param cloudFile an object returned by listFolder.
 * @param success a block of code called with the initial cloud file object augmented with new field values (like size, creation time, thumbnail and download URL).
 * @param failure a block of code called when the request failed.
 */
- (void) fileInfo:(CloudItem *)cloudFile success:(FileInfoBlock)success failure:(FailureBlock)failure;

/** Get the available space of the current account.
 * @param success a block of code called with the available free space, in bytes.
 * @param failure a block of code called when the request failed.
 */
- (void) getFreeSpace:(FreeSpaceBlock)success failure:(FailureBlock)failure;

/** Fetch the thumbnail data associated with file stored in the cloud. A thumbnail is a small and square graphical (around 144x144) representation of the content data.
 * The data returned in the @i success callback are suitable to be decoded as an image, like below:
@code
[CloudManager sharedInstance] getThumbnail:cloudFile success:^(NSData*)data {
 imageView.image = [UIImage imageWidthData:data];
 }
 failure (CloudStatus status) {
 imageView.image = defaultImage;
 }
];
@endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the thumbnail URL.
 * @param success a block of code called with the data associated with the thumbnail.
 * @param failure a block of code called when the request failed.
 */
- (void) getThumbnail:(CloudItem *)cloudFile success:(DataBlock)success failure:(FailureBlock)failure;

/** Get the preview image associated with file stored in the cloud. A preview is a small version of the graphical 
 * representation of the content data, suitable to be displayed on a mobile phone screen.
 * The data returned in the @i success callback are suitable to be decoded as an image, like below:
 @code
 [CloudManager sharedInstance] getPreview:cloudFile success:^(NSData*)data {
 imageView.image = [UIImage imageWidthData:data];
 }
 failure (CloudStatus status) {
 imageView.image = defaultImage;
 }
 ];
 @endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the thumbnail URL.
 * @param success a block of code called with the data associated with the preview.
 * @param failure a block of code called when the request failed.
 */
- (void) getPreview:(CloudItem *)cloudFile success:(DataBlock)success failure:(FailureBlock)failure;

/** Create a new folder.
 * @note The parent folder identifier is typically retreived with a listFolder call.
 * @param folderName the name of the folder to be created.
 * @param parentCloudItem the cloud item of the folder to be created.
 * @param success a block of code called with the available free space, in bytes.
 * @param failure a block of code called when the request failed.
 */
- (void) createFolder:(NSString*)folderName parent:(CloudItem*)parentCloudItem success:(FileInfoBlock)success failure:(FailureBlock)failure;

/** Retrieve the file content stored in the cloud.
 * The data returned in the @i success callback is the exact content of the file. For instance, if the file is an image, its usage is pretty similar to getThumbnail:
 @code
 [CloudManager sharedInstance] getFileContent:cloudFile success:^(NSData*)data {
 imageView.image = [UIImage imageWidthData:data];
 }
 failure (CloudStatus status) {
 imageView.image = defaultImage;
 }
 ];
 @endcode
 * @warning the file info must have been retrieved first to be able to call this method.
 * @param cloudFile the cloud file object containing the download URL.
 * @param success a block of code called with the file content data.
 * @param failure a block of code called when the request failed.
 */
- (void) getFileContent:(CloudItem *)cloudFile success:(DataBlock)success failure:(FailureBlock)failure;

/** Upload data content in a new file inside a folder
 * @param data the data to upload. This can be arbitrary data, like text or binary image compressed data.
 * @param filename the name of file that will be created and that will contain data.
 * @param folderID the identifier of the folder that will contain the newly created file (typically destinationCloudItem.identifier).
 * @param progress a block of code called whenever a chunk of data has been uploaded. The parameter is teh download percentage, from 0 to 1.
 * @param success a block of code called when data has been succesfully uploaded.
 * @param failure a block of code called when the upload failed.
 */
- (void) uploadData:(NSData*)data filename:(NSString*)filename folderID:(NSString*)folderID progress:(ProgressBlock)progress success:(FileInfoBlock)success failure:(FailureBlock)failure;

/** Delete a folder and all its files and subfolders. You should really pay attention when calling this method as files will be permanentely deleted.
 * @param folderCloudItem the cloudItem of the folder that is to be deleted.
 * @param success a block of code called when folder has been succesfully deleted.
 * @param failure a block of code called when the deletion failed.
 */
- (void) deleteFolder:(CloudItem*)folderCloudItem success:(SuccessBlock)success failure:(FailureBlock)failure;

/** Delete permanentely a single file.
 * @param fileCloudItem the cloudItem of the folder that is to be deleted.
 * @param success a block of code called when file has been succesfully deleted.
 * @param failure a block of code called when the deletion failed.
 */
- (void) deleteFile:(CloudItem*)fileCloudItem success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

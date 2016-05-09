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
#import <UIKit/UIKit.h>

@class CloudItem;

/** List of available item types */
typedef enum {
    /** item is an image/photo (ex: png, jpg) */
    CloudTypeImage,
    /** item is an audio file (ex: mp3, m4a */
    CloudTypeAudio,
    /** item is a video (ex: mp4, mov */
    CloudTypeVideo,
    /** item is a directory */
    CloudTypeDirectory,
    /** item is a file of unknown type*/
    CloudTypeFile,
} CloudType;

/** This class encapsulate all information about a file or a directory stored on the Oraneg Cloud.
 * Both elements share the same information, while a directory have its type set to CloudTypeDirectory
 */
@interface CloudItem : NSObject

/** The unique identifier for this file (base64 decadable for debug) */
@property (nonatomic) NSString * identifier;

/** The readable name */
@property (nonatomic) NSString * name;

/** The item type (directory, image, video, ...*/
@property (nonatomic) CloudType type;

/** The size, ine bytes, of the item, only available for plain files (i.e. not a directory) */
@property (nonatomic, readonly) int size;

/** The creation date of the item, only available for plain files (i.e. not a directory) */
@property (nonatomic, readonly) NSDate * creationDate;

/** The URL to download a preview thumbnail, only available for plain files (i.e. not a directory) */
@property (nonatomic, readonly) NSString * downloadURL;

/** The URL to download a very small graphical representation of the file, only available for some file type (photo, pdf, ...) */
@property (nonatomic, readonly) NSString * thumbnailURL;

/** The URL to download a graphical representation suitable to be displayed in full screen on a mobile device, only available for some file type (photo, pdf, ...) */
@property (nonatomic, readonly) NSString * previewURL;

/** The unique identifier of the parent directory containing this folder (not available for folders) */
@property (nonatomic, readonly) NSString * parentIdentifier;

/** A flag set to YES if the item is a directory, set to NO if the item is a plain file*/
@property (nonatomic, readonly) BOOL isDirectory;

/** A flag set to yes when extra information (i.e. size, urls, creation time) has been fetched */
@property (nonatomic) BOOL extraInfoAvailable;

/** flag set to yes when a request is pending to get extra file info. Used to avoid multiple requests in CacheManager*/
@property (nonatomic) BOOL extraInfoRequested;

@property (nonatomic) NSMutableArray * extraInfoDelegates;

/** A convenience place to store the thumbnail icon, in order to avoid requesting it from cloud servers multiple times */
@property (nonatomic) UIImage * thumbnail;



/** Initialize a file object based on a dictionary coming from a cloud request. 
 * This is a one-to-one mapping to avoid the burden of parsing the results of cloud requests.
 * @param dictionary the dictionary built from JSON content of cloud requests
 * @return the initialized file object
 */
-(id) initWithDictionary:(NSDictionary*)dictionary;

/** set info typically returned by a getFileInfo cloud request, like size, creation time, download and thumbnail URLs, ... */
- (void) setExtraInfo:(NSDictionary*)dictionary;

/** return extra info as a dictionary, suitable as a parameter call of setExtraInfo and mostly used for caching */
- (NSDictionary*) extraInfo;

@end

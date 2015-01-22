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


#import "CloudItem.h"

@interface CloudItem ()


@end

@implementation CloudItem

- (id) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self != nil) {
        _identifier = dictionary[@"id"];
        _name = dictionary[@"name"];
        _parentIdentifier = dictionary[@"parentId"];
        NSString * type = dictionary[@"type"];
//        NSLog (@"CloudItem: %@ is %@", self.name, type);
        if (type == nil) {
            _type = CloudTypeDirectory;
        } else if ([type isEqualToString:@"FILE"]) {
            _type = CloudTypeFile;
        } else if ([type isEqualToString:@"PICTURE"]) {
            _type = CloudTypeImage;
        } else if ([type isEqualToString:@"AUDIO"]) {
            _type = CloudTypeAudio;
        } else if ([type isEqualToString:@"VIDEO"]) {
            _type = CloudTypeVideo;
        }
        
    }
    return self;
}

//- (NSString*)thumbnailURL {
//    return [_thumbnailURL stringByReplacingOccurrencesOfString:@"https://cloudapi-test.orange.com" withString:@"http://ext-api.orange.fr"];
//}
//
//- (NSString*)downloadURL {
//    return [_downloadURL stringByReplacingOccurrencesOfString:@"https://cloudapi-test.orange.com" withString:@"http://ext-api.orange.fr"];
//}

- (BOOL) isDirectory {
    return self.type == CloudTypeDirectory;
}

- (BOOL) extraInfoAvailable {
    return self.type == CloudTypeDirectory || self.creationDate != nil;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"name: %@, type:%d, id:%@", self.name, self.type, self.identifier ];
}

static NSString * kSizeKey = @"size";
static NSString * kCreationDateKey = @"creationDate";
static NSString * kThumbUrlKey = @"thumbUrl";
static NSString * kThumbnailUrlKey = @"thumbnailUrl";
static NSString * kPreviewUrlKey = @"previewUrl";
static NSString * kDownloadUrlKey = @"downloadUrl";

- (void) setExtraInfo:(NSDictionary *)dictionary {
    _size = [dictionary[kSizeKey] intValue];
    _creationDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[kCreationDateKey] doubleValue]];

    if (dictionary[kThumbUrlKey] != [NSNull null]) {
        _thumbnailURL = dictionary[kThumbUrlKey];
    } else {
        _thumbnailURL = dictionary[kThumbnailUrlKey];
    }
    if (dictionary[kPreviewUrlKey] != [NSNull null]) {
        _previewURL = dictionary[kPreviewUrlKey];
    } else {
        _previewURL = nil;
    }
    if (dictionary[kDownloadUrlKey] != [NSNull null]) {
        _downloadURL = dictionary[kDownloadUrlKey];
    } else {
        _downloadURL = nil;
    }
    _extraInfoAvailable = YES;
}


- (NSDictionary*)extraInfo {
    if ((self.thumbnailURL == nil || self.previewURL == nil) && (self.type == CloudTypeImage || self.type == CloudTypeVideo)) {
        return nil;
    }
    return @{ @"size" : [NSNumber numberWithInt:self.size],
              @"creationDate" : [NSNumber numberWithDouble:[self.creationDate timeIntervalSince1970]],
              kThumbUrlKey : self.thumbnailURL == nil ? @"nil" : self.thumbnailURL,
              kPreviewUrlKey : self.previewURL == nil ? @"nil" : self.previewURL,
              kDownloadUrlKey : self.downloadURL == nil ? @"nil" : self.downloadURL
              };
}
@end

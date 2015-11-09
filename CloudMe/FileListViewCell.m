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


#import "FileListViewCell.h"
#import "CloudManager.h"

@interface FileListViewCell ()
@property (nonatomic) UILabel * name;
@property (nonatomic) UILabel * size;
@property (nonatomic) UILabel * date;
@property (nonatomic) UIImageView * thumbnail;
@property (nonatomic) UIImageView * indicator;
@end

@implementation FileListViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.thumbnail = [[UIImageView alloc]initWithFrame:CGRectZero];
        self.thumbnail.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        self.thumbnail.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbnail.clipsToBounds = YES;
        self.thumbnail.layer.borderColor = [UIColor whiteColor].CGColor;
        self.thumbnail.layer.borderWidth = 0;
        [self.contentView addSubview:self.thumbnail];

        self.name = [[UILabel alloc] initWithFrame:CGRectZero];
        self.name.font = [UIFont systemFontOfSize:16];
        self.name.textColor = [UIColor blackColor];
        self.name.textAlignment = NSTextAlignmentLeft;
        [self.name setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.name];

        self.size = [[UILabel alloc] initWithFrame:CGRectZero];
        self.size.font = [UIFont systemFontOfSize:12];
        self.size.textColor = [UIColor blackColor];
        self.size.textAlignment = NSTextAlignmentLeft;
        [self.size setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.size];

        self.date = [[UILabel alloc] initWithFrame:CGRectZero];
        self.date.font = [UIFont systemFontOfSize:12];
        self.date.textColor = [UIColor blackColor];
        self.date.textAlignment = NSTextAlignmentRight;
        [self.date setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.date];
        
        self.indicator = [[UIImageView alloc]initWithFrame:CGRectZero];
        self.indicator.image = [UIImage imageNamed:@"Indicator"];
        [self.contentView addSubview:self.indicator];
    }
    return self;
}

- (void) setIconFor:(CloudItem*)cloudItem withData:(NSData*)data {
    UIImage * image = nil;
    if (data != nil) {
        image = [UIImage imageWithData:data];
    }
    if (image == nil) { // if no data or data is corruped, used a default image
        if (cloudItem.type == CloudTypeDirectory) {
            image = [UIImage imageNamed:@"LS_Folder"];
        } else if (cloudItem.type == CloudTypeImage) {
            image = [UIImage imageNamed:@"FileImage"];
        } else if (cloudItem.type == CloudTypeVideo) {
            image = [UIImage imageNamed:@"FileVideo"];
        } else {
            image = [UIImage imageNamed:@"FileDocument"];
        }

    }
    cloudItem.thumbnail = image;
    if (_cloudItem== cloudItem) { // bu sure that cell has not been reused
        self.thumbnail.image = image;
    }
}

- (void) getThumbnail:(CloudItem*)cloudFile {
    if (cloudFile.thumbnail == nil) {
        [self.cloudManager getThumbnail:cloudFile result:^(NSData * data, CloudStatus status) {
            if (status == StatusOK) {
                [self setIconFor:cloudFile withData:data];
            } else {
                //NSLog (@"Cannot load thumbnail, using default icon");
                [self setIconFor:cloudFile withData:nil];
            }
        }];
    } else {
        self.thumbnail.image = cloudFile.thumbnail;
    }
}

- (void) updateCellInfo:(CloudItem *)cloudItem {
    if (_cloudItem != cloudItem) { // the cell has been reused before a network request completed
        return;
    }
    self.name.text = cloudItem.name;
    if (cloudItem.isDirectory == NO) {
        self.indicator.hidden = YES;
        self.date.hidden = NO;
        self.size.hidden = NO;
        self.date.text = [NSDateFormatter localizedStringFromDate:cloudItem.creationDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
        if (cloudItem.size < 1024) {
            self.size.text = [NSString stringWithFormat:@"%d bytes", cloudItem.size];
        } else {
            self.size.text = [NSString stringWithFormat:@"%.1f kb", cloudItem.size/1024.0];
        }
    } else {
        self.indicator.hidden = NO;
        self.date.hidden = YES;
        self.size.hidden = YES;
    }
    [self getThumbnail:cloudItem];

    
}

- (void) setCloudItem:(CloudItem *)cloudItem {
    _cloudItem = cloudItem;
    self.indicator.hidden = YES;
    self.date.hidden = YES;
    self.size.hidden = YES;
    self.thumbnail.image = nil;
    if (cloudItem.extraInfoAvailable == NO) {
        [self.cloudManager fileInfo:cloudItem result:^(CloudItem * cloudFile, CloudStatus status ) {
            if (status == StatusOK) {
                [self updateCellInfo:cloudFile];
            } else {
                [self setIconFor:cloudItem withData:nil];
            }
        }];
    } else {
        [self updateCellInfo:cloudItem];
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = [self bounds];
    float width = rect.size.width;
    float height = rect.size.height;
    float gap = 10;
    float labelWidth = width - height - 2*gap;
    self.thumbnail.frame = CGRectMake(0, 0, height, height);
    self.name.frame = CGRectMake(height+gap, 0, labelWidth, height*0.66);
    self.size.frame = CGRectMake(height+gap, height*0.66, labelWidth*0.33, height*0.33);
    self.date.frame = CGRectMake(height+gap+labelWidth*0.33, height*0.66, labelWidth*0.66, height*0.33);
    self.indicator.frame = CGRectMake(width-24-gap, (height-24)/2, 24, 24);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end

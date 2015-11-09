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


#import <AssetsLibrary/AssetsLibrary.h>
#import "FileListViewController.h"
#import "FileListViewCell.h"
#import "CloudTestViewController.h"
#import "ImageViewController.h"

@interface ProgressView : UIView
@property (nonatomic) double progress;
@property (nonatomic) CGFloat radius;
@property (nonatomic) UIColor * fgColor;
@property (nonatomic) UIColor * bgColor;
@end

@implementation ProgressView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.radius = 30;
        self.bgColor = [UIColor colorWithRed:48/255.0 green:120/255.0 blue:131/255.0 alpha:1];
        self.fgColor = [UIColor colorWithRed:12/255.0 green:193/255.0 blue:220/255.0 alpha:1];
    }
    return self;
}

- (void) setProgress:(double)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    //NSLog (@"****** drawInContext: %g / %g", self.progress, self.radius);
    CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint (context, centerPoint.x, centerPoint.y);
    CGContextAddArc(context, centerPoint.x, centerPoint.y, self.radius, 0, 2*M_PI, 0);
    CGContextClosePath(context); // could be omitted
    CGContextSetFillColorWithColor (context, self.bgColor.CGColor);
    CGContextFillPath(context);
    
    CGContextBeginPath(context);
    //CGContextMoveToPoint (context, centerPoint.x, centerPoint.y);
    CGContextAddArc(context, centerPoint.x, centerPoint.y, self.radius, 0, 2*M_PI, 0);
    CGContextClosePath(context); // could be omitted
    CGContextSetStrokeColorWithColor(context, self.fgColor.CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextStrokePath(context);
    
    if (self.progress > 0) {
        CGContextBeginPath(context);
        CGContextMoveToPoint (context, centerPoint.x, centerPoint.y);
        CGContextAddArc(context, centerPoint.x, centerPoint.y, self.radius, 0-M_PI/2, 2*M_PI*self.progress -M_PI/2, 0);
        CGContextClosePath(context); // could be omitted
        CGContextSetFillColorWithColor(context, self.fgColor.CGColor);
        CGContextFillPath(context);
    }
}

@end
@interface FileListViewController () <UITableViewDataSource, UIAlertViewDelegate, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) CloudManager * cloudManager; // the cloud session to use
@property (nonatomic) CloudItem * cloudItem;


@property (nonatomic) ProgressView * uploadProgressView;

@property (nonatomic) NSArray * entries;
//@property (nonatomic) UIRefreshControl * refreshControl;
@property (nonatomic) UIActivityIndicatorView * indicator;
@property (nonatomic) UIAlertView * createDirAlert;
@property (nonatomic) UIAlertView * deleteDirAlert;
@property (nonatomic) UIAlertView * logoutAlert;
@property (nonatomic) BOOL canReloadContent;
@end


@implementation FileListViewController

- (id) initWithManager:(CloudManager*)manager item:(CloudItem*)cloudItem {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        self.cloudItem = cloudItem;
        self.cloudManager = manager;
        if (cloudItem.identifier) {
            self.title = [self title:cloudItem.identifier];
        }
    }
    return self;
}

- (NSString*)title:(NSString*)base64String {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    // return last component of string
    NSArray * components = [decodedString componentsSeparatedByString:@"/"];
    NSLog(@"title: %@", components);
    NSUInteger count = components.count;
    while (count > 0) {
        NSString * string = components[count-1];
        if (string.length > 0) {
            break;
        }
        count--;
    }
    return components[count > 0 ? count-1 : 0];
}

- (void) viewDidLoad {
//    float w = self.view.frame.size.width;
//    float h = self.view.frame.size.height;

    // first create the toolbar
    self.navigationController.toolbarHidden = NO;
    
    UIImage *image;
    
    image = [[UIImage imageNamed:@"LS_Upload"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem * upload = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(uploadPhoto:)];
    
    image = [[UIImage imageNamed:@"LS_CreateDir"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem * createDir = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(createDir:)];
    
    image = [[UIImage imageNamed:@"LS_DeleteDir"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem * deleteDir = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(deleteDir:)];
    
    image = [[UIImage imageNamed:@"LS_More"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem * more = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(more:)];

    
    
    
    [self setToolbarItems: @[
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             upload,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             createDir,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             deleteDir,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             more,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             ]
                 animated:YES];
    
    

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor colorWithWhite:0.8 alpha:1];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.rowHeight = 66;
    self.tableView.scrollsToTop = YES;

    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.indicator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:self.indicator];
//
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
	[self.refreshControl addTarget:self action:@selector(loadContent) forControlEvents:UIControlEventValueChanged];

    self.canReloadContent = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.entries == nil) {
        [self loadContent];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = -self.tableView.contentOffset.y;
    if (offset > (self.tableView.rowHeight*1.5) && self.canReloadContent == YES) {
        self.canReloadContent = NO;
        [self loadContent];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.canReloadContent = YES;
}


- (void) loadContent {
    [self.indicator startAnimating];
    [self.cloudManager listFolder:self.cloudItem result:^(NSArray * array, CloudStatus status) {
        if (status == StatusOK) {
            if (self.refreshControl.isRefreshing) {
                [self.refreshControl endRefreshing];
            }
            self.entries = array;
            [self.tableView reloadData];
            [self.indicator stopAnimating];
        } else {
            if (self.refreshControl.isRefreshing) {
                [self.refreshControl endRefreshing];
            }
            self.entries = nil;
            [self.tableView reloadData];
            [self.indicator stopAnimating];
        }
    }];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.entries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellID = @"FileListViewCell";
	
	FileListViewCell * cell = (FileListViewCell *)[tableView dequeueReusableCellWithIdentifier:kCellID];
    
	if (cell == nil) {
		cell = [[FileListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
	}
    cell.cloudManager = self.cloudManager;
    cell.cloudItem = (CloudItem*) self.entries[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CloudItem * item = (CloudItem*) self.entries[indexPath.row];
    if (item.isDirectory) {
        [self.navigationController pushViewController:[[FileListViewController alloc] initWithManager:self.cloudManager item:item] animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [self.navigationController pushViewController:[[ImageViewController alloc] initWithManager:self.cloudManager item:item] animated:YES];
    }
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - toolbar callbacks

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView == self.createDirAlert) {
        if (buttonIndex == 1) {
            NSString * name = [alertView textFieldAtIndex:0].text;
            [self.cloudManager createFolder:name parent:self.cloudItem result:^(CloudItem * item, CloudStatus status) {
                if (status == StatusOK) {
                    self.entries = nil;
                    [self loadContent];
                } else {
                    NSLog (@"***** Cannot create directory %@", name);
                }
            }];
        }
    } else if (alertView == self.deleteDirAlert) {
        if (buttonIndex == 1) {
            [self.cloudManager deleteFolder:self.cloudItem result:^(CloudStatus status){
                if (status == StatusOK) {
                    NSArray * viewControllers = self.navigationController.viewControllers;
                    NSInteger index = [viewControllers indexOfObject:self];
                    if (index != NSNotFound && index > 0) {
                        UIViewController * previousController = viewControllers[index-1];
                        if ([previousController isKindOfClass:[FileListViewController class]]) {
                            [(FileListViewController*)previousController loadContent];
                        } else {
                            [self loadContent];
                        }
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    NSLog (@"***** Cannot delete directory %@", self.title);
                }
            }];
        }
    } else if (alertView == self.logoutAlert) {
        if (buttonIndex == 1) {
            CloudTestViewController * rootController = (CloudTestViewController*)self.navigationController;
            [rootController logout];
        }
    }
}

-(void) createDir:(id)sender {
    self.createDirAlert = [[UIAlertView alloc] initWithTitle:@"Enter new name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
    [self.createDirAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    // Change keyboard type
    [[self.createDirAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.createDirAlert show];
}

-(void) deleteDir:(id)sender {
    self.deleteDirAlert = [[UIAlertView alloc] initWithTitle:@"Are you sure to delete folder and all its files?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [self.deleteDirAlert show];
}

- (void) uploadPhoto:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}


- (void) logout {
    self.logoutAlert = [[UIAlertView alloc] initWithTitle:@"Log Out" message:@"You are about to log out from Orange Cloud " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes, log me out", nil];
    [self.logoutAlert show];
}

- (void) showAlertWithTitle:(NSString*)title message:(NSString*)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
}
- (void) showInfo {
    // an example of how to query for available cloud space

    [self.cloudManager getFreeSpace:^(long size, CloudStatus status) {
        if (status == StatusOK) {
            NSString * message = [NSString stringWithFormat:@"You have %d kB of free space", (int)(size/1024)];
            [self showAlertWithTitle:@"Free Space" message:message];
        } else {
            NSString * message = [NSString stringWithFormat:@"Error while getting free space: %@", [CloudManager statusString:status]];
            [self showAlertWithTitle:@"Free Space" message:message];
        }
    }];
    [NSThread sleepForTimeInterval:0.1];

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { //logout
        [self logout];
    } else if (buttonIndex == 1) { // info
        [self showInfo];
    } else { // cancel : do nothing
        
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet{
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            NSString * text = [button titleForState:UIControlStateNormal];
            if ([text isEqualToString:NSLocalizedString(@"MORE_LOGOUT", nil)] == NO) {
                [button setTitleColor:self.view.tintColor forState:UIControlStateNormal];
                [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
            }
        }
    }
}

- (void) more:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Logout"
                                                    otherButtonTitles:@"Info", nil];
    [actionSheet showInView:[self.view window]];
}


- (void) showProgressIndicator {
    if (self.uploadProgressView == nil) {
        self.uploadProgressView = [[ProgressView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:self.uploadProgressView];
    } else {
        self.uploadProgressView.hidden = NO;
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL * assetUrl = info[UIImagePickerControllerReferenceURL];
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:assetUrl
                   resultBlock:^(ALAsset * asset) {
                       ALAssetRepresentation * defaultRepresentation = [asset defaultRepresentation];
                       Byte * buffer = (Byte*) malloc ((int)defaultRepresentation.size);
                       NSUInteger buffered = [defaultRepresentation getBytes:buffer fromOffset:0.0 length:(int)defaultRepresentation.size error:nil];
                       NSData * data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                       NSString * filename = defaultRepresentation.filename;
                       [self showProgressIndicator];
                       
                       [self.cloudManager uploadData:data filename:filename folderID:self.cloudItem.identifier progress:^(float progress) {
                           self.uploadProgressView.progress = progress;
                       } result:^(CloudItem * item, CloudStatus status) {
                           if (status == StatusOK) {
                               self.entries = nil;
                               self.uploadProgressView.hidden = YES;
                               [self loadContent];
                           } else {
                               self.uploadProgressView.hidden = YES;
                               NSString * message = [NSString stringWithFormat:@"Problem uploading image: %@", [CloudManager statusString:status]];
                               UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Uploading failed" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                               [alert show];
                               
                               NSLog (@"Probleme uploading image: %@", [CloudManager statusString:status]);
                           }
                       }];
                   }
     
                  failureBlock:^(NSError* error) {
                      NSLog(@"Cannot retrieve image : %@", [error localizedDescription]);
                  }
     ];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}




@end

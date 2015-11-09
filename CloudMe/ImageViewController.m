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


#import "ImageViewController.h"
#import "CloudManager.h"
#import "FileListViewController.h"

@interface ImageViewController ()
@property (nonatomic) UIImageView * imageView;
@property (nonatomic) UIActivityIndicatorView * indicator;
@property (nonatomic) CloudManager * cloudManager;
@property (nonatomic) CloudItem * cloudItem;
@property (nonatomic) UIAlertView * deleteFileAlert;
@end

@implementation ImageViewController

- (id) initWithManager:(CloudManager*)cloudManager item:(CloudItem*)cloudItem {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.cloudManager = cloudManager;
        self.cloudItem = cloudItem;
        self.view.hidden = NO;
        self.title = cloudItem.name;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    UIImage * image = [[UIImage imageNamed:@"LS_Delete"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem * deleteFile = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(deleteFile:)];
    [self setToolbarItems: @[
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             deleteFile,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             ]
                 animated:YES];

    // Do any additional setup after loading the view.
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];

    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.indicator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:self.indicator];
    [self.indicator startAnimating];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.cloudManager getFileContent:self.cloudItem result:^(NSData * data, CloudStatus status) {
        if (status == StatusOK) {
            [self.indicator stopAnimating];
            self.imageView.image = [UIImage imageWithData:data];
        } else {
            [self.indicator stopAnimating];
            NSLog (@"Error during file content retrieval: %@", [CloudManager statusString:status]);
        }
    }];

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView == self.deleteFileAlert) {
        if (buttonIndex == 1) {
            [self.cloudManager deleteFile:self.cloudItem result:^(CloudStatus status){
                if (status == StatusOK) {
                    NSArray * viewControllers = self.navigationController.viewControllers;
                    NSInteger index = [viewControllers indexOfObject:self];
                    if (index != NSNotFound && index > 0) {
                        UIViewController * previousController = viewControllers[index-1];
                        if ([previousController isKindOfClass:[FileListViewController class]]) {
                        [(FileListViewController*)previousController loadContent];
                        }
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    NSLog (@"***** Cannot delete file %@", self.title);
                }
            }];
        }
    }
}

-(void) deleteFile:(id)sender {
    self.deleteFileAlert = [[UIAlertView alloc] initWithTitle:@"Are you sure to delete this image?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [self.deleteFileAlert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//- (void) setImageData:(NSData*)data {
//    self.imageView.image = [UIImage imageWithData:data];
//}

@end

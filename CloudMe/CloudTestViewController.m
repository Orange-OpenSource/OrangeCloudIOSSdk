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


#import "CloudTestViewController.h"
#import "FileListViewController.h"

@interface CloudTestViewController ()


@end

@implementation CloudTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    // Create the connection object that will make first user authentication and then open a cloud session
//#warning - please replace with your own credentials
    
//    self.cloudManager = [[CloudManager alloc] initWithAppKey:@"84s1QUs16ZKz0MKMppjxANczFQTfzpwe"
//                                                   appSecret:@"yrXb1IA1hQqaDHa0"
//                                                 redirectURI:@"cloudmefull://callback"];

    self.cloudManager = [[CloudManager alloc] initWithAppKey:@"YWrByWAIwwdQuN7i4DrQnD0rlEI0LNpw"
                                                   appSecret:@"AidRAEmS0SiUGQaR"
                                                 redirectURI:@"http://www.spikitup.macflymotion.fr/Service/SpikiServices.php/OrangeConnect"];
    
    
    
    [self.cloudManager setUseWebView:TRUE];
    [self.cloudManager setForceLogin:TRUE];
}

/** This method is typically called from the app delegate when the app becomes active or whenever a connection must be re-established (i.e. after a logout)
 * It will first check that user is authenticated using the right mechanism (refresh_toke, web view or external browser), then open a cloud session.
 * Normally, once the session is open, any cloud method can be used.
 */
- (void) connect {
    if (self.cloudManager.isConnected == NO) {
        [self.cloudManager openSessionFrom:self result:^(CloudStatus status){ // everything is Ok, so we can list the root folder and display its content using our dedicated FileListViewController
            if (status == StatusOK) {
                [self.cloudManager rootFolder:^(CloudItem * cloudItem, CloudStatus status) { // this cloudItem represent the root folder your application has access to
                    if (status == StatusOK) {
                        [self setViewControllers:@[[[FileListViewController alloc] initWithManager:self.cloudManager item:cloudItem]]];
                    } else {
                        // Note that this should happen only upon unexpected issues like network errors, but you may probably want to display a popup warning
                        NSLog (@"Error while getting root folder: %@", [CloudManager statusString:status]);
                    }
                }];
            } else {
                if ([self.cloudManager canShowAlertFromStatus:status] == NO) { // if it is an error reqiuring a very specifc Orange Cloud action
                    if (status == ForbiddenAccess) {
                        [self logout]; // try to login with another credentials
                    } else {
                        NSString * message = [NSString stringWithFormat:@"A problem occured while connecting to Orange Cloud (%@). Please try again later.", [CloudManager statusString:status]];
                        [[[UIAlertView alloc] initWithTitle:@"Connection Issue" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    }
                }
            }
        }];
    }
}


/** This method is used to logout out the current user. It can be called from anywhere in teh view hierarchy, so we need to reset the stack of viewControllers.
 * Once user is discoonected and controllers cleand up, teh authent proces is automatically brought up
 */
- (void) logout {
    [self.cloudManager logout]; // close current session
    [self setViewControllers:@[]]; // remove current controllers
    [self connect]; // display back the authent page
}

@end

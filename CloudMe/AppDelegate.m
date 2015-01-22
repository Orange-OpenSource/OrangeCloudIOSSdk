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

#import "AppDelegate.h"
#import "CloudTestViewController.h"
#import "OIDCManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.tintColor = [UIColor colorWithRed:48/255.0 green:120/255.0 blue:131/255.0 alpha:1];

    // Here we instantiate our custom view controller taht will connect to Orange Cloud
    self.window.rootViewController = [[CloudTestViewController alloc]initWithNibName:nil bundle:nil];

    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // when the authent process is done extrenally using Safari mobile, the application is called back using the url that starts with the app custom scheme.
    // We need to give this url to the OIDC manager in order to extract the authorization code and then to continue the connection process
    CloudTestViewController * controller = (CloudTestViewController*)self.window.rootViewController;
    if ([controller.cloudSession handleOpenURL:url]) {
        return YES;
    }
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    CloudTestViewController * controller = (CloudTestViewController*)self.window.rootViewController;
    [controller connect];
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application { }


@end

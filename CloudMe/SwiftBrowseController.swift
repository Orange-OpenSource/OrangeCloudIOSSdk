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

import Foundation
import UIKit

/**
 This class is the Swift equivalent of CloudTestViewController and can be used as another example of using the SDK in Swift.
 */
class SwiftBrowseController : UINavigationController {
    
    /** the cloud session object used to access Orange Cloud */
    var cloudManager : CloudManager?

    override func viewDidLoad() {
        super.viewDidLoad ()
        view.backgroundColor = UIColor.whiteColor()

        // Create the cloud manager object that will make first user authentication and then open a cloud connection
        // Warning - please replace with your own credentials
        cloudManager = CloudManager (appKey: "your_app_key", appSecret: "your_app_secret", redirectURI: "your_app_callback_URI")

        cloudManager?.setUseWebView(true) // force using a webview instead of safari
        cloudManager?.setForceLogin(false) // will ask user to enter its login each time (i.e. no token caching)
        cloudManager?.addScope(.FullRead) // require to use this new scope
    }

    /** Convenient method for AppDelegate to ask the cloud manager to connect to the cloud.
     * This method is typically called from the app delegate when the app becomes active or whenever a connection must be re-established (i.e. after a logout)
     * It will first check that user is authenticated using the right mechanism (refresh_token, web view or external browser), then open a cloud session.
     * Normally, once the session is open, any cloud method can be used.
     */

    func connect () {
        if let cloudManager = cloudManager where cloudManager.isConnected == false {
            cloudManager.openSessionFrom(self) { status in
                if status == StatusOK {
                    cloudManager.rootFolder { cloudItem, status in
                        if status == StatusOK {
                            self.setViewControllers([FileListViewController (manager: cloudManager, item: cloudItem)], animated: true)
                        } else {
                            print ("Error while getting root folder: \(CloudManager.statusString (status))")
                        }
                    }
                } else {
                    if cloudManager.canShowAlertFromStatus (status) == false { // if it is an error requiering a very specifc Orange Cloud action
                        if status == ForbiddenAccess {
                            self.logout () // try to login with another credentials
                        } else {
                            let message = "A problem occured while connecting to Orange Cloud (\(CloudManager.statusString(status))). Please try again later."
                            UIAlertView (title: "Connection issue", message: message, delegate: nil, cancelButtonTitle: "OK").show ()
                        }
                    }
                }
            }
        }
    }
    
    /** convenient method (for AppDelegate) to inform the cloud manager it needs to logout the current user */
    func logout () {
        cloudManager?.logout() // close current session
        setViewControllers ([], animated:true) // remove current controllers
        connect() // display back the authent page

    }

}
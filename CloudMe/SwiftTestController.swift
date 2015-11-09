//
//  SwiftTestController.swift
//  OrangeCloudSDK
//
//  Created by renaud on 04/11/2015.
//  Copyright © 2015 renaud. All rights reserved.
//

import Foundation
import UIKit

class SwiftTestController : UINavigationController {
    
    /** the cloud session object used to access Orange Cloud */
    var cloudManager : CloudManager?

    override func viewDidLoad() {
        super.viewDidLoad ()
        view.backgroundColor = UIColor.whiteColor()
        // Create the cloud manager object that will make first user authentication and then open a cloud connection
        cloudManager = CloudManager (appKey: "84s1QUs16ZKz0MKMppjxANczFQTfzpwe", appSecret: "yrXb1IA1hQqaDHa0", redirectURI: "cloudmefull://callback")
        cloudManager?.setUseWebView(true)
        cloudManager?.setForceLogin(true)
        cloudManager?.addScope(.FullRead)
    }

    /** Convenient method for AppDelegate to tell the cloud manager to connect to the cloud.
     * This method is typically called from the app delegate when the app becomes active or whenever a connection must be re-established (i.e. after a logout)
     * It will first check that user is authenticated using the right mechanism (refresh_toke, web view or external browser), then open a cloud session.
     * Normally, once the session is open, any cloud method can be used.
     */

    func connect () {
        if let cloudManager = cloudManager where cloudManager.isConnected == false {
            print ("let's open a session !")
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
    
    /** convenient method for AppDelegate to inform the cloud manager it needs to logout the current user */
    func logout () {
        cloudManager?.logout() // close current session
        setViewControllers ([], animated:true) // remove current controllers
        connect() // display back the authent page

    }

}
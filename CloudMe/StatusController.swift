/*
 Copyright (C) 2016 Orange
 
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

class TestContext : NSObject {
    // some constants for the tests
    let folderName = "__TestFolder__"
    let folderNameAlt = "__TestFolder_2__"
    let imageNameAlt = "image_2.png"
    let imageNameCopy = "image_2_copy.png"
    
    // Warning - please replace with your own credentials
    var manager = CloudManager (appKey: "your_app_key", appSecret: "your_app_secret", redirectURI: "your_app_callback_URI")

    var rootFolder : CloudItem? // the place where the app is allowed to write data (ususally a sub directory of the user cloud tree)
    var testFolder : CloudItem? // here we store a reference to a dir we create for the testing suite
    var testFile : CloudItem? // here we store a reference to a dir we create for the testing suite
    
    override init () {
        manager.setUseWebView (true)
    }
}

class StatusController : UIViewController {
    
    var testContext : TestContext = TestContext ()
    
    private let testConfig : [TestUnit] = [
        ("connect" , testConnection),
        ("get root folder" , testRootFolder),
        ("create folder" , createFolder),
        ("upload file" , uploadFile),
        ("list folder" , listFolder),
        ("get direct file content" , getFileContent),
        ("rename directory", renameDirectory),
        ("list folder" , listFolder),
        ("copy file", copyFile),
        ("rename file", renameFile),
        ("get file information" , getFileInfo),
        ("download file" , downloadFile),
        ("download thumbnail" , getThumbnail),
        ("get file information" , getFileInfo),
        ("delete file" , deleteFile),
        ("delete folder" , deleteFolder),
        ]
    
    private let label = UILabel ()

    private var testItems = [TestItem]()
    private var currentItem = 0
    
    private let scrollview = UIScrollView ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        scrollview.frame = CGRect (x: 0, y: 9, width: view.frame.width, height: view.frame.height-44)
        scrollview.alwaysBounceVertical = true
        view.addSubview(scrollview)
        

        
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect (x: 0, y: view.frame.height-44, width: view.frame.width, height: 44)
        view.addSubview(blurView)

        let blurEffect2 = UIBlurEffect(style: .Light)
        let blurView2 = UIVisualEffectView(effect: blurEffect2)
        blurView2.frame = CGRect (x: 0, y: 0, width: view.frame.width, height: 20)
        view.addSubview(blurView2)

        let width = view.frame.size.width
        var y = CGFloat (20)
        let itemHeight = CGFloat (32)

        label.frame = CGRectMake(0, y, width, 32)
        label.textColor = UIColor.blackColor()
        label.font = titleFont
        label.textAlignment = .Center
        label.text = "Cloud Status"
        scrollview.addSubview(label)
        y += itemHeight
        
        
        for (name, function) in testConfig {
            let item = TestItem (frame: CGRectMake(0, y, view.frame.size.width, itemHeight))
            item.label.text = name
            item.state = .Pending
            item.closure = function
            scrollview.addSubview(item)
            testItems.append(item)
            y += itemHeight
        }
        
        scrollview.contentSize = CGSize (width: width, height: y+10)

        let login = UILabel (frame: CGRectMake(10, (44-itemHeight)/2, width/3, itemHeight))
        login.textColor = UIColor(red: 1, green: 0.6, blue: 0, alpha: 1)
        login.font = buttonFont
        login.textAlignment = .Left
        login.text = "Reset login"
        login.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (logout)))
        login.userInteractionEnabled = true
        blurView.contentView.addSubview(login)
        
        //y += 32

        //y = view.frame.size.height - (32 + 8)
        let testAgain = UILabel (frame: CGRectMake(width/3, (44-itemHeight)/2, width/3, itemHeight))
        testAgain.textColor = UIColor(red: 1, green: 0.6, blue: 0, alpha: 1)
        testAgain.font = buttonFont
        testAgain.textAlignment = .Center
        testAgain.text = "Test again"
        testAgain.userInteractionEnabled = true
        testAgain.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(connect)))
        
        blurView.contentView.addSubview(testAgain)
        
        let clear = UIImageView (frame: CGRectMake(width - itemHeight, (44-itemHeight)/2, itemHeight, itemHeight))
        clear.image = UIImage (named: "trash")
        clear.userInteractionEnabled = true
        clear.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearStats)))
        
        blurView.contentView.addSubview(clear)
        
    }
    
    func ensureItemIsDisplayed (item : TestItem) {
        scrollview.scrollRectToVisible(item.frame, animated: true)
    }
    
    func performNextTest () {
        currentItem += 1
        if currentItem < testItems.count {
            let item = testItems[currentItem]
            ensureItemIsDisplayed(item)
            item.state = .InProgress
            let startingDate = NSDate ()
            if let selector = item.closure {
                selector (context: testContext) { state in
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        item.state = state
                        if item.duration == 0 {
                            let duration = NSDate().timeIntervalSinceDate(startingDate)
                            stats.addStat(duration, forTest: item.name)
                            item.duration = duration
                        }
                    }
                    self.performNextTest()
                }
            }
        }
    }
    
    func performTests () {
        currentItem = -1
        performNextTest ()
        
    }
    
    func clearStats () {
        stats.clear ()
    }
    
    func connect () {
        print ("connect")
        scrollview.setContentOffset(CGPoint (x:0, y:0), animated: true)
        for item in testItems {
            item.state  = .Pending
            item.duration = 0
            item.durationLabel.text = ""
        }
        testItems[0].state = .InProgress
        let startingDate = NSDate ()
        if testContext.manager.isConnected == false || true {
            testContext.manager.addScope([.Cloud, .FullRead, .OpenID, .OfflineAccess])
            testContext.manager.openSessionFrom(self) { status in
                if status == StatusOK {
                    let duration = NSDate().timeIntervalSinceDate(startingDate)
                    stats.addStat(duration, forTest: self.testItems[0].name)
                    self.testItems[0].duration = duration
                    self.performTests ()
                } else {
                    print ("error connecting to cloud")
                    if self.testContext.manager.canShowAlertFromStatus(status) == false {
                        if status == StatusOK {
                            self.logout ()
                        } else {
                            let error = CloudManager.statusString(status)
                            let body = "A problem occured while connecting to Orange Cloud (\(error)). Please try again later."
                            UIAlertView (title: "Connection Issue", message: body, delegate: nil, cancelButtonTitle: "OK").show()
                        }
                    }
                }
            }
        } else {
            self.performTests ()
        }
    }
    
    func logout () {
        print ("logout")
        testContext.manager.logout(); // close current session
        connect(); // display back the authent page
        
    }
}
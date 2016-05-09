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

typealias TestResult = (value : Double, count : Int)

class TestStats {
    let kStatsKey = "StatsKey"
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var stats : [String : [Double]]
    
    init () {
        if let dict = defaults.dictionaryForKey(kStatsKey) as? [String : [Double]] {
            stats = dict
        } else {
            stats =  [String : [Double]] ()
        }
    }
    
    func addStat(value : Double, forTest testName : String) {
        if let array = stats[testName] {
            stats[testName] = [ array[0] + value, array[1] + 1]
        } else {
            stats[testName] = [value, 1]
        }
        defaults.setObject(stats, forKey: kStatsKey)
        defaults.synchronize()
    }
    
    func average (test: String) -> Double {
        if let array = stats[test] {
            return array[0] / array[1]
        } else {
            return 0
        }
    }
    func clear () {
        stats = [String : [Double]] ()
        defaults.setObject(stats, forKey: kStatsKey)
        defaults.synchronize()
    }
}

var stats = TestStats ()

enum TestState {
    case Pending, // not passed yet => gray
    InProgress, // being passed => bikining gray - orange
    Failed, // red
    Partial, // orange
    Succeeded // green
}

typealias TestFunc = (context : TestContext, result : (TestState)->Void) -> Void
typealias TestUnit = (name:String, closure : TestFunc)


func testConnection (context : TestContext, result : (TestState)->Void) {
    print ("testConnection")
    result (context.manager.isConnected ? .Succeeded : .Failed)
}

func testRootFolder (context : TestContext, result : (TestState)->Void) {
    context.manager.rootFolder(){ cloudItem, status in
        if status == StatusOK {
            context.rootFolder = cloudItem
        }
        result (status == StatusOK ? .Succeeded : .Failed)
    }
}

func createFolder (context : TestContext, result : (TestState)->Void) {
    context.testFolder = nil
    if let folder = context.rootFolder {
        context.manager.createFolder(context.folderName, parent: folder) { item, status in
            if status == StatusOK {
                context.testFolder = item
                result (.Succeeded)
            } else {
                context.manager.listFolder(folder) { items, status in
                    if status == StatusOK {
                        for item in items as! [CloudItem] {
                            if item.name == context.folderName {
                                context.testFolder = item
                                result (.Succeeded)
                                return
                            }
                        }
                    }
                    result (.Failed)
                }
            }
        }
    }
}


func uploadFile (context : TestContext, result : (TestState)->Void) {
    let bundle = NSBundle.mainBundle()
    if let folder = context.testFolder,
        path = bundle.pathForResource("image", ofType: "jpg"),
        data = NSData (contentsOfFile: path) {
        context.manager.uploadData(data, filename: "image.jpg", folderID: folder.identifier, progress: nil) { item, status in //) { cloudItem, status in
            if status == StatusOK {
                context.testFile = item
                result (.Succeeded)
            } else {
                result (.Failed)
            }
        }
    } else {
        result (.Failed)
    }
}

func listFolder (context : TestContext, result : (TestState)->Void) {
    if let folder = context.testFolder {
        context.manager.listFolder(folder, restrictedMode: false, showThumbnails: true, filter: .All, flat: false, tree: false, limit: 0, offset: 0) { items, status in
            if let items = items as? [CloudItem] where items.count > 0 {
                context.testFile = items[0]
            }
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func getFileInfo (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile {
        context.manager.fileInfo(file) { item, status in
            if status == StatusOK {
                context.testFile = item
                result (.Succeeded)
            } else {
                result (.Failed)
            }
        }
    } else {
        print ("[TEST] no file to get info from")
        result (.Failed)
    }
}

func getFileContent (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile {
        context.manager.getFileContent(file) { data, status in
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func downloadFile (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile,
        token = context.manager.token,
        downloadURL = file.downloadURL,
        url = NSURL (string: downloadURL + "?token=" + token) {
        print ("trying to get file with url: \(url.absoluteString)")
        print ("thumbnail url: \(file.thumbnailURL)?token=" + token)
        NSOperationQueue ().addOperationWithBlock() {
            let data = NSData (contentsOfURL: url)
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                result (data != nil ? .Succeeded : .Failed)
            }
        }
    } else {
        result (.Failed)
    }
}

func getThumbnail (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile {
        context.manager.getThumbnail(file) { data, status in
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func renameFile (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile {
        context.manager.rename(file, newName:context.imageNameAlt) { item, status in
            if let item = item {
                context.testFile = item
            }
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func renameDirectory (context : TestContext, result : (TestState)->Void) {
    if let folder = context.testFolder {
        context.manager.rename(folder, newName:context.folderNameAlt) { item, status in
            if let item = item {
                context.testFolder = item
            }
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func copyFile (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile, folder = context.testFolder {
        context.manager.copy(file, destination: folder) { item, status in
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func deleteFile (context : TestContext, result : (TestState)->Void) {
    if let file = context.testFile {
        context.manager.deleteFile(file) { status in
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func deleteFolder (context : TestContext, result : (TestState)->Void) {
    if let folder = context.testFolder {
        context.manager.deleteFolder(folder) { status in
            result (status == StatusOK ? .Succeeded : .Failed)
        }
    } else {
        result (.Failed)
    }
}

func blindTest (context : TestContext, result : (TestState)->Void) {
    print ("blindTest")
    result (.Failed)
}


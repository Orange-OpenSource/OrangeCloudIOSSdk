# Orange Cloud iOS SDK

Welcome to the CloudMe project for iPhone, designed to help you test Orange Cloud APIs.
This is a preliminary sample code: we are currently developing a fully featured SDK.

Please start with: https://www.orangepartner.com/content/cloud-fr-api
to get an overview of the Cloud service for Orange customers in France
and the scope and capabilities of the related Cloud APIs.
From there, you can register your app and get your own credentials
and paste them into the relevant section: #warning in ViewController.m.

We'd love to hear your feedback.

Notes on Xcode project:
----------
This project is compatible with both iOS 8 and iOS 9 versions.

The Cloud API can be accessed using conventional HTTP calls, however this Objective-C project
provides a set of classes that remove the burden of making your own calls.
These classes are used to implement a simple navigation application to illustrate their usage.

Swift compatibility:
-----------
You can use this SDK using either Objective-C or Swift. An example of
Swift usage is provided in SwiftTestController.swift. You will just
need to insert
``` objective-c
#import "CloudManager.h"
```
in your  bridging header

CloudTestViewController:
---------------
A UINavigationController implements a simple navigation through the Cloud content.
This is where you set your application credentials (client id, secret and redirect url).
This is also the place where you trigger user authentication and then, through a callback,
start using the cloud.


CloudManager:
-------------
This class gives you access to the Cloud functionalities : user authentication, list of available files,
detailed info on a file, upload and download of content.
You  typically start by creating a CloudSession instance with your appp credentials and open it using your main view controller.
Once the session is open, you can access the user Cloud data.
Due to the asynchronous nature inherent to HTTP calls, this API uses blocks.
You should be never blocked by a call but remember that all UI modifications
must be done back to the main loop.

CloudItem:
----------
This is a helper class representing a cloud file very often used as parameter
or return value in many of the CloudManager methods.
It is just a place holder for all information available from the Cloud.

FileListViewController, FileListViewCell, ImageViewController:
--------------------------------------------------------------
This set of simple classes is an example of how to use the CloudSession to browse the user Cloud.
You can refer to the source code if you have any questions about the way to use it.


(c) 2014 Orange - All rights reserved.

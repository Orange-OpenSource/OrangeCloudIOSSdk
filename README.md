# Orange Cloud iOS SDK 2.0
Welcome to the CloudMe project for iPhone, designed to help you test Orange Cloud APIs.
This is a preliminary sample code: we are currently developing a fully featured SDK.

Please start at [Orange Partner site](https://www.orangepartner.com/content/cloud-fr-api)
to get an overview of the Cloud service for Orange customers in France
and the scope and capabilities of the related Cloud APIs.
From there, you can register your app and get your own credentials
and paste them into the relevant section: #warning in ViewController.m.

We'd love to hear your feedback, thanks for your time!

Legal notice: 
--------------
ORANGE OFFERS NO WARRANTY EITHER EXPRESS OR IMPLIED INCLUDING THOSE OF MERCHANTABILITY,
NONINFRINGEMENT OF THIRD-PARTY INTELLECTUAL PROPERTY OR FITNESS FOR A PARTICULAR PURPOSE.
ORANGE SHALL NOT BE LIABLE FOR ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION,
DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
OR OTHER LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THE SAMPLE CODE,
EVEN IF ORANGE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

What's new in 2.0 
-----------
- remove unnecessary session token management
- improve Swift compatibility (nullable, enum, single closure)
- add new verbs support (move, rename and copy)
- add support for enhanced folder listing (pagination, tree, file type selection, ...)
- improve debugging features (curl like calls syntax)
- add new swift example as a comprehensive testing suite

About this Xcode project:
----------
The Orange cloud API can obviously be accessed using conventional HTTP calls, however it is often easier to use a wrapper in a high-level programing language to speed up integration in 
your own project or to quickly check that the functonaly behind the API suits your need. This is exactly what this project does: it
provides a SDK, a set of Objective-C classes that encapsulates these calls to remove the burden of making your own calls and dealing with low-level HTTP calls. 
It also provides a couple of examples that shows how to use this SDK for the most common operations.

This project is open-source to give your alll freedom to reuse and modify and integrate any part of this code that can help you integrate the Orange cloud in your project.

### Organisation of the project
The source files of the SDK itself are located inside the "Cloud API" group and can be easily extracted for you own needs. The main class is located in **CloudManager** and is
documented inline, so hovering a method with teh alt key should sohw documentation as usual.

The two examples are located in separate groups, respectively **Status** and **Navigation**. Each group contains a bunch of classes that show the use of the SDK to implement a simple navigation application across the user's cloud directory.

### Before starting using this project
In order to be able to use this project, you must first
create your own application key, secret and callback url on
[Orange Partner](https://www.orangepartner.com) and set them in one the the main controllers provided as SDK use example, like
BrowseController or SwiftTestController (see below)

### Swift compatibility: 
Despite the core of the SDK is written in Objective-C, it has been designed and decorated in order to provide maximum compatibility with Swift so you can use transparently 
the SDK in any Swift project by adding: 

```Objective-c
#import "CloudManager.h"
```
in your bridging header (usually 'name-of-your-project-Bridging-Header.h)

An example of Swift usage is provided in the file **StatusController.swift**. You will just need to insert

The SDK has been rewritten in order to take advantage of Swift syntaxic shortcuts, in particular the closure as the last parameter,
allowing to write code like : 

```Swift
cloudManager.rootFolder { cloudItem, status in
    if status == StatusOK {
        self.setViewControllers([FileListViewController (manager: cloudManager, item: cloudItem)], animated: true)
    } else {
        print ("Error while getting root folder: \(CloudManager.statusString (status))")
    }
}
```

### Debug
One of the main issues when debugging WEB calls embeded in a SDK is to be able to extact these calls to test them unitarily. 
In order to help you, a define can be set to true (TRACE_API_CALL in CloudConfig.h) and all API calls will be printed on the Xcode console as a curl command.
You can then freely test it on the terminal or send it to the [Cloud API support team](https://developer.orange.com/support/contact-us).

You can also set a define to track bandwitdh usage if you suspect bottlenecks. Finally you can also request to force API calls to be sequantial if you have special needs in your application.

Content of the SDK
----------

You have acess to the user's cloud through two classes. the first one is the entry point to all function and the second one is a wrapper to a cloud file or folder information. 

### CloudManager:
This is the main class of the SDK and it gives you full access to the Cloud functionalities : user authentication, list of available files,
detailed info on a file, upload and download of content.
You  typically start by creating a CloudManager instance with your appp credentials and open it using your main view controller.
Once the session is open, you can access the user cloud data.

Due to the asynchronous nature inherent to HTTP calls, this API makes intensive usage of blocks / closures.
Therefore, you should be never blocked by a call in your main thread but remember that all UI modifications must be done back to the main loop.

### CloudItem:
This is a helper class representing a cloud file very often used as parameter
or return value in many of the CloudManager methods. It is just a place holder for all information available from the Cloud.

You will probably have your own data strcuture, so this is probably the place to modify first for a best project integration.

### authentication
The authentication step is automatically managed by the SDK, through the `connect` methof of `CloudManager`. However, there are a few tips to know, 
as this step can be done inside a webview integrated inside the application or using an external browser (namely Safari).

If you decide to use a WebView, you need to provide a valid, already presented, view controller that will used as the anchor to display the webview. 
You also need to setup the CloudManager property `setUseWebView`to YES, before calling connect.

On the other hand, if you prefer to use an external authentication process, your application will need to meet some requirements mandatory for the OpenID Connect process : 

+ Safari must be invoked with the right URL: this is automatically managed by the SDK
+ Safari needs to call your application back when the authenticatino process is done. For this you must ensure three things:
  * Add a custom scheme managed by your app (i.e. myCoolApp://)
  * Specify this custom scheme as the base url of the callback URL when declaring you app in teh Orange Partner portal
  * add a hook in you application delegate to pass the url used to invoke your app to the CloudManager instance. This is also 
  * important because this URL will contain a token that is mandatory to use the cloud API.

``` Objective-c
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([controller.cloudManager handleOpenURL:url]) {
        return YES;
    } 
    return NO;
}
```

Additionaly, 


How to test the SDK
----------
Although the SDK is self content (i.e. you can grab the classes and use them as is), it may be useful for you to have an usage example. Two sample applications are provided to demonstrate 
the SDK usage on various use cases. 
The first example, in Objective-C, is based on a UINavigationController and shows how to navigate through the user cloud hierachy.
The second example, in Swift, makes use of a bunch of unitary tests in sequence and can also be used to check that your credentials are working.

In order to run one of the sample, you must select it and provide your own credentials, as explained below. Your are now ready to run the aaplication on a simulator or on a real device.

### Select your example
To select which example to use, just comment/uncomment the specific controller creation in AppDelegate.h line #23, that select the language and thus the type of example

### Set your own application credentials 
Either in BrowseController (line #23) or in StatusController (line #28), depending whether your are testing the Objective-C or Swift example.

### Content of BrowseController
A UINavigationController that implements a simple navigation through the Cloud content.
This is where you set your application credentials (client id, secret and redirect url).
This is also the place where you trigger user authentication and then, through a callback,
start using the cloud.

#### FileListViewController, FileListViewCell, ImageViewController
This set of simple classes is an example of how to use the CloudSession to browse the user's Cloud.
You can refer to the source code if you have any questions about the way to use it.

#### Bonus: SwiftBrowseController
This class is the Swift alternative to BrowseController and demonstrate how to connect easily in Swift

### Content of StatusController
This Swift controller will run a bunch of tests and display the result on the phone screen.
To use this Swift class, just make sure the `USE_SWIFT` #define in AppDelegate is not commented out (line #23)

#### UnitTests, TestItem
This set of classes implements a basic unit test system. A great benefit is that each unit test is also a self contained exapmle of a task. You can easily 
reuse this task in your own code or even add a new test to check a dedicated feature of your service.


SDK as a tool to help using the WEB API
---------------------------------------
For many reasons, you may want to use directly the WEB API (i.e. make straight http calls) from your own existing software. This could be because the 
user experience and/or your internal data structure is too far from what this SDK provides.

You can still take advantage of this SDK as you can dump every API calls as curl requests that are usally a good way to provide unambigous call 
examples as a valuable complement to the documentation. This way you can discover teh actual sequence os http calls, from teh authenthication phase to data retrieval.

Contact
-------
If you have any question or issue, please feel free to [contact us](https://developer.orange.com/support/contact-us)

(c) 2016 Orange - All rights reserved.

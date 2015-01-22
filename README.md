# OrangeCloudIOSSdk
Welcome to CloudMe project for iPhone, designed to help you test the Orange Cloud APIs.
This is a preliminary sample code and we are currently developing a fully featured SDK.

Please start with: https://www.orangepartner.com/content/cloud-fr-api
to get an overview of the Cloud service for Orange customers in France
and the scope and capabilities of the related Cloud APIs.
From there, you can register your app and get your own credentials
and paste them in the relevant section: #warning in ViewController.m.

We'd love to hear your feedback/comments.
Thank you in advance for your time.

-----------------------------------------------------------------------------------------
Legal notice:

ORANGE OFFERS NO WARRANTY EITHER EXPRESS OR IMPLIED INCLUDING THOSE OF MERCHANTABILITY,
NONINFRINGEMENT OF THIRD-PARTY INTELLECTUAL PROPERTY OR FITNESS FOR A PARTICULAR PURPOSE.
ORANGE SHALL NOT BE LIABLE FOR ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION,
DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
OR OTHER LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THE SAMPLE CODE,
EVEN IF ORANGE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
-----------------------------------------------------------------------------------------

Notes re: Xcode project:

This project is compatible with both iOS 7 and iOS 8 versions.

Despite the Cloud API can be accessed using conventional HTTP calls, this Objective-C project
provides a set of classes that encapsulates all the burden of making calls yourself.
These classes are then used to implement a simple navigation application to illustrate their usage.

CloudTestViewController:
---------------
A UINavigationController that implements a simple navigation through the Cloud content.
This is were you set your application credentials (client id, secret and redirect url).
This also the place where you trigger user authentication and then, through a callback,
start using the cloud.


CloudSession:
-------------
This class gives you access to Cloud functionality : user authentication, list of availables files,
detailled info on a file, upload and download of content.
You  typically start by creating a CloudSession instance with your appp credentials and open it using you main view controller.
Once the session is open you can access teh user cloud data.
Due to the asynchronous nature inherent to HTTP calls, this API makes a huge usage of blocks.
You should be never blocked by a call but remember that all UI modifications
must be done back to the main loop.

CloudItem:
----------
This is an helper class representing a cloud file very often used as parameter
or return value in many of CloudManager methods.
It is just a place holder for all information available from the CLoud.

FileListViewController, FileListViewCell, ImageViewController:
--------------------------------------------------------------
This set of simple classes are an example of how to use CloudSession to browse teh user cloud.
You can refer to the source code if you have any interrogation about the way to use it.


(c) 2014 Orange - All rights reserved.

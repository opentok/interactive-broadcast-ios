# OpenTok Interactive Broadcast Solution for iOS
![OpenTok Labs](https://d26dzxoao6i3hh.cloudfront.net/items/0U1R0a0e2g1E361H0x3c/Image%202017-11-22%20at%2012.16.38%20PM.png?v=2507a2df)

[![Build Status](https://travis-ci.com/opentok/ibs-ios.svg?token=Bgz48rVAyAihVsymz2iz&branch=develop)](https://travis-ci.com/opentok/ibs-ios)
[![codecov](https://codecov.io/gh/opentok/ibs-ios/branch/master/graph/badge.svg?token=lVSgFBGVpU)](https://codecov.io/gh/opentok/ibs-ios)

This document describes how to create an OpenTok Interactive Broadcast Solution mobile app for iOS. You will learn how to set up the API calls to use the admin ID for the backend account, set up the role and name of the mobile participant, and connect the participant with a specified event.

This guide has the following sections:

* [Prerequisites](#prerequisites): A checklist of everything you need to get started.
* [Create your first Interactive Broadcast Solution application](#createfirstapp): A step by step tutorial to help you develop a basic Interactive Broadcast Solution application.

_**NOTE:** The **Interactive Broadcast Solution** only supports landscape orientation on mobile devices._

## Prerequisites

- Xcode version 8 or later.
- Download the **iOS Interactive Broadcast Solution Framework** provided by TokBox.
- You will need the **Admin ID** and **Backend Base URL** provided by TokBox.

_**NOTE:** To get the **iOS Interactive Broadcast Solution Framework**, **Admin ID**, and **Backend Base URL**, contact <a mailto:"bizdev@tokbox.com">bizdev@tokbox.com</a>._

_**IMPORTANT:** In order to deploy the OpenTok Interactive Broadcast Solution, your web domain must use HTTPS._

<h2 id=createfirstapp> Create your first Interactive Broadcast Solution application</h2>

To get up and running quickly with your first app, go through the following steps in the tutorial provided below:

- [OpenTok Interactive Broadcast Solution for iOS](#opentok-interactive-broadcast-solution-for-ios)
  - [Prerequisites](#prerequisites)
    - [Create an Xcode project](#create-an-xcode-project)
    - [Add the required frameworks](#add-the-required-frameworks)
    - [Configure the Interactive Broadcast Solution controller](#configure-the-interactive-broadcast-solution-controller)
  - [Development and Contributing](#development-and-contributing)
  - [Getting Help](#getting-help)
  - [Further Reading](#further-reading)

### Create an Xcode project

In Xcode, configure a new iOS **Single View Application** project.

1. Specify your **Product Name** and the storage location for your project.
2. From the **Project Navigator** view, click **Build Settings** and configure the following:
   * **Build Options > Enable Bitcode**: Select **No**.


### Add the required frameworks

1.  Drag the **IBKit.framework** into your project. Select each and ensure **Target Membership** is checked in the **File Inspector**.
2.  From the **Project Navigator** view, click **General**. Add both frameworks in **Embedded Binaries**.
3.  On the **General** tab under **Linked Frameworks and Libraries**, add all the required frameworks listed at [OpenTok iOS SDK Requirements](https://tokbox.com/developer/sdks/ios/).


### Configure the Interactive Broadcast Solution controller

Now you are ready to add the Interactive Broadcast Solution user detail to your app, as well as the Admin ID and Base URL you retrieved earlier (see [Prerequisites](#prerequisites)). This detail is needed to initialize the Interactive Broadcast Solution controller that connects the app with the backend server and presents the user interface populated with Interactive Broadcast Solution events.

1. From the **Project Navigator** view, edit **ViewController.m** and ensure you have the following import statements:

```objc
#import <IBKit/IBKit.h>
```

2. You will be able to use the API to create an Interactive Broadcasting Solution controller.

To initialize the controller you need:

   - **The Admin ID** is unique to your account. It is used to authorize your code to use the library and make requests to the backend, which is hosted at the location identified by the Backend Base URL. You can use your Admin ID for multiple events.
   - **The Backend URL** is the endpoint to the web service hosting the events, and should be provided by TokBox.
   - **The User Type** to be used. Specify one of the following values for the User Type: `fan`, `celebrity`, or `host`. There should only be one celebrity and host per event.
   - The Username will be displayed in chats with the producer and when Fans get in line. **This field is optional**.

3. Configure the backend URL using the `configureBackendURL ` method:

```objc
[IBApi configureBackendURL:<YOUR_BACKEND URL>];
``` 

4. Now you can create an Interactive Broadcast Solution controller, which will populate the application with events available on the Interactive Broadcast Solution service using the `sharedManager` method, the `admin_id` parameter and the `user type`:

```objc
[[IBApi sharedManager] getInstanceWithAdminId: <#admin id#>
                                   completion:^(IBInstance *instance, NSError *error) {

                                       dispatch_async(dispatch_get_main_queue(), ^(){

                                           if (!error) {

                                               // user data could be:
                                               // [IBUser userWithIBUserRole:IBUserRoleFan name:@"FanName"]
                                               // [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"Celebrity"]
                                               // [IBUser userWithIBUserRole:IBUserRoleHost name:@"Host"]

                                               UIViewController *viewcontroller;
                                               if(instance.events.count != 1){
                                                   viewcontroller = [[EventsViewController alloc] initWithInstance:instance user:<#user data#>];
                                               }
                                               else {
                                                   viewcontroller = [[EventViewController alloc] initWithInstance:instance eventIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] user:<#user data#>];
                                               }

                                               [weakSelf presentViewController:viewcontroller animated:YES completion:nil];
                                           }
                                       });
                                   }];
```

## Development and Contributing

Interested in contributing? We :heart: pull requests! See the 
[Contribution](CONTRIBUTING.md) guidelines.

## Getting Help

We love to hear from you so if you have questions, comments or find a bug in the project, let us know! You can either:

- Open an issue on this repository
- See <https://support.tokbox.com/> for support options
- Tweet at us! We're [@VonageDev](https://twitter.com/VonageDev) on Twitter
- Or [join the Vonage Developer Community Slack](https://developer.nexmo.com/community/slack)

## Further Reading

- Check out the Developer Documentation at <https://tokbox.com/developer/>
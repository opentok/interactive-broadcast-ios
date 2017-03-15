![logo](tokbox-logo.png)

[![Build Status](https://travis-ci.com/opentok/spotlight-ios.svg?token=CxoLD2TL8UCwsuAUJUsN&branch=master)](https://travis-ci.com/opentok/spotlight-ios)

# OpenTok Interactive Broadcast Solution for iOS

This document describes how to create an OpenTok Interactive Broadcast Solution mobile app for iOS. You will learn how to set up the API calls to use the admin ID for the backend account, set up the role and name of the mobile participant, and connect the participant with a specified event.

This guide has the following sections:

* [Prerequisites](#prerequisites): A checklist of everything you need to get started.
* [Create your first Interactive Broadcast Solution application](#createfirstapp): A step by step tutorial to help you develop a basic Interactive Broadcast Solution application.

_**NOTE:** The **Interactive Broadcast Solution** only supports landscape orientation on mobile devices._

## Prerequisites

- Xcode version 5 or later.
- Download the **iOS Interactive Broadcast Solution Framework** provided by TokBox.
- You will need the **Admin ID** and **Backend Base URL** provided by TokBox.

_**NOTE:** To get the **iOS Interactive Broadcast Solution Framework**, **Admin ID**, and **Backend Base URL**, contact <a mailto:"bizdev@tokbox.com">bizdev@tokbox.com</a>._

_**IMPORTANT:** In order to deploy the OpenTok Interactive Broadcast Solution, your web domain must use HTTPS._

<h2 id=createfirstapp> Create your first Interactive Broadcast Solution application</h2>

To get up and running quickly with your first app, go through the following steps in the tutorial provided below:

1. [Create an Xcode project](#create-an-xcode-project)
2. [Add the required frameworks](#add-the-required-frameworks)
3. [Configure the Interactive Broadcast Solution controller](#configure-the-interactive-broadcast-solution-controller)
4. [Handle events](#handle-events)

View the [Complete code example](#complete-code-example).

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

3. The ``user type`` can be passed depending on which button is pressed:

```objc
_requestData = @{
                     @(self.celebrityButton.hash): [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"Celebrity"],
                     @(self.hostButton.hash): [IBUser userWithIBUserRole:IBUserRoleHost name:@"Host"],
                     @(self.fanButton.hash): [IBUser userWithIBUserRole:IBUserRoleFan name:@"FanName"],
                     @(self.mlbFanButton.hash): [IBUser userWithIBUserRole:IBUserRoleFan name:@"FanName"],
                     @(self.fanCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleFan name:@"Fan"],
                     @(self.celebrityCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"Celebrity"],
                     @(self.hostCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleHost name:@"Host"]
                    };
```                     

2. Configure the backend URL using the `configureBackendURL ` method:

```objc
[IBApi configureBackendURL:<YOUR_BACKEND URL>];
``` 

1. Now you can create an Interactive Broadcast Solution controller, which will populate the application with events available on the Interactive Broadcast Solution service using the `sharedManager` method, the `admin_id` parameter and the `user type`:

```objc
- (IBAction)mlbEventButtonPressed:(UIButton *)sender {
    
    [IBApi configureBackendURL:<YOUR_BACKEND_URL>];
    __weak ViewController *weakSelf = (ViewController *)self;
    [SVProgressHUD show];
    [[IBApi sharedManager] getInstanceWithInstanceId:mlbpass
                                          completion:^(IBInstance *instance, NSError *error) {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^(){
                                                  [SVProgressHUD dismiss];
                                                  if (!error) {
                                                      NSMutableDictionary *instance_data = [NSMutableDictionary dictionaryWithDictionary:@{}];
                                                      instance_data[@"backend_base_url"] = MLBBackend;
                                      
                                                      
                                                      UIViewController *viewcontroller;
                                                      if(instance.events.count != 1){
                                                          viewcontroller = [[EventsViewController alloc] initWithInstance:instance user:weakSelf.requestData[@(sender.hash)]];
                                                      }
                                                      else {
                                                          viewcontroller = [[EventViewController alloc] initWithInstance:instance eventIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] user:weakSelf.requestData[@(sender.hash)]];
                                                      }
                                                      [weakSelf presentViewController:viewcontroller animated:YES completion:nil];
                                                  }
                                                  else {
                                                      [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                  }
                                            });
                                          }];

}
```


### Handle events

The Interactive Broadcast Solution Kit provides you with these fully functional controllers that communicate with the backend web service and handle events: **EventViewController** and **EventsViewController**.

If you would like to create your own custom event handling implementation, create your event handling class and perform the following steps:


1. Add this import statement to your event handling class:

```objc
#import <IBKit/IBApi.h>
```

2. Fetch the events:

   ```objc
   NSMutableDictionary *instanceData = [[IBApi sharedManager] getEvents:admin_id
                                                                       back_url:backend_url];
   ```

3. Pass the event information to the event view controller:

   ```objc
    EventViewController *detailEvent = [[EventViewController alloc] initEventWithData:instanceData[@"events"][0]
                                                                       connectionData:instanceData
                                                                                 user:user
                                                                             isSingle:YES];
    [detailEvent setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:detailEvent animated:YES completion:nil];
   ```


## Complete code example

You have completed the task of setting up a fully working example that uses the OpenTok Interactive Broadcast Solution! You can add processing for events and errors, and begin using your program.


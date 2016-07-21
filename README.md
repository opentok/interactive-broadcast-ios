![logo](tokbox-logo.png)

# OpenTok Interactive Broadcast Solution for iOS<br/>Version 1.0

This document describes how to create a OpenTok Interactive Broadcast Solution mobile app for iOS. You will learn how to set up the API calls to use the instance ID for the backend account, set up the role and name of the mobile participant, and connect the participant with a specified event.

This guide has the following sections:

* [Prerequisites](#prerequisites): A checklist of everything you need to get started.
* [Create your first Interactive Broadcast Solution application](#createfirstapp): A step by step tutorial to help you develop a basic Interactive Broadcast Solution application.
* [Complete code example](#complete-code-example): This is the complete code example that you will develop in this tutorial. You can skip the tutorial and use this example to get started quickly with your own application development.

_**NOTE:** The **Interactive Broadcast Solution** only supports landscape orientation on mobile devices._

## Prerequisites

- Xcode version 5 or later.
- Download the **iOS Interactive Broadcast Solution Framework** provided by TokBox.
- You will need the **Instance ID** and **Backend Base URL** provided by TokBox.

_**NOTE:** To get the **iOS Interactive Broadcast Solution Framework**, **Instance ID**, and **Backend Base URL**, contact <a mailto:"bizdev@tokbox.com">bizdev@tokbox.com</a>._

_**IMPORTANT:** In order to deploy the OpenTok Interactive Broadcast Solution, your web domain must use HTTPS._

<h2 id=createfirstapp> Create your first Interactive Broadcast Solution application</h2>

To get up and running quickly with your first app, go through the following steps in the tutorial provided below:

1. [Create an Xcode project](#create-an-xcode-studio-project)
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

Now you are ready to add the Interactive Broadcast Solution user detail to your app, as well as the Instance ID and Base URL you retrieved earlier (see [Prerequisites](#prerequisites)). This detail is needed to initialize the Interactive Broadcast Solution controller that connects the app with the backend server and presents the user interface populated with Interactive Broadcast Solution events.

1. From the **Project Navigator** view, edit **ViewController.m** and ensure you have the following import statements:

```objc
#import <IBKit/MainIBViewController.h>
```

2. You will now be able to create a Interactive Broadcast Solution controller, which will populate the application with events available on the Interactive Broadcast Solution service. Ensure the following statement is within the **ViewController** interface declaration in **ViewController.m**:

```objc
@property (strong, nonatomic) MainIBViewController *IBController;
```


3. In **ViewController.m**, add this `loadIBController()` method, which instantiates the Interactive Broadcast Solution controller. You can call this method as needed to respond to load or button click events:

```objc
-(void)loadIBController:{
    NSString *instance_id = @"Your instance id";
    NSString *backend_url = @"your backend url";
    NSMutableDictionary *user = [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"type":@"fan",
                                    @"name":@""
                                }];
    self.IBController = [[MainIBViewController alloc] initWithData:instance_id
                                                                          backend_base_url:backend_url
                                                                                      user:user];
    [self presentViewController:self.IBController animated:NO completion:nil];
}
```


4. In the method you just added, the `user` dictionary stores the User Type and Username. It is used to initialize the `IBController` object, which is also initialized with the Instance ID and Backend Base Url:

   - The Instance ID is unique to your account. It is used to authorize your code to use the library and make requests to the backend, which is hosted at the location identified by the Backend Base URL. You can use your Instance ID for multiple events.
   - The Backend Base URL is the endpoint to the web service hosting the events, and should be provided by TokBox.
   - Specify one of the following values for the User Type: `fan`, `celebrity`, or `host`. There should only be one celebrity and host per event.
   - The Username will be displayed in chats with the producer and when Fans get in line. This field is optional.


### Handle events

The Interactive Broadcast Solution Kit provides you with these fully functional controllers that communicate with the backend web service and handle events: **EventViewController** and **EventsViewController**.

If you would like to create your own custom event handling implementation, create your event handling class and perform the following steps:


1. Add these import statements to your event handling class:

```objc
#import <IBKit/EventViewController.h>
#import <IBKit/IBApi.h>
```

2. Fetch the events:

   ```objc
   NSMutableDictionary *instanceData = [[IBApi sharedInstance] getEvents:instance_id
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


## Additional information

For information on how to set up archiving on an Interactive Broadcast (IB) instance, click <a href="./ARCHIVING.md">here</a>.
 

//
//  ViewController.m
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "ViewController.h"
#import "MainSpotlightControllerViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *SingleInstanceButton;
@property (weak, nonatomic) IBOutlet UIButton *SingleInstanceHost;
@property (weak, nonatomic) IBOutlet UIButton *SingleInstanceFan;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) MainSpotlightControllerViewController  *spotlightController;
@property (strong, nonatomic) NSString *instance_id;
@property (strong, nonatomic) NSString *backend_base_url;
@property (strong, nonatomic) NSDictionary* user;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.instance_id = @"AAAA1";
}

- (IBAction)openSingleInstance:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                @"type":@"celebrity",
                                @"name":@"Celebridad",
                                @"id":@1234,
                                  }];
    
    [self presentController:user];
}

- (IBAction)singleInstanceAsHost:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"host",
                                                           @"name":@"HOST NAME",
                                                           @"id":@1235,
                                                           }];
    
    [self presentController:user];

    
}
- (IBAction)singleInstanceAsFan:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"fan",
                                                           @"name":@"FanName",
                                                           }];
    [self presentController:user];

}



- (IBAction)openMultipleInstance:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"fan",
                                                           @"name":@"Fan",
                                                           }];
    [self presentController:user];

}
- (IBAction)multipleAsHost:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"host",
                                                           @"name":@"Host",
                                                           }];
    [self presentController:user];
}
- (IBAction)multipleAsCeleb:(id)sender {
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"celebrity",
                                                           @"name":@"Celebrity",
                                                           }];
    [self presentController:user];
}

///SELF IMPLEMENTED MULTIPLE EVENTS VIEW
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"GoToMultipleEvents"]) {
        ViewController *vc = [segue destinationViewController];
        NSMutableDictionary *user =[NSMutableDictionary
                                    dictionaryWithDictionary:@{
                                                               @"type":@"fan",
                                                               @"name":@"Fan",
                                                               }];
        vc.instance_id = self.instance_id;
        vc.backend_base_url= @"https://chatshow-tesla.herokuapp.com";
        vc.user = user;
    }
}


-(void) presentController:(NSMutableDictionary*)userOptions{
    if(![self.nameTextField.text isEqualToString:@"" ]){
        userOptions[@"name"] = self.nameTextField.text;
    }
    NSString *stagingBackend = @"https://chatshow-tesla.herokuapp.com";
//    NSString *demoBackend = @"https://chatshow-tesla-prod.herokuapp.com";
//    NSString *MLBBackend = @"https://spotlight-tesla-mlb.herokuapp.com";
    self.spotlightController = [[MainSpotlightControllerViewController alloc] initWithData:@"AAAA1" backend_base_url:stagingBackend user:userOptions];
    [self presentViewController:self.spotlightController animated:NO completion:nil];
}

@end

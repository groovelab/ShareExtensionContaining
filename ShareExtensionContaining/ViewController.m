//
//  ViewController.m
//  ShareExtensionContaining
//
//  Created by Nanba Takeo on 2014/08/06.
//  Copyright (c) 2014年 GrooveLab. All rights reserved.
//

#import "ViewController.h"

static NSString *const AppGroupId = @"group.asia.groovelab.ShareExtensionContaining";
static NSString *const UserDefaultsKeyMixiConsumerKey = @"mixiConsumerKey";
static NSString *const UserDefaultsKeyMixiConsumerSecret = @"mixiConsumerSecret";
static NSString *const UserDefaultsKeyMixiAuthrizedCode = @"mixiAuthrizedCode";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *mixiConsumerKey;
@property (weak, nonatomic) IBOutlet UITextField *mixiConsumerSecret;
@property (weak, nonatomic) IBOutlet UITextField *mixiAuthrizedCode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:AppGroupId];
    self.mixiConsumerKey.text = [sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerKey];
    self.mixiConsumerSecret.text = [sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerSecret];
    self.mixiAuthrizedCode.text = [sharedUserDefaults objectForKey:UserDefaultsKeyMixiAuthrizedCode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveAction:(id)sender {
    
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:AppGroupId];
    [sharedUserDefaults setObject:self.mixiConsumerKey.text forKey:UserDefaultsKeyMixiConsumerKey];
    [sharedUserDefaults setObject:self.mixiConsumerSecret.text forKey:UserDefaultsKeyMixiConsumerSecret];
    [sharedUserDefaults setObject:self.mixiAuthrizedCode.text forKey:UserDefaultsKeyMixiAuthrizedCode];
}

- (IBAction)shareTestAction:(id)sender {
    
    NSString *string = @"test text for mixi voice";
    NSURL *URL = [NSURL URLWithString:@"http://mixi.jp/"];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[string, URL]
                                                        applicationActivities:nil];
    
    [activityViewController setCompletionWithItemsHandler:^(NSString *activityType,
                                                            BOOL completed,
                                                            NSArray *returnedItems,
                                                            NSError * error){
        
        if ( completed ) {
            //  TODO error handling
            NSLog(@"share complete");
            //            NSExtensionItem* extensionItem = [returnedItems firstObject];
            //            NSItemProvider* itemProvider = [[extensionItem attachments] firstObject];
        } else {
            NSLog(@"canceld");
        }
    }];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}
@end

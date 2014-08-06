//
//  ShareViewController.m
//  MixiShare
//
//  Created by Nanba Takeo on 2014/08/06.
//  Copyright (c) 2014年 GrooveLab. All rights reserved.
//

#import "ShareViewController.h"
@import MobileCoreServices;

static NSString *const AppGroupId = @"group.asia.groovelab.ShareExtensionContaining";
static NSString *const UserDefaultsKeyMixiConsumerKey = @"mixiConsumerKey";
static NSString *const UserDefaultsKeyMixiConsumerSecret = @"mixiConsumerSecret";
static NSString *const UserDefaultsKeyMixiAuthrizedCode = @"mixiAuthrizedCode";
static NSString *const UserDefaultsKeyMixiRefreshToken = @"mixiRefreshToken";

@interface ShareViewController ()

@property (strong, nonatomic) NSUserDefaults *sharedUserDefaults;
@property (strong, nonatomic) NSString* mixiRefreshToken;

@end

@implementation ShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //  User Defaults
    self.sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:AppGroupId];
}

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here

    //  refresh token
    self.mixiRefreshToken = [self refreshToken];

    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
    NSItemProvider *urlItemProvider = inputItem.attachments.firstObject;
    
    if ([urlItemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL]) {
        [urlItemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL
                                           options:nil
                                 completionHandler:^(NSURL *url, NSError *error) {
                                     if (!error) {
                                         
                                         //  access token
                                         NSString *accessToken = [self accessToken];
                                         
                                         // text for post
                                         NSLog( @"text : %@", self.contentText);
                                         NSLog( @"url : %@", url.absoluteString );
                                         NSString *postString = [NSString stringWithFormat:@"%@ %@", self.contentText, url.absoluteString];
                                         
                                         // post
                                         [self post:postString token:accessToken];
                                         
                                         // notify to host app
                                         NSExtensionItem *outputItem = [inputItem copy];
                                         outputItem.attributedContentText = [[NSAttributedString alloc]
                                                                             initWithString:self.contentText attributes:nil];
                                         
                                         [self.extensionContext completeRequestReturningItems:@[outputItem]
                                                                            completionHandler:nil];
                                     }
                                 }
         ];
    }
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    if ( self.mixiRefreshToken.length > 0 ) {
        return @[];
    }
    
    SLComposeSheetConfigurationItem *configurationItem = [[SLComposeSheetConfigurationItem alloc] init];
    configurationItem.title = @"account";
    configurationItem.value = @"setting";
    configurationItem.tapHandler = ^(void){
        //  TODO add button to launch up containing app into view controller
        UIViewController *viewController = [[UIViewController alloc] init];
        [self pushConfigurationViewController:viewController];
    };
    return @[configurationItem];
}

#pragma mark access to mixi methods

- (NSString*)refreshToken
{
    //  check refresh token
    NSString *refreshToken = [self.sharedUserDefaults stringForKey:UserDefaultsKeyMixiRefreshToken];
    if ( refreshToken.length > 0 ) {
        return refreshToken;
    }
    
    //  get refresh token
    refreshToken = [self obtainTefreshToken];
    
    //  usrDefaults
    [self.sharedUserDefaults setObject:refreshToken forKey:UserDefaultsKeyMixiRefreshToken];
    
    return refreshToken;
}

- (NSString*)obtainTefreshToken
{
    NSString *mixiConsumrKey = [self.sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerKey];
    NSString *mixiConsumrSecret = [self.sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerSecret];
    NSString *authorizedCode = [self.sharedUserDefaults objectForKey:UserDefaultsKeyMixiAuthrizedCode];
    
    NSString *urlString = @"https://secure.mixi-platform.com/2/token";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"post"];
    
    NSString *param = [NSString stringWithFormat:@"grant_type=authorization_code&client_id=%@&client_secret=%@&code=%@&redirect_uri=https%%3A%%2F%%2Fmixi.jp%%2Fconnect_authorize_success.html",
                       mixiConsumrKey, mixiConsumrSecret, authorizedCode];
    [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *refreshToken = @"";
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if ( data ) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&error];
        refreshToken = dict[@"refresh_token"];
        NSLog( @"get refresh token : %@", refreshToken );
    }
    return refreshToken;
}

- (NSString*)accessToken
{
    //  get access token
    NSString *mixiConsumrKey = [self.sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerKey];
    NSString *mixiConsumrSecret = [self.sharedUserDefaults objectForKey:UserDefaultsKeyMixiConsumerSecret];

    NSString *urlString = @"https://secure.mixi-platform.com/2/token";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"post"];
    
    NSString *param = [NSString stringWithFormat:@"grant_type=refresh_token&client_id=%@&client_secret=%@&refresh_token=%@",mixiConsumrKey, mixiConsumrSecret, self.refreshToken];
    [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *accessToken = @"";
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if ( data ) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&error];
        accessToken = dict[@"access_token"];
        NSLog( @"get access token : %@", accessToken );
    }

    return accessToken;
}

- (void)post:(NSString*)postString token:(NSString*)accessToken
{
    NSString *encodeString = [postString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    NSString *urlString = @"https://api.mixi-platform.com/2/voice/statuses/update";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"post"];
    [request addValue:[NSString stringWithFormat:@"Bearer %@" ,accessToken] forHTTPHeaderField:@"Authorization"];
    
    NSString *param = [NSString stringWithFormat:@"status=%@", encodeString];
    [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSLog( @"error : %@", error );
    NSLog( @"response : %@", response );
    NSLog( @"data : %@", data );
    
    //  TODO error handling
}

@end

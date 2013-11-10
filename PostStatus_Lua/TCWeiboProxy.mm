//
//  TCWeiboProxy.m
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-23.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import "TCWeiboProxy.h"
#import "ScreenShot.h"

#include "CCLuaEngine.h"
#include "CCLuaObjcBridge.h"

@interface TCWeiboProxy ()

@property (nonatomic, assign) int callback;
@property (nonatomic, retain) NSDictionary *weiboInfo;

- (void)configeAuthData;
- (void)sendWeiboSucceed:(NSDictionary *)aDic;
- (void)sendWeiboFailed:(NSError *)aError;
- (void)weiboDidLogIn;

@end

@implementation TCWeiboProxy

+ (id)sharedTCWeiboProxy
{
    static TCWeiboProxy *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TCWeiboProxy alloc]init];
    });
    
    return instance;
}

+ (void)sendWeiboWithText:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    int callback = [[aDic objectForKey:@"callback"] intValue];
    
    [[TCWeiboProxy sharedTCWeiboProxy] setCallback:callback];
    
    [[TCWeiboProxy sharedTCWeiboProxy] sendWeiboWithText:aText];
}

+ (void)sendWeiboWithTextAndImage:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    int callback = [[aDic objectForKey:@"callback"] intValue];
    int imageID = [[aDic objectForKey:@"imageID"] intValue];
    
    [[TCWeiboProxy sharedTCWeiboProxy] setCallback:callback];
    
    UIImage *img = [[ScreenShot sharedScreenShot]getScreenshortByID:imageID];
    [[TCWeiboProxy sharedTCWeiboProxy] sendWeibowithtext:aText andImage:img];
}

+ (void)logout
{
    [[[TCWeiboProxy sharedTCWeiboProxy] TCWeibo] logOut];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
}

- (id)init
{
    self = [super init];
    if (self) {
        _TCWeibo = [[TCWBEngine alloc]initWithAppKey:WiressSDKDemoAppKey andSecret:WiressSDKDemoAppSecret andRedirectUrl:REDIRECTURI];
        [self configeAuthData];
    }
    return self;
}

- (void)dealloc
{
    [_TCWeibo release];
    [super dealloc];
}

- (void)login
{
    [self.TCWeibo logInWithDelegate:self onSuccess:@selector(weiboDidLogIn) onFailure:nil];
}

- (void)configeAuthData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *TCWeiboInfo = [defaults objectForKey:@"CocTCWeiboAuthData"];
    if ([TCWeiboInfo objectForKey:@"AccessTokenKey"] && [TCWeiboInfo objectForKey:@"ExpirationDateKey"] && [TCWeiboInfo objectForKey:@"Name"] && [TCWeiboInfo objectForKey:@"refresh_token"] && [TCWeiboInfo objectForKey:@"OpenID"])
    {
        [_TCWeibo logInWithAccessToken:[TCWeiboInfo objectForKey:@"AccessTokenKey"] expiredTime:[TCWeiboInfo objectForKey:@"ExpirationDateKey"] openID:[TCWeiboInfo objectForKey:@"OpenID"] name:[TCWeiboInfo objectForKey:@"Name"] andRefreshToken:[TCWeiboInfo objectForKey:@"refresh_token"] delegate:nil onSuccess:nil onFailure:nil];
    }
}

- (void)sendWeiboWithText:(NSString *)aText
{
//    [self.TCWeibo UIBroadCastMsgWithContent:aText
//                                       andImage:nil
//                                    parReserved:nil
//                                       delegate:self
//                                    onPostStart:@selector(postStart)
//                                  onPostSuccess:@selector(sendWeiboSucceed:)
//                                  onPostFailure:@selector(sendWeiboSucceed:)];
    if ([self.TCWeibo isLoggedIn]) {
        
        [self.TCWeibo postTextTweetWithFormat:@"json"
                                      content:aText
                                     clientIP:nil
                                    longitude:nil
                                  andLatitude:nil
                                  parReserved:[NSMutableDictionary dictionaryWithObject:@"ios-sdk-2.0-publish" forKey:@"appfrom"]
                                     delegate:self
                                    onSuccess:@selector(sendWeiboSucceed:)
                                    onFailure:@selector(sendWeiboFailed:)];
    } else {
        
        self.weiboInfo = [[NSDictionary alloc] initWithObjectsAndKeys:aText, @"content", @"text", @"type", nil];
        
        [self login];
        
    }
    

}

- (void)sendWeibowithtext:(NSString *)aText andImage:(UIImage *)aImage
{
//    [self.TCWeibo UIBroadCastMsgWithContent:aText
//                                   andImage:aImage
//                                parReserved:nil
//                                   delegate:self
//                                onPostStart:@selector(postStart)
//                              onPostSuccess:@selector(sendWeiboSucceed:)
//                              onPostFailure:@selector(sendWeiboSucceed:)];
    NSData *imageData = UIImageJPEGRepresentation(aImage, 1.0);
    
    if ([self.TCWeibo isLoggedIn]) {
        
        [self.TCWeibo postPictureTweetWithFormat:@"json"
                                         content:aText
                                        clientIP:nil
                                             pic:imageData
                                  compatibleFlag:@"0"
                                       longitude:nil
                                     andLatitude:nil
                                     parReserved:[NSMutableDictionary dictionaryWithObject:@"ios-sdk-2.0-publish" forKey:@"appfrom"]
                                        delegate:self
                                       onSuccess:@selector(sendWeiboSucceed:)
                                       onFailure:@selector(sendWeiboFailed:)];
        
    } else {
        
        self.weiboInfo = [[NSDictionary alloc] initWithObjectsAndKeys:aText, @"content", imageData, @"image", @"image", @"type", nil];
        
        [self login];
        
    }
    
    
}

#pragma mark - SendWeibo Callback

- (void)weiboDidLogIn
{
    NSString *type = [self.weiboInfo objectForKey:@"type"];
    if ([type isEqualToString:@"text"]) {
        
        [self.TCWeibo postTextTweetWithFormat:@"json"
                                      content:[self.weiboInfo objectForKey:@"text"]
                                     clientIP:nil
                                    longitude:nil
                                  andLatitude:nil
                                  parReserved:[NSMutableDictionary dictionaryWithObject:@"ios-sdk-2.0-publish" forKey:@"appfrom"]
                                     delegate:self
                                    onSuccess:@selector(sendWeiboSucceed:)
                                    onFailure:@selector(sendWeiboFailed:)];
        
    } else {
        
        [self.TCWeibo postPictureTweetWithFormat:@"json"
                                         content:[self.weiboInfo objectForKey:@"text"]
                                        clientIP:nil
                                             pic:[self.weiboInfo objectForKey:@"image"]
                                  compatibleFlag:@"0"
                                       longitude:nil
                                     andLatitude:nil
                                     parReserved:[NSMutableDictionary dictionaryWithObject:@"ios-sdk-2.0-publish" forKey:@"appfrom"]
                                        delegate:self
                                       onSuccess:@selector(sendWeiboSucceed:)
                                       onFailure:@selector(sendWeiboFailed:)];
        
    }
}

- (void)sendWeiboSucceed:(NSDictionary *)aDic
{
    if ([[aDic objectForKey:@"ret"] intValue] == 0) {
        
        NSLog(@"send TCWeibo succeed!");
        cocos2d::CCLuaEngine *LuaEngine = cocos2d::CCLuaEngine::defaultEngine();
        LuaEngine->executeGlobalFunction("weiboPostSucceed");
        
        cocos2d::CCLuaObjcBridge::pushLuaFunctionById(self.callback);
        cocos2d::CCLuaObjcBridge::getStack()->executeFunction(0);
        cocos2d::CCLuaObjcBridge::releaseLuaFunctionById(self.callback);
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                       message:@"腾讯微博分享成功" delegate:nil
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    } else {
        NSLog(@"send TCWeibo failed!");
    }
}

- (void)sendWeiboFailed:(NSError *)aError
{
    NSLog(@"send TCWeibo failed, error:%@", [aError localizedDescription]);
}

@end

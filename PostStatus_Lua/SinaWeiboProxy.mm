//
//  SinaWeiboProxy.m
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-20.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import "SinaWeiboProxy.h"
#import "ScreenShot.h"

#include "CCLuaEngine.h"
#include "CCLuaObjcBridge.h"

#define kTextUrl         @"statuses/update.json"
#define kTextAndImageUrl @"statuses/upload.json"

@interface SinaWeiboProxy ()

@property (nonatomic, retain) NSMutableDictionary *param;
@property (nonatomic, assign) id<SinaWeiboRequestDelegate> postDelegate;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, copy) NSString *netMethod;
@property (nonatomic, assign) int callback;

//设置用户数据
- (void)configeAuthData;
//储存用户数据
- (void)storeAuthData;
//移除用户数据
- (void)removeAuthData;

@end

@implementation SinaWeiboProxy

+ (id)sharedSinaWeiboProxy
{
    static SinaWeiboProxy *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SinaWeiboProxy alloc]init];
    });
    
    return instance;
}

+ (void)sendWeiboWithText:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    int callback = [[aDic objectForKey:@"callback"] intValue];
    
    [[SinaWeiboProxy sharedSinaWeiboProxy] setCallback:callback];
    
    [[SinaWeiboProxy sharedSinaWeiboProxy] sendWeiboWithText:aText andDelegate:[SinaWeiboProxy sharedSinaWeiboProxy]];
}

+ (void)sendWeiboWithTextAndImage:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    int callback = [[aDic objectForKey:@"callback"] intValue];
    int imageID = [[aDic objectForKey:@"imageID"] intValue];
    
    [[SinaWeiboProxy sharedSinaWeiboProxy] setCallback:callback];
    
    UIImage *img = [[ScreenShot sharedScreenShot]getScreenshortByID:imageID];

    [[SinaWeiboProxy sharedSinaWeiboProxy] sendWeibowithtext:aText andImage:img andDelegate:[SinaWeiboProxy sharedSinaWeiboProxy]];
}

+ (void)logout
{
    [[[SinaWeiboProxy sharedSinaWeiboProxy] sinaWeibo] logOut];
}

- (id)init
{
    self = [super init];
    if (self) {
        _sinaWeibo = [[SinaWeibo alloc]initWithAppKey:kAppKey
                                           appSecret:kAppSecret
                                      appRedirectURI:kAppRedirectURI
                                         andDelegate:self];
        [self configeAuthData];
    }
    return self;
}

- (void)dealloc
{
    [_sinaWeibo release];
    [super dealloc];
}

- (void)login
{
    [_sinaWeibo logIn];
}

- (void)applicationDidBecomeActive
{
    [self.sinaWeibo applicationDidBecomeActive];
}

- (BOOL)handleOpenURL:(NSURL *)aURL
{
    return [self.sinaWeibo handleOpenURL:aURL];
}

- (BOOL)isAuthValid
{
    return [self.sinaWeibo isAuthValid];
}

- (void)sendWeiboWithText:(NSString *)aText andDelegate:(id<SinaWeiboRequestDelegate>)aDelegate
{
    if ([self.sinaWeibo isAuthValid]) {
        
        [self.sinaWeibo requestWithURL:kTextUrl
                                params:[NSMutableDictionary dictionaryWithObjectsAndKeys:aText, @"status", nil]
                            httpMethod:@"POST"
                              delegate:aDelegate];
        
    } else {
        //如果验证不成功，将数据储存，成功后直接发送
        self.param = [NSMutableDictionary dictionaryWithObjectsAndKeys:aText, @"status", nil];
        self.netMethod = @"POST";
        self.URL = kTextUrl;
        self.postDelegate = aDelegate;
        
        [self login];
    }
}

- (void)sendWeibowithtext:(NSString *)aText andImage:(UIImage *)aImage andDelegate:(id<SinaWeiboRequestDelegate>)aDelegate
{
    if ([self.sinaWeibo isAuthValid]) {
        
        [self.sinaWeibo requestWithURL:kTextAndImageUrl
                                params:[NSMutableDictionary dictionaryWithObjectsAndKeys:aText, @"status", aImage, @"pic", nil]
                            httpMethod:@"POST"
                              delegate:aDelegate];
        
    } else {
        //如果验证不成功，将数据储存，成功后直接发送
        self.param = [NSMutableDictionary dictionaryWithObjectsAndKeys:aText, @"status", aImage, @"pic", nil];
        self.netMethod = @"POST";
        self.URL = kTextAndImageUrl;
        self.postDelegate = aDelegate;
        
        [self login];
    }
}

#pragma mark - Private Methods

- (void)configeAuthData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *sinaweiboInfo = [defaults objectForKey:@"CocSinaWeiboAuthData"];
    if ([sinaweiboInfo objectForKey:@"AccessTokenKey"] && [sinaweiboInfo objectForKey:@"ExpirationDateKey"] && [sinaweiboInfo objectForKey:@"UserIDKey"])
    {
        _sinaWeibo.accessToken = [sinaweiboInfo objectForKey:@"AccessTokenKey"];
        _sinaWeibo.expirationDate = [sinaweiboInfo objectForKey:@"ExpirationDateKey"];
        _sinaWeibo.userID = [sinaweiboInfo objectForKey:@"UserIDKey"];
    }
}

- (void)storeAuthData
{
    NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                              _sinaWeibo.accessToken, @"AccessTokenKey",
                              _sinaWeibo.expirationDate, @"ExpirationDateKey",
                              _sinaWeibo.userID, @"UserIDKey",
                              _sinaWeibo.refreshToken, @"refresh_token", nil];
    [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"CocSinaWeiboAuthData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeAuthData
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
}

#pragma mark - SinaWeibo Delegate

/**
 *	SinaWeibo 对象登录操作完成后,调用此方法。
 */
- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboDidLogIn userID = %@ accesstoken = %@ expirationDate = %@ refresh_token = %@", sinaweibo.userID, sinaweibo.accessToken, sinaweibo.expirationDate,sinaweibo.refreshToken);
    [self storeAuthData];
    
    if (self.param && self.netMethod && self.URL && self.postDelegate) {
        [self.sinaWeibo requestWithURL:self.URL
                                params:self.param
                            httpMethod:self.netMethod
                              delegate:self.postDelegate];
    }
}

/**
 *	SinaWeibo 对象登出操作完成后,调用此方法。
 */
- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboDidLogOut");
    [self removeAuthData];
}

/**
 *	取消登录操作,用户在 sso 登录过程中将应用重新唤醒到前台后,应调用[SinaWeibo applicationDidBecomeActive]方法,此方法将取消当前登录,并回调 sinaweiboLogInDidCancel。
 */
- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboLogInDidCancel");
}

/**
 *	￼登录失败后,将错误信息回调给此方法。
 */
- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error
{
    NSLog(@"sinaweibo logInDidFailWithError %@", error);
}

/**
 *	操作过程中出错时 sinaweibo 对象将调用此方法,如 accessToken 无效或者过期。用户接收到 此错误信息后应重新登录。
 */
- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error
{
    NSLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    [self removeAuthData];
    [self login];
}

#pragma mark - SinaWeiboRequest Delegate

/**
 *	请求失败时回调此方法。
 *
 *	@param 	request 	SinaWeiboRequest 对象,SDK 中具体用来实现请求的类,应用可根 据 request.url 来判断具体哪个请求失败。
 *	@param 	error 	失败信息。
 */
- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error

{
    if ([request.url hasSuffix:@"users/show.json"])
    {
        
    }
    else if ([request.url hasSuffix:@"statuses/user_timeline.json"])
    {
        
    }
    else if ([request.url hasSuffix:@"statuses/update.json"])
    {
        NSLog(@"Post status failed with error : %@", error);
    }
    else if ([request.url hasSuffix:@"statuses/upload.json"])
    {
        NSLog(@"Post image status failed with error : %@", error);
    }
}

/**
 *	请求完成后回调此方法。
 *
 *	@param 	request 	SinaWeiboRequest 对象,SDK 中具体用来实现请求的类,应用可根 据 request.url 来判断具体哪个请求。
 *	@param 	result 	返回的结果,一般为请求的内容。
 */
- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result

{
    if ([request.url hasSuffix:@"users/show.json"])
    {
        
    }
    else if ([request.url hasSuffix:@"statuses/user_timeline.json"])
    {
    
    }
    else if ([request.url hasSuffix:@"statuses/update.json"])
    {
        NSLog(@"Post status succeed!");
    }
    else if ([request.url hasSuffix:@"statuses/upload.json"])
    {
        NSLog(@"Post image status succeed!");
        cocos2d::CCLuaEngine *LuaEngine = cocos2d::CCLuaEngine::defaultEngine();
        LuaEngine->executeGlobalFunction("weiboPostSucceed");
        
        cocos2d::CCLuaObjcBridge::pushLuaFunctionById(self.callback);
        cocos2d::CCLuaObjcBridge::getStack()->executeFunction(0);
        cocos2d::CCLuaObjcBridge::releaseLuaFunctionById(self.callback);
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                       message:@"新浪微博分享成功" delegate:nil
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end

//
//  WXProxy.m
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-24.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import "WXProxy.h"
#import "WXApiObject.h"
#import "ScreenShot.h"

#include "CCLuaEngine.h"
#include "CCLuaObjcBridge.h"

@interface WXProxy ()

//发送到的位置 WXSceneSession 好友、WXSceneTimeline 朋友圈
@property (nonatomic, assign, readwrite) WXScene scene;
//LUA回调函数
@property (nonatomic, assign) int callback;

//图片发送
- (void)sendImageWX:(NSDictionary *)aDic;
//文本发送
- (void)sendTextWX:(NSDictionary *)aDic;

@end

@implementation WXProxy

+ (id)sharedWXProxy
{
    static WXProxy *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WXProxy alloc]init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.scene = WXSceneSession;
    }
    return self;
}

+ (void)sendWeiboToFriendWithTextAndImage:(NSDictionary *)aDic
{
    if (![WXApi isWXAppInstalled]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"出错了" message:@"您没有安装微信客户端" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    NSString *sendType = [aDic objectForKey:@"type"];
    //发送给好友
    [[WXProxy sharedWXProxy] setScene:WXSceneSession];
    if ([sendType isEqualToString:@"text"]) {
        [[WXProxy sharedWXProxy] sendTextWX:aDic];
    }
    else {
        [[WXProxy sharedWXProxy] sendImageWX:aDic];
    }
}

+ (void)sendWeiboToSceneWithTextAndImage:(NSDictionary *)aDic
{
    if (![WXApi isWXAppInstalled]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"出错了" message:@"您没有安装微信客户端" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    NSString *sendType = [aDic objectForKey:@"type"];
    //发送给朋友圈
    [[WXProxy sharedWXProxy] setScene:WXSceneTimeline];
    if ([sendType isEqualToString:@"text"]) {
        [[WXProxy sharedWXProxy] sendTextWX:aDic];
    }
    else {
        [[WXProxy sharedWXProxy] sendImageWX:aDic];
    }
}

- (void)sendImageWX:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    self.callback = [[aDic objectForKey:@"callback"] intValue];
    int imageID = [[aDic objectForKey:@"imageID"] intValue];
    UIImage *img = [[ScreenShot sharedScreenShot]getScreenshortByID:imageID];
    
    NSData *imageData = UIImageJPEGRepresentation(img, 0.0001);
    
    
    //发送图片内容给微信
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbData:imageData];
    [message setDescription:aText];
    
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = UIImageJPEGRepresentation(img, 1.0);
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = NO;
    req.message = message;
    req.text = aText;
    req.scene = self.scene;
    
    [WXApi sendReq:req];
}

- (void)sendTextWX:(NSDictionary *)aDic
{
    NSString *aText = [aDic objectForKey:@"text"];
    self.callback = [[aDic objectForKey:@"callback"] intValue];
    
    //发送文本内容给微信
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = YES;
    req.text = aText;
    req.scene = self.scene;
    
    [WXApi sendReq:req];
}

#pragma mark - WXApiDelegate Methodes

- (void)onResp:(BaseResp *)resp
{
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        int returnCode = resp.errCode;
        if (returnCode == WXSuccess) {
            
            NSLog(@"send WX succeed!");
            
            cocos2d::CCLuaEngine *LuaEngine = cocos2d::CCLuaEngine::defaultEngine();
            LuaEngine->executeGlobalFunction("weiboPostSucceed");

            cocos2d::CCLuaObjcBridge::pushLuaFunctionById(self.callback);
            cocos2d::CCLuaObjcBridge::getStack()->executeFunction(0);
            cocos2d::CCLuaObjcBridge::releaseLuaFunctionById(self.callback);
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                           message:@"微信分享成功" delegate:nil
                                                 cancelButtonTitle:@"确定"
                                                 otherButtonTitles:nil];
            [alert show];
            [alert release];
            
        } else {
            
            NSLog(@"send WX failed!error:%@", resp.errStr);
            
        }
    }
}

@end

//
//  SinaWeiboProxy.h
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-20.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SinaWeibo.h"
#import "SinaWeiboRequest.h"

#define kAppKey             @"900372112"
#define kAppSecret          @"3e66b7d24c08ba2680c10453081a294d"
#define kAppRedirectURI     @"https://api.weibo.com/oauth2/default.html"

@interface SinaWeiboProxy : NSObject<SinaWeiboDelegate, SinaWeiboRequestDelegate>

@property (nonatomic, retain) SinaWeibo *sinaWeibo;

+ (id)sharedSinaWeiboProxy;

+ (void)sendWeiboWithText:(NSDictionary *)aDic;
+ (void)sendWeiboWithTextAndImage:(NSDictionary *)aDic;

- (void)sendWeiboWithText:(NSString *)aText andDelegate:(id<SinaWeiboRequestDelegate>)aDelegate;
- (void)sendWeibowithtext:(NSString *)aText andImage:(UIImage *)aImage andDelegate:(id<SinaWeiboRequestDelegate>)aDelegate;


/**
 *	登录操作。SinaWeibo 对象根据具体环境进行 sso 登录或是浏览器登录。
 */
- (void)login;

/**
 *	登出操作。
 */
+ (void)logout;

/**
 *	应用从后台唤醒到前台后,调用此方法,方法中判断若正在登录过程中将退出当前登录。
 */
- (void)applicationDidBecomeActive;

/**
 *	接收 SSO 登录回调信息,并解析,属于 login 的中间一步。应用需要在 openURL 时调用此方 法以完成 sso 登录的回调过程。修改 info.plist 文件 URL types 项为自己的 sso 回调地址,默认格式为 sinaweibosso.your_app_key(此处替换 your_app_key 为自己的 app key)。
 *
 *	@param 	aURL 	官方客户端回调给应用时传回的参数，包含认证信息等。
 *
 *	@return	是否成功。
 */
- (BOOL)handleOpenURL:(NSURL *)aURL;

/**
 *	判断登录状态是否有效,即已登录且未过期
 *
 *	@return	是否有效。
 */
- (BOOL)isAuthValid;

@end

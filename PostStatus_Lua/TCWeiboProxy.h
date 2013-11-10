//
//  TCWeiboProxy.h
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-23.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCWBEngine.h"

@interface TCWeiboProxy : NSObject

@property (nonatomic, retain) TCWBEngine *TCWeibo;

+ (id)sharedTCWeiboProxy;

+ (void)sendWeiboWithText:(NSDictionary *)aDic;
+ (void)sendWeiboWithTextAndImage:(NSDictionary *)aDic;

- (void)sendWeiboWithText:(NSString *)aText;
- (void)sendWeibowithtext:(NSString *)aText andImage:(UIImage *)aImage;

/**
 *	登录操作。TCWBEngine 对象根据具体环境进行 sso 登录或是浏览器登录。
 */
- (void)login;

/**
 *	登出操作。
 */
+ (void)logout;

@end

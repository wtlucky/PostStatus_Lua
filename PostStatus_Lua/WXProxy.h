//
//  WXProxy.h
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-24.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"

@interface WXProxy : NSObject<WXApiDelegate>

+ (id)sharedWXProxy;


/**
 *	分享给好友，分享内容的方式由Dictionary中的type字段来表示
 *
 *	@param 	aDic 	包含有分享相关数据的字典，text=分享的文字，type=分享的内容（text为文本，image为图片），callback=LUA中的回调方法
 */
+ (void)sendWeiboToFriendWithTextAndImage:(NSDictionary *)aDic;

/**
 *	分享给朋友圈，分享内容的方式由Dictionary中的type字段来表示
 *
 *	@param 	aDic 	包含有分享相关数据的字典，text=分享的文字，type=分享的内容（text为文本，image为图片），callback=LUA中的回调方法
 */
+ (void)sendWeiboToSceneWithTextAndImage:(NSDictionary *)aDic;

@end

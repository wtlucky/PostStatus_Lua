//
//  ScreenShot.h
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-22.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScreenShot : NSObject

@property (nonatomic, retain) NSMutableDictionary *imageStore;

+ (id)sharedScreenShot;

//通过LUA调用方法
+ (void)createScreenshotWithID:(NSDictionary *)aDic;
+ (void)removeScreenshotByID:(NSDictionary *)aDic;

- (UIImage *)getScreenshortByID:(int)aID;

@end

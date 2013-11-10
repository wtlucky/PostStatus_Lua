//
//  ScreenShot.m
//  SinaWeiboProxy
//
//  Created by wtlucky on 13-7-22.
//  Copyright (c) 2013年 RenRen Games. All rights reserved.
//

#import "ScreenShot.h"
#import <QuartzCore/QuartzCore.h>

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "CCLuaObjcBridge.h"

@interface ScreenShot ()

- (UIImage *)getGLScreenshot;
- (UIImage *)getUIScreenshot;
- (UIImage *)cocos2dxGetScreenshot;
- (UIImage *)imageFromCCImage:(cocos2d::CCImage *)ccImage;
- (UIImage *)scaleFromImage:(UIImage *)image toSize:(CGSize)size;
- (int)generateRandomID;

@end

@implementation ScreenShot

@synthesize imageStore = _imageStore;

+ (id)sharedScreenShot
{
    static ScreenShot *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ScreenShot alloc]init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _imageStore = [[NSMutableDictionary alloc]initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    [_imageStore release];
    [super dealloc];
}

#pragma mark - Self Methods

+ (void)createScreenshotWithID:(NSDictionary *)aDic
{
    UIImage *image = [[ScreenShot sharedScreenShot] cocos2dxGetScreenshot];
    int randomID = [[ScreenShot sharedScreenShot] generateRandomID];
    NSNumber *ID = [NSNumber numberWithInt:randomID];
    [[[ScreenShot sharedScreenShot] imageStore] setObject:image forKey:ID];
    
    int callback = [[aDic objectForKey:@"callback"] intValue];
    
    cocos2d::CCLuaObjcBridge::pushLuaFunctionById(callback);
    cocos2d::CCLuaObjcBridge::getStack()->pushInt(randomID);
    cocos2d::CCLuaObjcBridge::getStack()->executeFunction(1);
    cocos2d::CCLuaObjcBridge::releaseLuaFunctionById(callback);
    
}

+ (void)removeScreenshotByID:(NSDictionary *)aDic

{
    NSNumber *randomID = [aDic objectForKey:@"imageID"];
    [[[ScreenShot sharedScreenShot] imageStore]removeObjectForKey:randomID];
    cocos2d::CCLog("remove screenshot succeed! imageID = %d", [randomID intValue]);
}

- (UIImage *)getScreenshortByID:(int)aID
{
    NSNumber *ID = [NSNumber numberWithInt:aID];
    return (UIImage *)[self.imageStore objectForKey:ID];
}

#pragma mark - Private Methods

- (UIImage *)getGLScreenshot
{
    CGRect windowRect = [[UIScreen mainScreen] bounds];
    NSInteger screenWidth = windowRect.size.height;
    NSInteger screenHeight = windowRect.size.width;
    
    NSInteger myDataLength = screenWidth * screenHeight * 4;
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, screenWidth, screenHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y <screenHeight; y++)
    {
        for(int x = 0; x <screenWidth * 4; x++)
        {
            buffer2[(screenHeight - 1 - y) * screenWidth * 4 + x] = buffer[y * 4 * screenWidth + x];
        }
    }
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              buffer2, myDataLength, NULL);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * screenWidth;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(screenWidth, screenHeight, bitsPerComponent,
                                        bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider,
                                        NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    
    // release memory
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    free(buffer);
    
    return myImage;
}

- (UIImage *)getUIScreenshot
{
        CGSize imageSize = [[UIScreen mainScreen] bounds].size;
        if (NULL != UIGraphicsBeginImageContextWithOptions) {
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        }
        else
        {
            UIGraphicsBeginImageContext(imageSize);
        }
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        for (UIWindow * window in [[UIApplication sharedApplication] windows]) {
            if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
                CGContextSaveGState(context);
                CGContextTranslateCTM(context, [window center].x, [window center].y);
                CGContextConcatCTM(context, [window transform]);
                CGContextTranslateCTM(context, -[window bounds].size.width*[[window layer] anchorPoint].x, -[window bounds].size.height*[[window layer] anchorPoint].y);
                [[window layer] renderInContext:context];
                
                CGContextRestoreGState(context);
            }
        }
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        return image;
}

- (UIImage *)cocos2dxGetScreenshot
{
    cocos2d::CCSize winSize = cocos2d::CCDirector::sharedDirector()->getWinSize();
    cocos2d::CCRenderTexture *renderTexture = cocos2d::CCRenderTexture::create(winSize.width, winSize.height);
    renderTexture->begin();
    cocos2d::CCDirector::sharedDirector()->getRunningScene()->visit();
    renderTexture->end();
    cocos2d::CCImage *ccImage = renderTexture->newCCImage(true);
    
    UIImage *img = [self imageFromCCImage:ccImage];
    UIImage *image = [self scaleFromImage:img toSize:CGSizeMake(480, 320)];
    
    return image;
}

- (UIImage *)imageFromCCImage:(cocos2d::CCImage *)ccImage
{
    NSUInteger bytesPerPixel = 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              ccImage->getData(),
                                                              ccImage->getDataLen() * bytesPerPixel,
                                                              NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    NSUInteger scanWidth = ccImage->getWidth() * bytesPerPixel;
    CGImageRef imageRef = CGImageCreate(ccImage->getWidth(),
                                        ccImage->getHeight(),
                                        8,
                                        bytesPerPixel * 8,
                                        scanWidth,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    
    return image;
}

- (UIImage *)scaleFromImage:(UIImage *)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (int)generateRandomID
{
    int randomID = arc4random() % 100;
    
    NSNumber *num = [NSNumber numberWithInt:randomID];
    while ([self.imageStore objectForKey:num]) {
        randomID = arc4random() % 100;
        num = [NSNumber numberWithInt:randomID];
    }
    
    return randomID;
}

@end

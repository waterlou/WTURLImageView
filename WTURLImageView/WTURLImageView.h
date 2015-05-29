//
//  WTURLImageView.h
//  WTURLImageViewDemo
//
//  Created by Water Lou on 14/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+WTExtension.h"

// default fillType, will not resize image, user can set aspect ratio of the image using view contentMode
#define UIImageResizeFillTypeNoResize ((UIImageResizeFillType)(16))

typedef NS_OPTIONS(NSUInteger, WTURLImageViewOptions) {
    WTURLImageViewOptionDontUseDiskCache            = 1 << 0,  // dont use disk cache
    WTURLImageViewOptionDontUseConnectionCache      = 1 << 1,  // dont use system wide cache
    WTURLImageViewOptionDontUseCache                = (WTURLImageViewOptionDontUseDiskCache | WTURLImageViewOptionDontUseConnectionCache),
    WTURLImageViewOptionDontSaveDiskCache           = 1 << 2, // (DEPRECATED) dont save to disk cache
    WTURLImageViewOptionShowActivityIndicator       = 1 << 3, // show activity indicator when loading
    WTURLImageViewOptionAnimateEvenCache            = 1 << 4, // by default no animation for cache image, force if set this
    WTURLImageViewOptionDontClearImageBeforeLoading = 1 << 5, // will not clear old image when loading
    // load disk image in background, sometimes when you load image in table view cell, loading image
    // in foreground will also make the scrolling not smooth, set this to load disk cache in background
    WTURLImageViewOptionsLoadDiskCacheInBackground  = 1 << 6, // (DEPRECATED), always do in background now

    // transition effects
    WTURLImageViewOptionTransitionNone              = 0 << 20, // default
    WTURLImageViewOptionTransitionCrossDissolve     = 1 << 20,
    
    WTURLImageViewOptionTransitionScaleDissolve     = 2 << 20,
    WTURLImageViewOptionTransitionPerspectiveDissolve  = 3 << 20,
    
    WTURLImageViewOptionTransitionSlideInTop        = 4 << 20,
    WTURLImageViewOptionTransitionSlideInLeft       = 5 << 20,
    WTURLImageViewOptionTransitionSlideInBottom     = 6 << 20,
    WTURLImageViewOptionTransitionSlideInRight      = 7 << 20,
    
    WTURLImageViewOptionTransitionFlipFromLeft      = 8 << 20,
    WTURLImageViewOptionTransitionFlipFromRight     = 9 << 20,

    WTURLImageViewOptionTransitionRipple            = 10 << 20,
    WTURLImageViewOptionTransitionCubeFromTop       = 11 << 20,
    WTURLImageViewOptionTransitionCubeFromLeft      = 12 << 20,
    WTURLImageViewOptionTransitionCubeFromBottom    = 13 << 20,
    WTURLImageViewOptionTransitionCubeFromRight     = 14 << 20,
    
};

@class WTURLImageView;
@class WTURLImageViewPreset;

// with userInteraction is set in the view, user can receive click event
@protocol WTURLImageViewDelegate <NSObject>
- (void) URLImageViewDidClicked : (WTURLImageView*)imageView;
@end


@interface UIImageView(WTURLImageView)

- (void) wt_makeTransition : (UIImage *)image effect : (WTURLImageViewOptions) effect;

@end

@interface WTURLImageView : UIImageView

- (void)setURLRequest:(NSURLRequest *)urlRequest
             fillType:(UIImageResizeFillType)fillType
              options:(WTURLImageViewOptions)options
     placeholderImage:(UIImage *)placeholderImage
          failedImage:(UIImage *)failedImage
diskCacheTimeoutInterval:(NSTimeInterval)diskCacheTimeInterval  // set to 0 will use default one
              success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
              failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

- (void)setURL:(NSURL *)url
      fillType:(UIImageResizeFillType)fillType
       options:(WTURLImageViewOptions)options
placeholderImage:(UIImage *)placeholderImage
   failedImage:(UIImage *)failedImage
diskCacheTimeoutInterval:(NSTimeInterval)diskCacheTimeInterval;  // set to 0 will use default one

- (void) setURL:(NSURL*)url;
- (void) setURL:(NSURL*)url withPreset:(WTURLImageViewPreset*) preset;
- (void) reloadWithPreset : (WTURLImageViewPreset*)preset;

@property (nonatomic, weak) id <WTURLImageViewDelegate> delegate;
@property (nonatomic, copy) NSString *urlString;    // will store this only when WTURLImageViewOptionRecordURLString is set

- (UIActivityIndicatorView *) activityIndicator;

/* clear all cache, for invalidate cache */
+ (void) clearAllCache;

+ (UIImage*) getCachedImageByUrlString : (NSString*) urlString;

/* limit max number of download concurrently */
+ (void) setMaxConcurrentDownload : (NSInteger) c;

/* set the default expiry interval for disk cache */
+ (void) setDiskCacheDefaultTimeOutInterval : (NSTimeInterval) timeout;

@end

@interface WTURLImageViewPreset : NSObject

+ (WTURLImageViewPreset*) defaultPreset;

@property (nonatomic, assign) UIImageResizeFillType fillType;
@property (nonatomic, assign) WTURLImageViewOptions options;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *failedImage;
@property (nonatomic, assign) NSTimeInterval diskCacheTimeInterval;

@end

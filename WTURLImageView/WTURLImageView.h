//
//  WTURLImageView.h
//  WTURLImageViewDemo
//
//  Created by Water Lou on 14/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+WTExtension.h"

#define UIImageResizeFillTypeIgnoreNoResize (99)

typedef NS_OPTIONS(NSUInteger, WTURLImageViewOptions) {
    WTURLImageViewOptionDontUseCache = 1 << 0,  // dont use disk cache
    WTURLImageViewOptionDontSaveCache = 1 << 2, // dont save to disk cache
    WTURLImageViewOptionShowActivityIndicator = 1 << 3, // show activity indicator when loading
    WTURLImageViewOptionAnimateEvenCache = 1 << 4,      // by default no animation for cache image, force if set this
    WTURLImageViewOptionDontClearImageBeforeLoading = 1 << 5,    // will not clear old image when loading
    WTURLImageViewOptionRecordURLString           = 1 << 6,    // set this flag so that user can get the url of the image
    // transition effects
    WTURLImageViewOptionTransitionNone            = 0 << 20, // default
    WTURLImageViewOptionTransitionCrossDissolve   = 1 << 20,
    WTURLImageViewOptionTransitionScaleDissolve   = 2 << 20,
    WTURLImageViewOptionTransitionPerspectiveDissolve  = 3 << 20,
    WTURLImageViewOptionTransitionSlideInTop      = 4 << 20,
    WTURLImageViewOptionTransitionSlideInLeft     = 5 << 20,
    WTURLImageViewOptionTransitionSlideInBottom   = 6 << 20,
    WTURLImageViewOptionTransitionSlideInRight    = 7 << 20,
};

@class WTURLImageView;
@class WTURLImageViewPreset;

// with userInteraction is set in the view, user can receive click event
@protocol WTURLImageViewDelegate <NSObject>
- (void) URLImageViewDidClicked : (WTURLImageView*)imageView;
@end


@interface WTURLImageView : UIImageView

- (void)setURLRequest:(NSURLRequest *)urlRequest
             fillType:(UIImageResizeFillType)fillType
              options:(WTURLImageViewOptions)options
     placeholderImage:(UIImage *)placeholderImage
          failedImage:(UIImage *)failedImage
              success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
              failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

- (void)setURL:(NSURL *)url
      fillType:(UIImageResizeFillType)fillType
       options:(WTURLImageViewOptions)options
placeholderImage:(UIImage *)placeholderImage
   failedImage:(UIImage *)failedImage;

- (void) setURL:(NSURL*)url;
- (void) setURL:(NSURL*)url withPreset:(WTURLImageViewPreset*) preset;
- (void) reloadWithPreset : (WTURLImageViewPreset*)preset;

@property (nonatomic, weak) id <WTURLImageViewDelegate> delegate;
@property (nonatomic, copy) NSString *urlString;    // will store this only when WTURLImageViewOptionRecordURLString is set

- (UIActivityIndicatorView *) activityIndicator;

/* clear all cache, for invalidate cache */
+ (void) clearAllCache;

/* limit max number of download concurrently */
+ (void) setMaxConcurrentDownload : (NSInteger) c;

@end

@interface WTURLImageViewPreset : NSObject

+ (WTURLImageViewPreset*) defaultPreset;

@property (nonatomic, assign) UIImageResizeFillType fillType;
@property (nonatomic, assign) WTURLImageViewOptions options;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *failedImage;

@end

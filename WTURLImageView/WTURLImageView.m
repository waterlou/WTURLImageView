//
//  WTURLImageView.m
//  WTURLImageViewDemo
//
//  Created by Water Lou on 14/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WTURLImageView.h"
#import "AFNetworking.h"
#import "GVCache.h"

#define kAIVTag 2222    // activity indicator tag

@interface WTURLImageView()

@property (nonatomic, strong) AFHTTPRequestOperation *requestOperation;
@property (nonatomic, assign) BOOL clipsToBoundsSave;   // for restore clipToBound for some transition effect
@end

@implementation WTURLImageView

/* resize image if needed */
- (UIImage*) resizedImage : (UIImage*)image fillType : (UIImageResizeFillType) fillType {
    if (CGSizeEqualToSize(image.size, self.bounds.size)) {
        // no need to resize
        return image;
    }
    if (fillType!=UIImageResizeFillTypeIgnoreNoResize)
        return [image resize:self.bounds.size fillType:fillType topLeftCorner:0 topRightCorner:0 bottomRightCorner:0 bottomLeftCorner:0 quality:kCGInterpolationDefault];
    else
        return image;
}

+ (GVCache *) sharedImageCache {
    static GVCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"WTLURLImageView"];
        sharedCache = [[GVCache alloc] initWithCacheDirectory:path];
        [sharedCache setDefaultTimeoutInterval: 86400];
    });
    
    return sharedCache;
}

+ (NSOperationQueue *) sharedImageRequestOperationQueue {
    static NSOperationQueue *imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    
    return imageRequestOperationQueue;
}

- (void)cancelImageRequestOperation {
    [self.requestOperation cancel];
    self.requestOperation = nil;
}

- (void) dealloc
{
    [self cancelImageRequestOperation];
}

- (NSString *)sanitizeFileNameString:(NSString *)fileName {
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

/* create activityIndicator on demand */
- (UIActivityIndicatorView *) activityIndicator
{
    UIActivityIndicatorView *aiv = (UIActivityIndicatorView*)[self viewWithTag: kAIVTag];
    if (aiv) return aiv;
    aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    aiv.tag = kAIVTag;
    aiv.hidesWhenStopped = YES;
    aiv.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    aiv.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview: aiv];
    return aiv;
}

- (void) beginLoadImage : (WTURLImageViewOptions) options placeHolderImage : (UIImage*) placeHolderImage
{
    if (!(options & WTURLImageViewOptionDontClearImageBeforeLoading) || self.image==nil)
        self.image = placeHolderImage;
    if (options & WTURLImageViewOptionShowActivityIndicator) {
        UIActivityIndicatorView *aiv = [self activityIndicator];
        [self bringSubviewToFront: aiv];
        [aiv startAnimating];
    }
}

- (void) endLoadImage : (UIImage*) image
            fromCache : (BOOL) fromCache
             fillType : (UIImageResizeFillType) fillType
              options : (WTURLImageViewOptions)options
          failedImage : (UIImage*) failedImage
{
    if (options & WTURLImageViewOptionShowActivityIndicator) {
        UIActivityIndicatorView *aiv = [self activityIndicator];
        [aiv stopAnimating];
    }

    if (image==nil)
    {
        // no image failed
        if (failedImage) self.image = failedImage;
        return;
    }
    
    UIViewAnimationOptions effect = options & (0x0000f<<20);
    // scale image
    image = [self resizedImage:image fillType:fillType];
    if ((fromCache && !(options & WTURLImageViewOptionAnimateEvenCache)) || effect==UIViewAnimationOptionTransitionNone) {
        self.image = image;
    }
    else {
        // show image with animation
        [self makeTransition: image effect:effect];
    }
}

- (void)setURLRequest:(NSURLRequest *)urlRequest
             fillType:(UIImageResizeFillType)fillType
              options:(WTURLImageViewOptions)options
     placeholderImage:(UIImage *)placeholderImage
          failedImage:(UIImage *)failedImage
              success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
              failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelImageRequestOperation];
    
    NSString *cacheKey = [self sanitizeFileNameString: urlRequest.URL.absoluteString];
    
    if (!(options & WTURLImageViewOptionDontUseCache)) {
        UIImage *cachedImage = [[[self class] sharedImageCache] imageForKey:cacheKey];
        if (cachedImage) {
            if (options & WTURLImageViewOptionAnimateEvenCache) {
                [self beginLoadImage:options placeHolderImage:placeholderImage];
                [self endLoadImage:cachedImage fromCache:YES fillType:fillType options:options failedImage:failedImage];

            }
            else {
                [self endLoadImage:cachedImage fromCache:YES fillType:fillType options:options failedImage:failedImage];
            }
            if (success) success(nil, nil, cachedImage);
            self.requestOperation = nil;
            return;
        }
    }
    
    [self beginLoadImage:options placeHolderImage:placeholderImage];
    
    AFImageRequestOperation *requestOperation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([[urlRequest URL] isEqual:[[self.requestOperation request] URL]]) {
            [self endLoadImage:responseObject fromCache:NO fillType:fillType options:options failedImage:failedImage];
            if (success) success(operation.request, operation.response, responseObject);
            if (!(options & WTURLImageViewOptionDontSaveCache)) {
                [[[self class] sharedImageCache] setImage:responseObject forKey:cacheKey];
            }
            self.requestOperation = nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([[urlRequest URL] isEqual:[[self.requestOperation request] URL]]) {
            [self endLoadImage:nil fromCache:NO fillType:fillType options:options failedImage:failedImage];
            if (failure) failure(operation.request, operation.response, error);
            self.requestOperation = nil;
        }
    }];
    if (options & WTURLImageViewOptionDontUseCache) {
        [requestOperation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
            // we also disable cache in afnetworking
            return nil;
        }];
    }
    
    self.requestOperation = requestOperation;
    [[[self class] sharedImageRequestOperationQueue] addOperation:self.requestOperation];
}

- (void)setURL:(NSURL *)url
      fillType:(UIImageResizeFillType)fillType
       options:(WTURLImageViewOptions)options
placeholderImage:(UIImage *)placeholderImage
   failedImage:(UIImage *)failedImage
{
    [self setURLRequest:[NSURLRequest requestWithURL:url] fillType:fillType options:options placeholderImage:placeholderImage failedImage:failedImage success:nil failure:nil];
}

- (void) setURL:(NSURL*)url
{
    [self setURL:url
        fillType:UIImageResizeFillTypeFillIn
         options:0
placeholderImage:nil
     failedImage:nil];
}

- (void) setURL:(NSURL*)url withPreset:(WTURLImageViewPreset*) preset
{
    [self setURL:url
        fillType:preset.fillType
         options:preset.options
placeholderImage:preset.placeholderImage
     failedImage:preset.failedImage];
}


#pragma mark touch event

- (void) setHighlighted:(BOOL)highlighted {
    if (highlighted) self.alpha = 0.5;
    else self.alpha = 1.0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    [self setHighlighted: CGRectContainsPoint(self.bounds,pt)];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted: NO];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted: NO];
    
	UITouch *touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    BOOL clicked = CGRectContainsPoint(self.bounds,pt);
    
    if (clicked && [_delegate respondsToSelector : @selector(URLImageViewDidClicked:)]) {
        [_delegate URLImageViewDidClicked : self];
    }
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    [self setHighlighted: CGRectContainsPoint(self.bounds,pt)];
}

#pragma transitions

- (void) makeTransition : (UIImage *)image effect : (UIViewAnimationOptions) effect
{
    CALayer *layer = [CALayer layer];
    layer.contents = (__bridge id)([image normalizeOrientation].CGImage);
    layer.frame = self.bounds;
    
    switch (effect) {
        case WTURLImageViewOptionTransitionCrossDissolve:
        case WTURLImageViewOptionTransitionScaleDissolve:
        case WTURLImageViewOptionTransitionPerspectiveDissolve:
        {
            switch (effect) {
                default:
                case WTURLImageViewOptionTransitionCrossDissolve:
                    break;
                case WTURLImageViewOptionTransitionScaleDissolve:
                    layer.affineTransform = CGAffineTransformMakeScale(1.5, 1.5); break;
                case WTURLImageViewOptionTransitionPerspectiveDissolve:
                {
                    CATransform3D t = CATransform3DIdentity;
                    t.m34 = 1.0/-450.0;
                    t = CATransform3DScale(t, 1.2, 1.2, 1);
                    t = CATransform3DRotate(t, 45.0f*M_PI/180.0f, 1, 0, 0);
                    t = CATransform3DTranslate(t, 0, self.bounds.size.height * 0.1, 0);
                    layer.transform = t;
                } break;
            }
            layer.opacity = 0.0f;
            [self.layer addSublayer: layer];
            [CATransaction flush];
            [CATransaction begin];
            [CATransaction setAnimationDuration: 0.45f];
            [CATransaction setCompletionBlock: ^ {
                [layer removeFromSuperlayer];
                self.image = image;
            }];
            layer.opacity = 1.0f;
            layer.affineTransform = CGAffineTransformIdentity;
            [CATransaction commit];

        } break;
        case WTURLImageViewOptionTransitionSlideInTop:
        case WTURLImageViewOptionTransitionSlideInLeft:
        case WTURLImageViewOptionTransitionSlideInBottom:
        case WTURLImageViewOptionTransitionSlideInRight:
        {
            // have sublayer means animation in progress
            NSArray *sublayer = self.layer.sublayers;
            BOOL clipsToBoundsSave = NO;
            NSLog(@"layers %d", sublayer.count);
            if (sublayer.count==1)
                self.clipsToBoundsSave = self.clipsToBounds;
            self.clipsToBounds = YES;
            switch (effect) {
                default:
                case WTURLImageViewOptionTransitionSlideInTop:
                    layer.affineTransform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height); break;
                case WTURLImageViewOptionTransitionSlideInLeft:
                    layer.affineTransform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0); break;
                case WTURLImageViewOptionTransitionSlideInBottom:
                    layer.affineTransform = CGAffineTransformMakeTranslation(0, self.bounds.size.height); break;
                case WTURLImageViewOptionTransitionSlideInRight:
                    layer.affineTransform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0); break;
                    break;
            }
            [self.layer addSublayer: layer];
            [CATransaction flush];
            [CATransaction begin];
            [CATransaction setAnimationDuration: 0.45f];
            [CATransaction setCompletionBlock: ^ {
                [layer removeFromSuperlayer];
                self.image = image;
                NSArray *sublayer = self.layer.sublayers;
                if (sublayer.count==1)
                    self.clipsToBounds = clipsToBoundsSave;
            }];
            layer.affineTransform = CGAffineTransformIdentity;
            [CATransaction commit];
        } break;
        default:
            break;
    }
}

#pragma global helper

+ (void) setMaxConcurrentDownload : (NSInteger) c
{
    [[[self class] sharedImageRequestOperationQueue] setMaxConcurrentOperationCount: c];
}

+ (void) clearAllCache
{
    [[[self class] sharedImageCache] clearCache];
}


@end

@implementation WTURLImageViewPreset

+ (WTURLImageViewPreset*) defaultPreset
{
    static WTURLImageViewPreset *defaultPreset = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultPreset = [[WTURLImageViewPreset alloc] init];
    });
    return defaultPreset;
}

@end
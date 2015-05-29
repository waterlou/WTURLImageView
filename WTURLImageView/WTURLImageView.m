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
#import "PINCache.h"


#define kAIVTag 2222    // activity indicator tag

static NSTimeInterval defaultTimeoutInterval = 60;  // default time out at 60 seconds
static NSTimeInterval defaultDiskCacheTimeoutInterval = 86400;

static CGFloat transitionDuration = 0.45f;

@interface WTURLImageView()

@property (nonatomic, strong) AFHTTPRequestOperation *requestOperation;

@end

@implementation WTURLImageView

/* resize image if needed */
- (UIImage*) resizedImage : (UIImage*)image fillType : (UIImageResizeFillType) fillType {
    if (CGSizeEqualToSize(image.size, self.bounds.size)) {
        // no need to resize
        return image;
    }
    if (fillType!=(UIImageResizeFillType)UIImageResizeFillTypeNoResize)
        return [image wt_resize:self.bounds.size fillType:fillType topLeftCorner:0 topRightCorner:0 bottomRightCorner:0 bottomLeftCorner:0 quality:kCGInterpolationDefault];
    else
        return image;
}

+ (PINCache *)sharedCache {
    static PINCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[PINCache alloc] initWithName:@"WTURLImageView"];
        sharedCache.memoryCache.costLimit = 32; // max number of image cached in memory
        sharedCache.memoryCache.ageLimit = defaultDiskCacheTimeoutInterval;
        sharedCache.diskCache.ageLimit = defaultDiskCacheTimeoutInterval;
    });
    return sharedCache;
}

+ (UIImage*) getCachedImageByUrlString : (NSString*) urlString
{
    NSString *cacheKey = [[self class] sanitizeFileNameString: urlString];
    return [[[self class] sharedCache] objectForKey:cacheKey];
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

+ (NSString *)sanitizeFileNameString:(NSString *)fileName {
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
    if (!(options & WTURLImageViewOptionDontClearImageBeforeLoading) || self.image==nil) {
        [self.layer removeAllAnimations];   // cancel all animation before setting placeholder
        self.image = placeHolderImage;
    }
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
    
    WTURLImageViewOptions effect = options & (0x0000f<<20);
    // scale image
    image = [self resizedImage:image fillType:fillType];
    if ((fromCache && !(options & WTURLImageViewOptionAnimateEvenCache)) || effect==UIViewAnimationOptionTransitionNone) {
        self.image = image;
    }
    else {
        // show image with animation
        [self wt_makeTransition: image effect:effect];
    }
}

- (void)createRequestOperation:(NSURLRequest *)urlRequest
                      cacheKey:(NSString*)cacheKey
                      fillType:(UIImageResizeFillType)fillType
                       options:(WTURLImageViewOptions)options
              placeholderImage:(UIImage *)placeholderImage
                   failedImage:(UIImage *)failedImage
      diskCacheTimeoutInterval:(NSTimeInterval)diskCacheTimeInterval  // set to 0 will use default one
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([[urlRequest URL] isEqual:[[self.requestOperation request] URL]]) {
            [self endLoadImage:responseObject fromCache:NO fillType:fillType options:options failedImage:failedImage];
            if (success) success(operation.request, operation.response, responseObject);
            if (!(options & WTURLImageViewOptionDontUseDiskCache)) {
                PINCache *diskCache = [[self class] sharedCache];
                [diskCache setObject:responseObject forKey:cacheKey];
            }
            self.requestOperation = nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error.code==NSURLErrorCancelled) {
            return; // manual cancel
        }
        if ([[urlRequest URL] isEqual:[[self.requestOperation request] URL]]) {
            [self endLoadImage:nil fromCache:NO fillType:fillType options:options failedImage:failedImage];
            if (failure) failure(operation.request, operation.response, error);
            self.requestOperation = nil;
        }
    }];
    // network level cache
    if (options & WTURLImageViewOptionDontUseConnectionCache) {
        [requestOperation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
            // we also disable cache in afnetworking
            return nil;
        }];
    }
    
    self.requestOperation = requestOperation;
    [[[self class] sharedImageRequestOperationQueue] addOperation:self.requestOperation];
}

- (void)setURLRequest:(NSURLRequest *)urlRequest
             fillType:(UIImageResizeFillType)fillType
              options:(WTURLImageViewOptions)options
     placeholderImage:(UIImage *)placeholderImage
          failedImage:(UIImage *)failedImage
diskCacheTimeoutInterval:(NSTimeInterval)diskCacheTimeInterval  // set to 0 will use default one
              success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
              failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelImageRequestOperation];
    
    self.urlString = urlRequest.URL.absoluteString; // record urlstring for reload
    NSString *cacheKey = [[self class] sanitizeFileNameString: self.urlString];

    [self beginLoadImage:options placeHolderImage:placeholderImage];
    if (!(options & WTURLImageViewOptionDontUseDiskCache)) {
        PINCache *cache = [[self class] sharedCache];
        [cache objectForKey:cacheKey block:^(PINCache *cache, NSString *key, id object) {
            UIImage *cachedImage = (UIImage *)object;
            if (cachedImage) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [self endLoadImage:cachedImage fromCache:YES fillType:fillType options:options failedImage:failedImage];
                    if (success) success(nil, nil, cachedImage);
                    self.requestOperation = nil;
                });
            }
            else {
                [self createRequestOperation:urlRequest cacheKey:cacheKey fillType:fillType options:options placeholderImage:placeholderImage failedImage:failedImage diskCacheTimeoutInterval:diskCacheTimeInterval success:success failure:failure];
            }
        }];
    }
    else {
        [self createRequestOperation:urlRequest cacheKey:cacheKey fillType:fillType options:options placeholderImage:placeholderImage failedImage:failedImage diskCacheTimeoutInterval:diskCacheTimeInterval success:success failure:failure];
    }
}

- (void)setURL:(NSURL *)url
      fillType:(UIImageResizeFillType)fillType
       options:(WTURLImageViewOptions)options
placeholderImage:(UIImage *)placeholderImage
   failedImage:(UIImage *)failedImage
diskCacheTimeoutInterval:(NSTimeInterval)diskCacheTimeInterval  // set to 0 will use default one
{
    NSURLRequestCachePolicy cachePolicy = (options & WTURLImageViewOptionDontUseConnectionCache) ? NSURLRequestReloadIgnoringCacheData : NSURLRequestUseProtocolCachePolicy;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url cachePolicy:cachePolicy timeoutInterval:defaultTimeoutInterval];
    [self setURLRequest:request fillType:fillType options:options placeholderImage:placeholderImage failedImage:failedImage diskCacheTimeoutInterval:diskCacheTimeInterval success:nil failure:nil];
}

- (void) setURL:(NSURL*)url
{
    [self setURL:url withPreset:[WTURLImageViewPreset defaultPreset]];
}

- (void) setURL:(NSURL*)url withPreset:(WTURLImageViewPreset*) preset
{
    [self setURL:url
        fillType:preset.fillType
         options:preset.options
placeholderImage:preset.placeholderImage
     failedImage:preset.failedImage
     diskCacheTimeoutInterval:preset.diskCacheTimeInterval];
}

- (void) reloadWithPreset : (WTURLImageViewPreset*)preset
{
    [self setURL:[NSURL URLWithString:self.urlString]
        fillType:preset.fillType
         options:(preset.options & ~WTURLImageViewOptionDontUseCache)   // mask out cache
placeholderImage:preset.placeholderImage
     failedImage:preset.failedImage
diskCacheTimeoutInterval:preset.diskCacheTimeInterval];
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

#pragma global helper

+ (void) setMaxConcurrentDownload : (NSInteger) c
{
    [[[self class] sharedImageRequestOperationQueue] setMaxConcurrentOperationCount: c];
}

+ (void) clearAllCache
{
    [[[self class] sharedCache] removeAllObjects];
}

+ (void) setDiskCacheDefaultTimeOutInterval : (NSTimeInterval) timeout
{
    [[[self class] sharedCache].memoryCache setAgeLimit:timeout];
    [[[self class] sharedCache].diskCache setAgeLimit:timeout];
}

@end


@implementation UIImageView(WTURLImageView)

#pragma transitions

- (CALayer*) wt_layerFromImage : (UIImage*) image
{
    CALayer *layer = [CALayer layer];
    layer.contents = (__bridge id)([image wt_normalizeOrientation].CGImage);
    layer.frame = self.bounds;
    return layer;
}

- (void) wt_makeTransition : (UIImage *)image effect : (WTURLImageViewOptions) effect
{
    switch (effect) {
            // OS-provided CALayer CATranstion type transition animation
        case WTURLImageViewOptionTransitionCrossDissolve:
        case WTURLImageViewOptionTransitionRipple:
        case WTURLImageViewOptionTransitionCubeFromRight:
        case WTURLImageViewOptionTransitionCubeFromLeft:
        case WTURLImageViewOptionTransitionCubeFromTop:
        case WTURLImageViewOptionTransitionCubeFromBottom:
        {
            CATransition *animation = [CATransition animation];
            [animation setDuration:transitionDuration];
            //[animation setSubtype:kCATransitionFromLeft];
            //rippleEffect, cube, oglFlip...
            switch (effect) {
                default:
                    [animation setType:kCATransitionFade]; break;
                case WTURLImageViewOptionTransitionCubeFromTop:
                    [animation setType:@"cube"]; [animation setSubtype:kCATransitionFromTop]; break;
                case WTURLImageViewOptionTransitionCubeFromBottom:
                    [animation setType:@"cube"]; [animation setSubtype:kCATransitionFromBottom]; break;
                case WTURLImageViewOptionTransitionCubeFromLeft:
                    [animation setType:@"cube"]; [animation setSubtype:kCATransitionFromLeft]; break;
                case WTURLImageViewOptionTransitionCubeFromRight:
                    [animation setType:@"cube"]; [animation setSubtype:kCATransitionFromRight]; break;
                case WTURLImageViewOptionTransitionRipple:
                    [animation setType:@"rippleEffect"]; break;
            }
            [self.layer addAnimation:animation forKey:@"transition"];
            self.image = image;
        } break;
            // Custom dissolve type animation
        case WTURLImageViewOptionTransitionScaleDissolve:
        case WTURLImageViewOptionTransitionPerspectiveDissolve:
        {
            CALayer *layer = [self wt_layerFromImage:image];
            switch (effect) {
                default:
                    //case WTURLImageViewOptionTransitionCrossDissolve:
                    //    break;
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
            [CATransaction setAnimationDuration: transitionDuration];
            [CATransaction setCompletionBlock: ^ {
                [layer removeFromSuperlayer];
                self.image = image;
            }];
            layer.opacity = 1.0f;
            layer.affineTransform = CGAffineTransformIdentity;
            [CATransaction commit];
            
        } break;
            // Custom slide type animation
        case WTURLImageViewOptionTransitionSlideInTop:
        case WTURLImageViewOptionTransitionSlideInLeft:
        case WTURLImageViewOptionTransitionSlideInBottom:
        case WTURLImageViewOptionTransitionSlideInRight:
        {
            CALayer *layer = [self wt_layerFromImage:image];
            BOOL clipsToBoundsSave = self.clipsToBounds;
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
            [CATransaction setAnimationDuration: transitionDuration];
            [CATransaction setCompletionBlock: ^ {
                [layer removeFromSuperlayer];
                self.image = image;
                // have sublayer means animation in progress
                NSArray *sublayer = self.layer.sublayers;
                if (sublayer.count==1)
                    self.clipsToBounds = clipsToBoundsSave;
            }];
            layer.affineTransform = CGAffineTransformIdentity;
            [CATransaction commit];
        } break;
            // OS-provided UIView type transition animation
        case WTURLImageViewOptionTransitionFlipFromLeft:
        case WTURLImageViewOptionTransitionFlipFromRight:
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:transitionDuration];
            switch (effect) {
                case WTURLImageViewOptionTransitionFlipFromLeft:
                    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES]; break;
                case WTURLImageViewOptionTransitionFlipFromRight:
                    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self cache:YES]; break;
                default:
                    break;
            }
            self.image = image;
            [UIView commitAnimations];
            break;
        } break;
        default:
            break;
    }
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

- (id) init
{
    self = [super init];
    if (self) {
        // default fill in
        _fillType = UIImageResizeFillTypeFillIn;
    }
    return self;
}

@end
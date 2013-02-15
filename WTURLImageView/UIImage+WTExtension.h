//
//  UIImage+ResizeExtension.h
//  WTURLImageViewDemo
//
//  Created by Water Lou on 15/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UIImageResizeFillType) {
    UIImageResizeFillTypeIgnoreAspectRatio = 0,
    UIImageResizeFillTypeFillIn = 1,
    UIImageResizeFillTypeFitIn = 2,
};

@interface UIImage (WTExtension)

/*
 * resize image with options to keep aspect ratio using different method. And optionally round the corners
 */
- (UIImage*) resize : (CGSize)newSize
           fillType : (UIImageResizeFillType) fillType
      topLeftCorner : (CGFloat)topLeftCorner
     topRightCorner : (CGFloat)topRightCorner
  bottomRightCorner : (CGFloat)bottomRightCorner
   bottomLeftCorner : (CGFloat)bottomLeftCorner quality:(CGInterpolationQuality)quality;

// resize and not keep the aspect ratio
- (UIImage*) resize : (CGSize)newSize roundCorner:(CGFloat)roundCorner quality:(CGInterpolationQuality)quality;
// resize and keep the aspect ratio using fill in
- (UIImage*) resizeFillIn : (CGSize)newSize roundCorner:(CGFloat)roundCorner quality:(CGInterpolationQuality)quality;
// resize and keep the aspect ratio using fit in, not draw area will be in transparent color
- (UIImage*) resizeFitIn : (CGSize)newSize roundCorner:(CGFloat)corner quality:(CGInterpolationQuality)quality;

// crop image, handled scale and orientation
- (UIImage*) crop : (CGRect) cropRect;

// return an image that orientation always UIImageOrientationUp
- (UIImage*) normalizeOrientation;

// generate plain image from color
+ (UIImage*) imageWithUIColor : (UIColor*) color size : (CGSize) size;

@end

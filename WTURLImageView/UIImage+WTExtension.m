//
//  UIImage+ResizeExtension.m
//  WTURLImageViewDemo
//
//  Created by Water Lou on 15/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import "UIImage+WTExtension.h"

static void CGContextMakeRoundCornerPath(CGContextRef c, CGRect rrect, float rad_tl, float rad_tr, float rad_br, float rad_bl) {
	CGContextBeginPath(c);
	
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
	
	// Next, we will go around the rectangle in the order given by the figure below.
	//       minx    midx    maxx
	// miny    8       7       6
	// midy   1 9              5
	// maxy    2       3       4
	// Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
	// form a closed path, so we still need to close the path to connect the ends correctly.
	// Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
	// You could use a similar tecgnique to create any shape with rounded corners.
	
	// Start at 1
	CGContextMoveToPoint(c, minx, midy);
	// Add an arc through 2 to 3
	CGContextAddArcToPoint(c, minx, miny, midx, miny, rad_bl);
	// Add an arc through 4 to 5
	CGContextAddArcToPoint(c, maxx, miny, maxx, midy, rad_br);
	// Add an arc through 6 to 7
	CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, rad_tr);
	// Add an arc through 8 to 9
	CGContextAddArcToPoint(c, minx, maxy, minx, midy, rad_tl);
	// Close the path
	CGContextClosePath(c);
}


@implementation UIImage (WTExtension)

- (UIImage*) resize : (CGSize)newSize roundCorner:(CGFloat)roundCorner quality:(CGInterpolationQuality)quality {
	return [self resize:newSize fillType:UIImageResizeFillTypeIgnoreAspectRatio
          topLeftCorner:roundCorner topRightCorner:roundCorner bottomRightCorner:roundCorner bottomLeftCorner:roundCorner quality:quality];
}

- (UIImage*) resizeFillIn : (CGSize)newSize roundCorner:(CGFloat)roundCorner quality:(CGInterpolationQuality)quality {
	return [self resize:newSize fillType:UIImageResizeFillTypeFillIn
          topLeftCorner:roundCorner topRightCorner:roundCorner bottomRightCorner:roundCorner bottomLeftCorner:roundCorner quality:quality];
}

- (UIImage*) resizeFitIn : (CGSize)newSize roundCorner:(CGFloat)roundCorner quality:(CGInterpolationQuality)quality {
	return [self resize:newSize fillType:UIImageResizeFillTypeFitIn
          topLeftCorner:roundCorner topRightCorner:roundCorner bottomRightCorner:roundCorner bottomLeftCorner:roundCorner quality:quality];
}

- (UIImage*) resize : (CGSize)newSize
           fillType : (UIImageResizeFillType) fillType
      topLeftCorner : (CGFloat)topLeftCorner
     topRightCorner : (CGFloat)topRightCorner
  bottomRightCorner : (CGFloat)bottomRightCorner
   bottomLeftCorner : (CGFloat)bottomLeftCorner quality:(CGInterpolationQuality)quality {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, [UIScreen mainScreen].scale);
	CGRect imageRect = CGRectMake(0, 0, newSize.width, newSize.height);
	if (topLeftCorner>0.0 || topRightCorner>0.0 || bottomLeftCorner>0.0 || bottomRightCorner>0.0) {
        CGContextRef c = UIGraphicsGetCurrentContext();
		CGContextMakeRoundCornerPath(c, imageRect, topLeftCorner, topRightCorner, bottomRightCorner, bottomLeftCorner);
		CGContextClip(c);
	}
	switch (fillType) {
        case UIImageResizeFillTypeFillIn:
        {
            CGSize oldSize = self.size;
            CGFloat r1 = oldSize.width/oldSize.height;
            CGFloat r2 = newSize.width/newSize.height;
            if (r1 > r2) {
                CGFloat w = oldSize.width * newSize.height / oldSize.height;
                CGFloat h = newSize.height;
                imageRect = CGRectMake((newSize.width-w)/2.0f, 0.0f, w, h);
            }
            else {
                CGFloat w = newSize.width;
                CGFloat h = oldSize.height * newSize.width / oldSize.width;
                imageRect = CGRectMake(0.0f, (newSize.height-h)/2.0f, w, h);
            }
        } break;
        case UIImageResizeFillTypeFitIn:
        {
            CGSize oldSize = self.size;
            CGFloat r1 = oldSize.width/oldSize.height;
            CGFloat r2 = newSize.width/newSize.height;
            if (r1 > r2) {
                imageRect.size.height = newSize.width * oldSize.height / oldSize.width;
                imageRect.origin.y = (newSize.height - imageRect.size.height ) / 2.0;
            }
            else {
                imageRect.size.width = newSize.height * oldSize.width / oldSize.height;
                imageRect.origin.x = (newSize.width - imageRect.size.width ) / 2.0;
            }
        }
            break;
        default:
            break;
	}
	[self drawInRect:imageRect];
	UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return ret;
}

- (UIImage*) normalizeOrientation
{
    if (self.imageOrientation==UIImageOrientationUp) return self;   // correct orientation
    // redraw image in context to create a new image
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
	[self drawInRect:rect];
	UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return ret;
}


- (UIImage*) crop : (CGRect) cropRect
{
    // if orientation not standard, rotate the rect
    CGFloat scale = self.scale;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
            cropRect = CGRectApplyAffineTransform(cropRect, CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -cropRect.size.height));
            break;
        case UIImageOrientationRight:
            cropRect = CGRectApplyAffineTransform(cropRect, CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -cropRect.size.width, 0));
            break;
        case UIImageOrientationDown:
            cropRect = CGRectApplyAffineTransform(cropRect, CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI), -cropRect.size.width, -cropRect.size.height));
            break;
        default:
            break;
    }
    // multiply cropRect with scale for retina image
    if (scale>1.0) {
        cropRect.origin.x *= scale;
        cropRect.origin.y *= scale;
        cropRect.size.width *= scale;
        cropRect.size.height *= scale;
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage *ret = [UIImage imageWithCGImage: imageRef scale:scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return ret;
}

+ (UIImage*) imageWithUIColor : (UIColor*) color size : (CGSize) size
{
    // redraw image in context to create a new image
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    [color setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
	UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return ret;
    
}

@end

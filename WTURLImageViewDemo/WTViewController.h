//
//  WTViewController.h
//  WTURLImageViewDemo
//
//  Created by Water Lou on 14/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WTURLImageView.h"

@interface WTViewController : UIViewController

@property (weak, nonatomic) IBOutlet WTURLImageView *imageView;

- (IBAction)doLoadImage:(id)sender;
- (IBAction)doUsePlaceHolder:(id)sender;
- (IBAction)doClearImageBeforeLoading:(id)sender;
- (IBAction)doUseDiskCache:(id)sender;
- (IBAction)doActivityIndicator:(id)sender;
- (IBAction)doTransition:(id)sender;
- (IBAction)doResize:(id)sender;

@end

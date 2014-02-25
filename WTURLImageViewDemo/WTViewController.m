//
//  WTViewController.m
//  WTURLImageViewDemo
//
//  Created by Water Lou on 14/2/13.
//  Copyright (c) 2013 First Water Tech Ltd. All rights reserved.
//

#import "WTViewController.h"

@interface WTViewController ()

@end

@implementation WTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // you can set parameters of the imageView in preset and quickly set on setURL later
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    preset.fillType = UIImageResizeFillTypeFillIn;
    preset.placeholderImage = [UIImage imageNamed:@"placeholder"];
    preset.options = WTURLImageViewOptionTransitionNone | WTURLImageViewOptionShowActivityIndicator | WTURLImageViewOptionAnimateEvenCache;
    
    UISegmentedControl *control = (UISegmentedControl*)[self.view viewWithTag:5000];
    [control setSelectedSegmentIndex: 1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doLoadImage:(id)sender {
    NSArray *images = @[
                         @"http://www.ctvnews.ca/polopoly_fs/1.1061284!/httpImage/image.jpeg_gen/derivatives/landscape_620/image.jpeg",
                         @"http://www.clker.com/cliparts/c/2/4/3/1194986855125869974rubik_s_cube_random_petr_01.svg.hi.png",
                         @"http://sports.ndtv.com/images/stories/football-image-300.jpg",
                         @"http://highslide.com/samples/full2.jpg",
                         @"http://static5.businessinsider.com/image/50a68c3869beddbf2c00001c-400-300/klipschs-image-s4i-are-great-budget-friendly-headphones.jpg"
                         ];
    static int index = 0;
    if (sender!=nil)
        index = (index+1) % 5;
    [self.imageView setURL: [NSURL URLWithString:images[index]] withPreset:[WTURLImageViewPreset defaultPreset]];
}

- (IBAction)doUsePlaceHolder:(UISwitch *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    if (sender.isOn)
        preset.placeholderImage = [UIImage imageNamed:@"placeholder"];
    else
        preset.placeholderImage = nil;
    [self doLoadImage: nil];
}

- (IBAction)doClearImageBeforeLoading:(UISwitch *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    WTURLImageViewOptions options = preset.options;
    if (sender.isOn)
        options &= ~ (WTURLImageViewOptionDontClearImageBeforeLoading);
    else
        options |= (WTURLImageViewOptionDontClearImageBeforeLoading);
    preset.options = options;
    [self doLoadImage: nil];
}

- (IBAction)doUseDiskCache:(UISwitch *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    WTURLImageViewOptions options = preset.options;
    if (sender.isOn)
        options &= ~ (WTURLImageViewOptionDontSaveDiskCache | WTURLImageViewOptionDontUseCache);
    else
        options |= (WTURLImageViewOptionDontSaveDiskCache | WTURLImageViewOptionDontUseCache);
    preset.options = options;
    [self doLoadImage: nil];
}

- (IBAction)doActivityIndicator:(UISwitch *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    WTURLImageViewOptions options = preset.options;
    if (sender.isOn)
        options |= (WTURLImageViewOptionShowActivityIndicator);
    else
        options &= ~ (WTURLImageViewOptionShowActivityIndicator);
    preset.options = options;
    [self doLoadImage: nil];
}

- (IBAction)doTransition:(UISegmentedControl *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    WTURLImageViewOptions options = preset.options;

    options &= ~ (0x0fL << 20);  // mask out transition parts
    options |= sender.selectedSegmentIndex << 20;
    preset.options = options;
    [self doLoadImage: nil];
}

- (IBAction)doResize:(UISegmentedControl *)sender {
    WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    preset.fillType = sender.selectedSegmentIndex;
    [self doLoadImage:nil];
    
}

@end

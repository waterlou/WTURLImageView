WTURLImageView
==============

WTURLImageView is a subclass of UIImageView that load images from Internet using AFNetworking, with the following features

- Auto resize image
- Show image in different aspect ratio
- Disk cache using GVCache
- Activity indicator
- Placeholder and failed image
- Various transition animations when image is loaded

### Usage

Simplest call:

	[imageView setURL:url];
	
Call with options:

	[imageView setURL:url
			 fillType:fillType
			  options:options
    placeholderImage:placeholderImage
	     failedImage:failedImage
			   diskCacheTimeoutInternal:diskCacheTimeInterval];

where you can set different fillType:

- UIImageResizeFillTypeFillIn
- UIImageResizeFillTypeFitIn
- UIImageResizeFillTypeIgnoreAspectRatio

various options:

- WTURLImageViewOptionDontUseDiskCache: Disable disk cache
- WTURLImageViewOptionDontUseConnectionCache: Disable http cache
- WTURLImageViewOptionDontUseCache: Disable all cache
- WTURLImageViewOptionDontSaveDiskCache: Don't cache image
- WTURLImageViewOptionShowActivityIndicator: show activity indicator
- WTURLImageViewOptionAnimateEvenCache: by default, no animation when load from cache, set it to force animation in all case
- WTURLImageViewOptionDontClearImageBeforeLoading: by default, will clear old image when loading new image, keep the old image before new image is loaded.
- WTURLImageViewOptionsLoadDiskCacheInBackground: by default, cache is loaded in foreground.  Set it if you assume loading image is very big that will take time to load from cache.
- WTURLImageViewOptionTransitionXXX: Various predefined transition when image is loaded.

It may be troublesome to set options every time, so you can use a helper class to preset settings:

	WTURLImageViewPreset *preset = [][WTURLImageViewPreset alloc] init];
    preset.placeholderImage = [UIImage imageNamed:@"placeholder"];

	[imageView setURL: url preset:preset];
	
Or you can set the default settings:

	WTURLImageViewPreset *preset = [WTURLImageViewPreset defaultPreset];
    preset.placeholderImage = [UIImage imageNamed:@"placeholder"];

that all [WTURLImageView setURL:] will use the preset settings.

Check the sample code for details.

### License

These specifications and CocoaPods are available under the [MIT license](http://www.opensource.org/licenses/mit-license.php).

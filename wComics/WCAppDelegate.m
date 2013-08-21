//
//  WCAppDelegate.m
//  wComics
//
//  Created by Nik S Dyonin on 24.07.13.
//  Copyright (c) 2013 Brite Apps. All rights reserved.
//

#import "WCAppDelegate.h"
#import "WCViewerViewController.h"
#import "WCLibraryDataSource.h"

void uncaughtExceptionHandler(NSException *exception) {
	TRACE(@"CRASH: %@", exception);
	TRACE(@"Stack Trace: %@", [exception callStackSymbols]);
}

@implementation WCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

	viewController = [[WCViewerViewController alloc] init];
	
	window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	window.rootViewController = viewController;
	[window makeKeyAndVisible];
	
	[self run];
	
	justStarted = YES;
	[self performSelectorInBackground:@selector(updateLibrary) withObject:nil];
	
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if (url) {
		WCComic *comic = [[WCComic alloc] initWithFile:[url path]];
		viewController.comic = comic;
	}
	
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[viewController dismissPopover];
	[[WCSettingsStorage sharedInstance] setLastDocument:viewController.comic.file];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[self showIndicator];
	[self performSelectorInBackground:@selector(updateLibrary) withObject:nil];
}

- (void)checkOpen {
	NSString *lastDocument = [[WCSettingsStorage sharedInstance] lastDocument];
	if (lastDocument) {
		[self showIndicator];
		WCComic *comic = [[WCComic alloc] initWithFile:lastDocument];
		viewController.comic = comic;
		[self hideIndicator];
	}
}

- (void)updateLibrary {
	@autoreleasepool {
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		NSString *coverDir = [DOCPATH stringByAppendingPathComponent:@"covers"];
		[[NSFileManager defaultManager] createDirectoryAtPath:coverDir withIntermediateDirectories:YES attributes:nil error:nil];
		
		[[WCLibraryDataSource sharedInstance] updateLibrary];
		[self hideIndicator];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		
		if (justStarted) {
			justStarted = NO;
			[self checkOpen];
		}
	}
}


- (void)showIndicator {
	[viewController.view addSubview:updateIndicator];
	CGRect tmpRect = updateIndicator.frame;
	tmpRect.origin.x = floorf((viewController.view.bounds.size.width - tmpRect.size.width) * 0.5f);
	tmpRect.origin.y = floorf((viewController.view.bounds.size.height - tmpRect.size.height) * 0.5f);
	updateIndicator.frame = tmpRect;
}

- (void)hideIndicator {
	[updateIndicator removeFromSuperview];
}

- (void)run {
	updateIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 300.0f)];
	updateIndicator.backgroundColor = RGBA(0, 0, 0, 0.8);
	CALayer *layer = updateIndicator.layer;
	layer.masksToBounds = YES;
	layer.cornerRadius = 10.0f;
	
	UIActivityIndicatorView *ind = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[updateIndicator addSubview:ind];
	CGRect tmpRect = ind.frame;
	tmpRect.origin.x = floorf((updateIndicator.frame.size.width - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = floorf((updateIndicator.frame.size.height - tmpRect.size.height) / 2.0f) - 20.0f;
	ind.frame = tmpRect;
	[ind startAnimating];
	
	UILabel *textLabel = [[UILabel alloc] init];
	textLabel.backgroundColor = [UIColor clearColor];
	textLabel.font = [UIFont boldSystemFontOfSize:18];
	textLabel.textColor = RGB(255, 255, 255);
	textLabel.numberOfLines = 1;
	textLabel.lineBreakMode = NSLineBreakByWordWrapping;
	textLabel.text = NSLocalizedString(@"UPDATING_LIBRARY", @"Updating library");
	[textLabel sizeToFit];
	tmpRect = textLabel.frame;
	tmpRect.origin.x = floorf((updateIndicator.frame.size.width - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = ind.frame.origin.y + ind.frame.size.height + 20.0f;
	textLabel.frame = tmpRect;
	[updateIndicator addSubview:textLabel];
	
	viewController.updateIndicator = updateIndicator;
	
	[self showIndicator];
}

- (void)dealloc {
	viewController = nil;
	updateIndicator = nil;
	window = nil;
}

@end
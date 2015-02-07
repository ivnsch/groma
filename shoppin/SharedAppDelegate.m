//
//  SharedAppDelegate.m
//  shoppin
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

#import "SharedAppDelegate.h"

#if TARGET_OS_IPHONE
    #import "shoppin-Swift.h"
#else
    #import "shoppin_osx-Swift.h"
#endif

@implementation SharedAppDelegate

+ (AppDelegate *) getAppDelegate {
#if TARGET_OS_IPHONE
    return [[UIApplication sharedApplication] delegate];
#else
    return [[NSApplication sharedApplication] delegate];
#endif
}

@end

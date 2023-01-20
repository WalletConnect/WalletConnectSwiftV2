#import <Foundation/Foundation.h>
#import "Router.h"

#if __has_include(<UIKit/UIKit.h>)

@import UIKit;
@import ObjectiveC.runtime;

@interface UISystemNavigationAction : NSObject
@property(nonatomic, readonly, nonnull) NSArray<NSNumber*>* destinations;
-(BOOL)sendResponseForDestination:(NSUInteger)destination;
@end

@implementation Router

+ (void)goBack {
    Ivar sysNavIvar = class_getInstanceVariable(UIApplication.class, "_systemNavigationAction");
    UIApplication* app = UIApplication.sharedApplication;
    UISystemNavigationAction* action = object_getIvar(app, sysNavIvar);
    if (!action) {
        return;
    }
    NSUInteger destination = action.destinations.firstObject.unsignedIntegerValue;
    [action sendResponseForDestination:destination];
}

@end

#endif


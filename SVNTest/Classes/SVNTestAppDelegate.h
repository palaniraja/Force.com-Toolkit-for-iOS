//
//  SVNTestAppDelegate.h
//  SplitForce
//
//  Created by Dave Carroll on 6/20/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "zkSforce.h"

@class RootViewController;
@class DetailViewController;
@class LoginViewController;

@interface SVNTestAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    
    UISplitViewController *splitViewController;
    
    RootViewController *rootViewController;
    DetailViewController *detailViewController;
    LoginViewController *loginViewController;
	UIAlertView *alert;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@property (nonatomic, retain) IBOutlet LoginViewController *loginViewController;

- (void)showLogin;
- (void)hideLogin;
-(void)popupActionSheet:(NSError *)message;
@end

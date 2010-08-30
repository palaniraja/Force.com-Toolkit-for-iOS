    //
//  LoginViewController.m
//  SplitForce
//
//  Created by Dave Carroll on 6/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "SVNTestAppDelegate.h"
#import "ZKSforce.h"

@implementation LoginViewController

@synthesize usernameTextField, passwordTextField;

- (IBAction)login:(id)sender 
{
	SVNTestAppDelegate *app = [[UIApplication sharedApplication] delegate];
	RootViewController *rootViewController = app.rootViewController;
    [ZKServerSwitchboard switchboard].logXMLInOut = YES;
    [[ZKServerSwitchboard switchboard] loginWithUsername:usernameTextField.text password:passwordTextField.text target:rootViewController selector:@selector(loginResult:error:)];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    NSString *password = @"test1234";
    NSString *token = @"b3haNhsBVrhrj78F22V6wTO";// @"cUb3haNhsBVrhrj78F22V6wTO";
    passwordTextField.text = [NSString stringWithFormat:@"%@%@", password, token];// @"test1234cUb3haNhsBVrhrj78F22V6wTO";
    usernameTextField.text = @"dcarroll@chatterbuzz.com";
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
    [super dealloc];
}



@end

//
//  RootViewController.h
//  SplitForce
//
//  Created by Dave Carroll on 6/20/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "zkSforce.h"

@class DetailViewController;

@interface RootViewController : UITableViewController <UIActionSheetDelegate, ForceClientDelegate> {
    DetailViewController *detailViewController;
	ZKSforceClient *client;
	
	NSMutableArray *dataRows;
	NSIndexPath *deleteIndexPath;
}

@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;
@property (nonatomic, retain) ZKSforceClient *client;
@property (nonatomic, retain) NSMutableArray *dataRows;
@property (nonatomic, retain) NSIndexPath *deleteIndexPath;

-(void)getRows;
-(void)alertOKCancelAction:(NSString *)title withMessage:(NSString *)message;
-(void)alertOKAction:(NSString *)title withMessage:(NSString *)message;
-(void)loginSucceeded:(ZKLoginResult *)results;

@end

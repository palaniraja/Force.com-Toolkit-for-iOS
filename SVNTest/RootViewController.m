//
//  RootViewController.m
//  SplitForce
//
//  Created by Dave Carroll on 6/20/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RootViewController.h"
#import "DetailViewController.h"
#import "SVNTestAppDelegate.h"
#import "ZKLoginResult.h"
#import "ZKServerSwitchboard.h"

@implementation RootViewController

@synthesize detailViewController;
@synthesize client;
@synthesize dataRows;
@synthesize deleteIndexPath;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(420.0, 800.0);
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
												target:self
												action:@selector(addItem:)] autorelease];
}

// Old Method, see Server Switchboard Results section.
-(void)loginSucceeded:(ZKLoginResult *)results {
	
	SVNTestAppDelegate *app = [[UIApplication sharedApplication] delegate];

	NSLog(@"Hey, we logged in!");
	
	[self getRows];
	
	// remove login dialog
	[app hideLogin];
}

-(void)receivedErrorFromAPICall:(NSString *)err {
	SVNTestAppDelegate *app = [[UIApplication sharedApplication] delegate];
	[app popupActionSheet:err];
}

- (void)getRows {
	NSString *queryString = @"Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Type, Website From Account";
    //[client queryAsync:queryString withDelegate:self];
    [[ZKServerSwitchboard switchboard] query:queryString target:self selector:@selector(queryResult:error:context:) context:nil];
}

// Old Method, see Server Switchboard Results section.
-(void)queryReady:(ZKQueryResult *)results {
	self.dataRows = [NSMutableArray arrayWithArray:[results records]];
	[self.tableView reloadData];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
	actionSheet.frame = CGRectMake(50, 50, 600.0, 600.0 ); 
}
- (void)willPresentAlertView:(UIAlertView *)alertView {
    alertView.frame = CGRectMake(50, 50, 600.0, 600.0 );
}
- (void)didPresentAlertView:(UIAlertView *)alertView {
    alertView.frame = CGRectMake(50, 50, 600.0, 600.0 );
}

- (IBAction)addItem:(id)sender {
	ZKSObject *cObj = [[ZKSObject alloc] initWithType:@"Account"];
	
	[self.detailViewController setDetailItem:cObj];
	[self.detailViewController setEditing:YES];
	[self.detailViewController showEditView:sender];
	
	[cObj release];
}
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [dataRows count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Configure the cell.
	ZKSObject *obj = [dataRows objectAtIndex:indexPath.row];
	cell.textLabel.text = [obj fieldValue:@"Name"];

    //cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row from the data source
		deleteIndexPath = indexPath;
		[self alertOKCancelAction:@"Delete Contact" withMessage:@"Click OK to permanently delete row."];
		//[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}   
}

- (void)alertOKCancelAction:(NSString *)title withMessage:(NSString *)message {
	// open a alert with an OK and cancel button
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	// the user clicked one of the OK/Cancel buttons
	if (buttonIndex == 0)
	{
		NSLog(@"cancel");
	}
	else
	{
		NSLog(@"ok");
		ZKSObject *delObj = (ZKSObject *)[self.dataRows objectAtIndex:deleteIndexPath.row];
		NSString *objectID = [delObj fieldValue:@"Id"];
		[client deleteAsync:[NSArray arrayWithObjects:objectID,nil]	withDelegate:self];
	}
}

-(void)deleteResultsReady:(NSMutableArray *)results {
		ZKSaveResult *res = [results objectAtIndex:0];
		
		if ([res success]) {
			[self.dataRows removeObjectAtIndex:deleteIndexPath.row];
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
		} else {
			NSLog([res message], "%");
			[self alertOKAction:@"Action Failed" withMessage:[res message]];
			[self.tableView setEditing:NO animated:YES];
		}
}

- (void)alertOKAction:(NSString *)title withMessage:(NSString *)message {
	// open a alert with an OK and cancel button
	UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:title];
	[alert setMessage:message]; 
	[alert addButtonWithTitle:@"OK"];
	[alert show];
	[alert release];
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     When a row is selected, set the detail view controller's detail item to the item associated with the selected row.
     */
    detailViewController.detailItem = [dataRows objectAtIndex:indexPath.row];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [detailViewController release];
    [super dealloc];
}


#pragma mark Server Switchboard Results

- (void)loginResult:(ZKLoginResult *)result error:(NSError *)error
{
    if (result && !error)
    {
        NSLog(@"Hey, we logged in (with the new switchboard)!");
        
        [self getRows];
        
        // remove login dialog
        SVNTestAppDelegate *app = [[UIApplication sharedApplication] delegate];
        [app hideLogin];
    }
    else if (error)
    {
        [self receivedErrorFromAPICall: [error domain]];
    }
}

- (void)queryResult:(ZKQueryResult *)result error:(NSError *)error context:(id)context
{
    NSLog(@"queryResult:%@ eror:%@ context:%@", result, error, context);
    if (result && !error)
    {
        self.dataRows = [NSMutableArray arrayWithArray:[result records]];
        [self.tableView reloadData];
    }
    else if (error)
    {
        [self receivedErrorFromAPICall: [error domain]];
    }
}

@end


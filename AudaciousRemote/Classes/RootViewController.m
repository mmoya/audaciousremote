//
//  RootViewController.m
//  AudaciousRemote
//
//  Created by Maykel Moya on 16/08/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RootViewController.h"
#import "AudaciousRemoteViewController.h"


@implementation RootViewController

- (void)viewDidLoad
{
    self.title = @"Hostname";
    [super viewDidLoad];
}

- (IBAction)showAudaciousController:(id)sender
{
    AudaciousRemoteViewController *audaciousRemoteVC = [[AudaciousRemoteViewController alloc]
                                                        initWithNibName:@"AudaciousRemoteViewController"
                                                        bundle:nil];
    audaciousRemoteVC.hostname = hostnameField.text;

    [self.navigationController pushViewController:audaciousRemoteVC
                                         animated:TRUE];
    [audaciousRemoteVC release];
}

@end


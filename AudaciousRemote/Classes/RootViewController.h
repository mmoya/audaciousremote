//
//  RootViewController.h
//  AudaciousRemote
//
//  Created by Maykel Moya on 16/08/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController {

    IBOutlet UITextField *hostnameField;

}

- (IBAction)showAudaciousController:(id)sender;

@end

//
//  AudaciousRemoteViewController.h
//  AudaciousRemote
//
//  Created by Maykel Moya on 14/08/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONRPCManager.h"


@interface AudaciousRemoteViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource>
{
    JSONRPCManager *rpcManager;

    IBOutlet UISlider *timeSlider;
    BOOL timeSliderChanging;

    IBOutlet UILabel *timeElapsedLabel;
    IBOutlet UILabel *timeRemainingLabel;

    IBOutlet UISlider *volumeSlider;
    BOOL volumeSliderChanging;

    IBOutlet UILabel *songTitleLabel;
    IBOutlet UILabel *songArtistLabel;

    IBOutlet UITableView *playlistTableView;

    NSTimer *statusTimer;
    BOOL statusRequestInProgress;

    NSMutableArray *playlist;
    BOOL playlistRequestInProgress;

    IBOutlet UIButton *toggleRepeatButton;
    IBOutlet UIButton *toggleShuffleButton;

    IBOutlet UIButton *playPauseButton;

    NSString *hostname;
}

@property (nonatomic, retain) NSString *hostname;

- (IBAction)prev:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)next:(id)sender;

- (IBAction)updateStatus:(id)sender;
- (IBAction)updatePlaylist:(id)sender;

- (IBAction)toggleRepeat:(id)sender;
- (IBAction)toggleShuffle:(id)sender;

- (IBAction)volumeChangeDidBegin:(id)sender;
- (IBAction)volumeChangeDidEnd:(id)sender;
- (IBAction)volumeChanged:(id)sender;

- (IBAction)timeChangeDidBegin:(id)sender;
- (IBAction)timeChangeDidEnd:(id)sender;
- (IBAction)timeChanged:(id)sender;

- (void)statusTimerTick:(NSTimer *)theTimer;

@end

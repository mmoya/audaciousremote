//
//  AudaciousRemoteViewController.m
//  AudaciousRemote
//
//  Created by Maykel Moya on 14/08/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "AudaciousRemoteViewController.h"

#define PLAYPAUSE_BUTTON_PLAYING_TAG 10
#define PLAYPAUSE_BUTTON_PLAYING_IMAGE @"media-playback-pause.png"
#define PLAYPAUSE_BUTTON_PAUSED_TAG 20
#define PLAYPAUSE_BUTTON_PAUSED_IMAGE @"media-playback-start.png"

@implementation AudaciousRemoteViewController

@synthesize hostname;

- (void)viewDidLoad
{
    self.title = @"Remote Controller";

    [super viewDidLoad];

    NSString *url = [NSString stringWithFormat:@"http://%@:8888/", hostname];

    rpcManager = [[JSONRPCManager alloc] init:url];
    playlist = [[NSMutableArray alloc] initWithCapacity:5];

    [playPauseButton setImage:[UIImage imageNamed:PLAYPAUSE_BUTTON_PAUSED_IMAGE]
                     forState:UIControlStateNormal];
    playPauseButton.tag = PLAYPAUSE_BUTTON_PAUSED_TAG;

    statusRequestInProgress = FALSE;
    statusTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                   target:self
                                                 selector:@selector(statusTimerTick:)
                                                 userInfo:nil
                                                  repeats:TRUE];
}

#pragma mark -
#pragma mark prev

- (void)rpcPrevDidComplete:(NSDictionary *)results
{
}

- (void)rpcPrevDidFail:(NSError *)error
{
}

- (void)prev:(id)sender
{
    [rpcManager rpc:@"prev"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcPrevDidComplete:)
            errback:@selector(rpcPrevDidFail:)];
}

#pragma mark -
#pragma mark play

- (void)rpcPlayDidComplete:(NSDictionary *)results
{
}

- (void)rpcPlayDidFail:(NSError *)error
{
}

- (void)play:(id)sender
{
    [rpcManager rpc:@"play"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcPlayDidComplete:)
            errback:@selector(rpcPlayDidFail:)];
}

#pragma mark -
#pragma mark pause

- (void)rpcPauseDidComplete:(NSDictionary *)results
{
}

- (void)rpcPauseDidFail:(NSError *)error
{
}

- (void)pause:(id)sender
{
    [rpcManager rpc:@"pause"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcPauseDidComplete:)
            errback:@selector(rpcPauseDidFail:)];
}

#pragma mark -
#pragma mark stop

- (void)rpcStopDidComplete:(NSDictionary *)results
{
}

- (void)rpcStopDidFail:(NSError *)error
{
}

- (void)stop:(id)sender
{
    [rpcManager rpc:@"stop"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcStopDidComplete:)
            errback:@selector(rpcStopDidFail:)];
}

#pragma mark -
#pragma mark next

- (void)rpcNextDidComplete:(NSDictionary *)results
{
}

- (void)rpcNextDidFail:(NSError *)error
{
}

- (void)next:(id)sender
{
    [rpcManager rpc:@"next"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcNextDidComplete:)
            errback:@selector(rpcNextDidFail:)];
}

#pragma mark -
#pragma mark status

- (void)updateTimeLabels:(NSInteger)length time:(NSInteger)aTime
{
    NSInteger remaining = length - aTime;

    timeElapsedLabel.text = [NSString stringWithFormat:@"%d:%02d", aTime / 60, aTime % 60];
    timeRemainingLabel.text = [NSString stringWithFormat:@"%d:%02d", remaining / 60, remaining % 60];
}

- (void)rpcStatusDidComplete:(NSDictionary *)results
{
    NSDictionary *result = [results objectForKey:@"result"];

    NSInteger length = [[result objectForKey:@"length"] intValue];
    NSInteger time = [[result objectForKey:@"time"] intValue];

    if (!timeSliderChanging) {
        if (timeSlider.maximumValue != length)
            timeSlider.maximumValue = length;

        timeSlider.value = time;

        [self updateTimeLabels:length time:time];
    }

    NSString *songTitle = [result objectForKey:@"title"];
    songTitleLabel.text = songTitle;

    NSString *songArtist = [result objectForKey:@"artist"];
    songArtistLabel.text = songArtist;

    BOOL repeat = [[result objectForKey:@"repeat"] boolValue];
    toggleRepeatButton.highlighted = repeat;

    BOOL shuffle = [[result objectForKey:@"shuffle"] boolValue];
    toggleShuffleButton.highlighted = shuffle;

    BOOL playing = [[result objectForKey:@"playing"] boolValue];
    if (playing && playPauseButton.tag == PLAYPAUSE_BUTTON_PAUSED_TAG) {
        [playPauseButton setImage:[UIImage imageNamed:PLAYPAUSE_BUTTON_PLAYING_IMAGE]
                         forState:UIControlStateNormal];
        playPauseButton.tag = PLAYPAUSE_BUTTON_PLAYING_TAG;
    }
    else if (!playing && playPauseButton.tag == PLAYPAUSE_BUTTON_PLAYING_TAG) {
        [playPauseButton setImage:[UIImage imageNamed:PLAYPAUSE_BUTTON_PAUSED_IMAGE]
                         forState:UIControlStateNormal];
        playPauseButton.tag = PLAYPAUSE_BUTTON_PAUSED_TAG;
    }

    NSInteger volume = [[result objectForKey:@"volume"] intValue];
    if (!volumeSliderChanging)
        volumeSlider.value = volume;

    statusRequestInProgress = FALSE;
}

- (void)rpcStatusDidFail:(NSError *)error
{
    statusRequestInProgress = FALSE;
}

- (void)rpcStatus
{
    if (statusRequestInProgress)
        return;

    statusRequestInProgress = TRUE;

    [rpcManager rpc:@"status"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcStatusDidComplete:)
            errback:@selector(rpcStatusDidFail:)];
}

- (IBAction)updateStatus:(id)sender
{
    [self rpcStatus];
}

- (void)statusTimerTick:(NSTimer *)theTimer
{
    DLog(@"statusTimer tick");
    [self rpcStatus];
}

#pragma mark -
#pragma mark playlist

- (void)rpcPlaylistDidComplete:(NSDictionary *)results
{

    NSArray *result = [results objectForKey:@"result"];

    [playlist release];
    playlist = [result retain];

    [playlistTableView reloadData];

    playlistRequestInProgress = FALSE;
    timeSliderChanging = FALSE;
    volumeSliderChanging = FALSE;
}

- (void)rpcPlaylistDidFail:(NSError *)error
{
    playlistRequestInProgress = FALSE;
}

- (void)rpcPlaylist
{
    if (playlistRequestInProgress)
        return;

    playlistRequestInProgress = TRUE;

    [rpcManager rpc:@"playlist"
               args:[NSArray arrayWithObjects:nil]
           delegate:self
           callback:@selector(rpcPlaylistDidComplete:)
            errback:@selector(rpcPlaylistDidFail:)];
}

- (IBAction)updatePlaylist:(id)sender
{
    [self rpcPlaylist];
}

#pragma mark -
#pragma mark jump

- (void)rpcJumpDidComplete:(NSDictionary *)results
{
    NSIndexPath *indexPath = [playlistTableView indexPathForSelectedRow];
    if (indexPath)
        [playlistTableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (void)rpcJumpDidFail:(NSError *)error
{
    NSIndexPath *indexPath = [playlistTableView indexPathForSelectedRow];
    if (indexPath)
        [playlistTableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (void)rpcJump:(NSInteger)pos
{
    [rpcManager rpc:@"jump"
               args:array_([NSNumber numberWithInt:pos])
           delegate:self
           callback:@selector(rpcJumpDidComplete:)
            errback:@selector(rpcJumpDidFail:)];
}

#pragma mark -
#pragma mark toggleRepeat

- (IBAction)toggleRepeat:(id)sender
{
}

#pragma mark -
#pragma mark toggleShuffle

- (IBAction)toggleShuffle:(id)sender
{
}

#pragma mark -
#pragma mark volumeChanged

- (void)rpcVolumeDidComplete:(NSDictionary *)results
{
    volumeSliderChanging = FALSE;
}

- (void)rpcVolumeDidFail:(NSError *)error
{
    volumeSliderChanging = FALSE;
}

- (IBAction)volumeChangeDidBegin:(id)sender
{
    DLog(@"volumeChangeDidBegin");
    volumeSliderChanging = TRUE;
}

- (IBAction)volumeChangeDidEnd:(id)sender
{
    DLog(@"volumeChangeDidEnd");
    volumeSliderChanging = FALSE;
}

- (IBAction)volumeChanged:(id)sender
{
    DLog(@"volumeChanged");
    [rpcManager rpc:@"volume_set"
               args:array_([NSNumber numberWithInt:volumeSlider.value])
           delegate:self
           callback:@selector(rpcVolumeDidComplete:)
            errback:@selector(rpcVolumeDidFail:)];
}

#pragma mark -
#pragma mark timeChanged

- (void)rpcTimeDidComplete:(NSDictionary *)results
{
    timeSliderChanging = FALSE;
}

- (void)rpcTimeDidFail:(NSError *)error
{
    timeSliderChanging = FALSE;
}

- (IBAction)timeChangeDidBegin:(id)sender
{
    DLog(@"timeChangeDidBegin");
    timeSliderChanging = TRUE;
}

- (IBAction)timeChangeDidEnd:(id)sender
{
    DLog(@"timeChangeDidEnd");
    [rpcManager rpc:@"time_set"
               args:array_([NSNumber numberWithInt:timeSlider.value])
           delegate:self
           callback:@selector(rpcTimeDidComplete:)
            errback:@selector(rpcTimeDidFail:)];
}

- (IBAction)timeChanged:(id)sender
{
    [self updateTimeLabels:timeSlider.maximumValue
                      time:timeSlider.value];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [playlist count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:@"cell"] autorelease];

    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

    NSDictionary *playlistEntry = [playlist objectAtIndex:indexPath.row];

    NSString *songTitle = [playlistEntry objectForKey:@"title"];
    if ([songTitle isEqualToString:@""])
        songTitle = @"Unknown title";
    cell.textLabel.text = songTitle;

    NSString *songArtist = [playlistEntry objectForKey:@"artist"];
    if ([songArtist isEqualToString:@""])
        songArtist = @"Unknown artist";
    cell.detailTextLabel.text = songArtist;

    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self rpcJump:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [playlistTableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

#pragma mark -

- (void)dealloc
{
    [hostname release];
    [rpcManager release];
    [playlist release];
    [super dealloc];
}

@end

//
// Created by Marijn Schilling on 18/11/14.
// Copyright (c) 2014 marijn. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "VideoPlayViewController.h"

@interface VideoPlayViewController ()

@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) MPMoviePlayerController *player;

@end

@implementation VideoPlayViewController

- (id)initWithURL:(NSURL *)url {
    
    self = [super init];
    
    if (self) {
        self.videoURL = url;
    }

    return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    [self play];

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *overlay = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:overlay];
}

-(void)play
{

    NSData *videoData = [NSData dataWithContentsOfURL:self.videoURL];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/vid1.mp4"];

    BOOL success = [videoData writeToFile:tempPath atomically:NO];

    self.player = [[MPMoviePlayerController alloc]initWithContentURL:self.videoURL];

    self.player.shouldAutoplay = NO;
    self.player.currentPlaybackRate = 18;
    self.player.view.frame = self.view.bounds;

    [self.view addSubview:self.player.view];

    self.player.scalingMode = MPMovieScalingModeAspectFit;

    self.player.fullscreen = YES;

    [self.player play];
}


@end
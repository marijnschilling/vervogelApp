//
// Created by Marijn Schilling on 18/11/14.
// Copyright (c) 2014 marijn. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <Novocaine/AudioFileReader.h>
#import "VideoPlayViewController.h"
#import "AudioFileWriter.h"
#import "Novocaine.h"

@interface VideoPlayViewController ()

@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) MPMoviePlayerController *player;

@property(nonatomic, strong) Novocaine *audioManager;

@property(nonatomic, strong) NSURL *audioURL;
@property(nonatomic, strong) UILabel *playButtonLabel;
@property(nonatomic, strong) UIImageView *overlay;
@property(nonatomic, strong) AudioFileReader *fileReader;
@end

@implementation VideoPlayViewController

- (id)initWithVideoURL:(NSURL *)url audioURL:(NSURL *)audioURL {

    self = [super init];

    if (self) {
        _videoURL = url;
        _audioURL = audioURL;
        _audioManager = [Novocaine audioManager];
    }

    return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.fileReader = [[AudioFileReader alloc]
            initWithAudioFileURL:self.audioURL
                    samplingRate:(float) self.audioManager.samplingRate
                     numChannels:self.audioManager.numOutputChannels];


    NSData *videoData = [NSData dataWithContentsOfURL:self.videoURL];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/vid1.mp4"];

    [videoData writeToFile:tempPath atomically:NO];


    self.player = [[MPMoviePlayerController alloc]initWithContentURL:self.videoURL];

    self.player.shouldAutoplay = NO;
    self.player.currentPlaybackRate = 18;
    self.player.view.frame = self.view.bounds;

    [self.view addSubview:self.player.view];

    self.player.scalingMode = MPMovieScalingModeAspectFit;
    self.player.fullscreen = YES;

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    self.overlay = [[UIImageView alloc] initWithImage:image];
    [self.player.view addSubview:self.overlay];

    self.playButtonLabel = [[UILabel alloc] init];
    self.playButtonLabel.text = @"Play >>>";
    self.playButtonLabel.textColor = [UIColor whiteColor];
    [self.playButtonLabel sizeToFit];
    self.playButtonLabel.frame = CGRectMake(self.view.bounds.size.width/2- self.playButtonLabel.frame.size.width/2, self.view.bounds.size.height/2- self.playButtonLabel.frame.size.height/2, self.playButtonLabel.frame.size.width, self.playButtonLabel.frame.size.height);

    [self.playButtonLabel setUserInteractionEnabled:YES];
    UITapGestureRecognizer *recordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPlay:)];
    [self.playButtonLabel addGestureRecognizer:recordGesture];
    [self.view addSubview:self.playButtonLabel];

    [[NSNotificationCenter defaultCenter] addObserver:self // the object listening / "observing" to the notification
                                             selector:@selector(playingFinished:) // method to call when the notification was pushed
                                                 name:MPMoviePlayerPlaybackDidFinishNotification // notification the observer should listen to
                                               object:nil]; // the object that is passed to the method
}

- (void)didTapPlay:(id)didTapPlay {

    [self.playButtonLabel setHidden:YES];

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
    {
        [self.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
    }];

    [self.fileReader play];
    [self.player play];
}

- (void)playingFinished:(id)playingFinished {

    [self.fileReader pause];
    self.audioManager.outputBlock = nil;
}

@end
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

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *overlay = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:overlay];

    self.playButtonLabel = [[UILabel alloc] init];
    self.playButtonLabel.text = @"Play >>>";
    [self.playButtonLabel sizeToFit];
    self.playButtonLabel.frame = CGRectMake(self.view.bounds.size.width/2- self.playButtonLabel.frame.size.width/2, self.view.bounds.size.height/2- self.playButtonLabel.frame.size.height/2, self.playButtonLabel.frame.size.width, self.playButtonLabel.frame.size.height);

    [self.playButtonLabel setUserInteractionEnabled:YES];
    UITapGestureRecognizer *recordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPlay:)];
    [self.playButtonLabel addGestureRecognizer:recordGesture];
    [self.view addSubview:self.playButtonLabel];

}

- (void)didTapPlay:(id)didTapPlay {

    NSURL *inputFileURL = self.audioURL;

    AudioFileReader *fileReader = [[AudioFileReader alloc]
            initWithAudioFileURL:inputFileURL
                    samplingRate:(float) self.audioManager.samplingRate
                     numChannels:self.audioManager.numOutputChannels];

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
    {
        [fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
    }];

    [fileReader play];

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
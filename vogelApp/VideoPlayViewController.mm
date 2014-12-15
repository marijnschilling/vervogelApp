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
    [self play];

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *overlay = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:overlay];

}

-(void)play
{

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
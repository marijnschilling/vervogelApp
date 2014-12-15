//
// Created by Marijn Schilling on 18/11/14.
// Copyright (c) 2014 marijn. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "VideoPlayViewController.h"
#import "AudioFileWriter.h"
#import "Novocaine.h"

@interface VideoPlayViewController ()

@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) MPMoviePlayerController *player;

@property(nonatomic, strong) AudioFileWriter *fileWriter;
@property(nonatomic, strong) Novocaine *audioManager;

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

//    AVMutableComposition *newAudioAsset = [AVMutableComposition composition];
//    AVMutableCompositionTrack *dstCompositionTrack = [newAudioAsset addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *overlay = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:overlay];

    self.audioManager = [Novocaine audioManager];

    __weak VideoPlayViewController *weakSelf = self;

//    AVAsset *videoAsset = [AVAsset assetWithURL:self.videoURL];
//
//    NSArray *trackArray = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
//    if(!trackArray.count){
//        NSLog(@"Track returns empty array for mediatype AVMediaTypeAudio");
//        return;
//    }
//
//    AVAssetTrack *srcAssetTrack = [trackArray  objectAtIndex:0];
//    CMTimeRange timeRange = srcAssetTrack.timeRange;
//    NSError *err = nil;
//    if(NO == [dstCompositionTrack insertTimeRange:timeRange ofTrack:srcAssetTrack atTime:kCMTimeZero error:&err]){
//        NSLog(@"Failed to insert audio from the video to mutable avcomposition track");
//        return;
//    }



    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"bird_1" withExtension:@"wav"];

    self.fileWriter = [[AudioFileWriter alloc] initWithAudioFileURL:inputFileURL samplingRate:44100*13 numChannels:1];

    __block int counter = 0;
    self.audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];
        counter += 1;
        NSLog(@"Bezig");
        if (counter > 1600) { // roughly 5 seconds of audio
            weakSelf.fileWriter = nil;
            weakSelf.audioManager.inputBlock = nil;
        }
    };

    // START IT UP YO
    [self.audioManager play];

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
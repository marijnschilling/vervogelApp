//
//  RootViewController.m
//  vogelApp
//
//  Created by Marijn Schilling on 17/11/14.
//  Copyright (c) 2014 marijn. All rights reserved.
//

#import <Novocaine/AudioFileReader.h>
#import <Novocaine/AudioFileWriter.h>
#import "RootViewController.h"
#import "VideoPlayViewController.h"
#import "Novocaine.h"
#import "AudioFileReader.h"

@interface RootViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) UIImagePickerController * imagePicker;
@property(nonatomic, strong) UILabel *recordLabel;

@property(nonatomic, strong) VideoPlayViewController *videoPlayViewController;
@property(nonatomic, strong) AudioFileReader *birdSoundPlayer;
@property(nonatomic) RingBuffer *ringBuffer;
@property(nonatomic, strong) Novocaine *audioManager;
@property(nonatomic, strong) AudioFileWriter *fileWriter;

@property(nonatomic, strong) NSURL *audioFileURL;
@property(nonatomic, strong) UILabel *stopRecordLabel;
@end

@implementation RootViewController

- (instancetype)init {

    self = [super init];

    if (self) {
        _ringBuffer = new RingBuffer(32768, 2);
        _audioManager = [Novocaine audioManager];

        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"bird_1" withExtension:@"wav"];

        _birdSoundPlayer = [[AudioFileReader alloc]
                initWithAudioFileURL:inputFileURL
                        samplingRate:(float) self.audioManager.samplingRate
                         numChannels:self.audioManager.numOutputChannels];
    }

    return self;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    [self createImagePicker];

    CGRect overlayFrame = [self.imagePicker.view frame];
    UIView *cameraOverlayView = [[UIView alloc] initWithFrame:overlayFrame];

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [cameraOverlayView addSubview:imageView];

    self.recordLabel = [[UILabel alloc] init];
    self.recordLabel.text = @"Record >>>";
    [self.recordLabel sizeToFit];
    self.recordLabel.frame = CGRectMake(self.view.bounds.size.width/2-self.recordLabel.frame.size.width/2, self.view.bounds.size.height/2-self.recordLabel.frame.size.height/2,self.recordLabel.frame.size.width,self.recordLabel.frame.size.height);

    [self.recordLabel setUserInteractionEnabled:YES];
    UITapGestureRecognizer *recordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapRecord:)];
    [self.recordLabel addGestureRecognizer:recordGesture];
    [cameraOverlayView addSubview:self.recordLabel];

    self.stopRecordLabel = [[UILabel alloc] init];
    self.stopRecordLabel.text = @"Stop >>>";
    [self.stopRecordLabel sizeToFit];
    self.stopRecordLabel.frame = CGRectMake(self.view.bounds.size.width/2-self.stopRecordLabel.frame.size.width/2, self.view.bounds.size.height/2-self.stopRecordLabel.frame.size.height/2,self.stopRecordLabel.frame.size.width,self.stopRecordLabel.frame.size.height);

    [self.stopRecordLabel setUserInteractionEnabled:YES];

    UITapGestureRecognizer *stopRecordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stopRecord)];
    [self.stopRecordLabel addGestureRecognizer:stopRecordGesture];
    [cameraOverlayView addSubview:self.stopRecordLabel];

    self.imagePicker.cameraOverlayView = cameraOverlayView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.recordLabel setHidden:NO];
    [self.stopRecordLabel setHidden:YES];

    _audioFileURL = [self getEmptyAudioPath];
    _fileWriter = [[AudioFileWriter alloc] initWithAudioFileURL:self.audioFileURL
                                                   samplingRate:(float) (self.audioManager.samplingRate * 14)
                                                    numChannels:self.audioManager.numInputChannels];

    [self presentViewController:self.imagePicker animated:YES completion:nil];
}


- (NSURL *)getEmptyAudioPath {

    NSArray *pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject],
            @"My Recording.m4a"];
    NSURL *fileURL = [NSURL fileURLWithPathComponents:pathComponents];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *filePath = [fileURL path];
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    if(fileExists) {
        NSError *error = nil;
        if(![fileManager removeItemAtPath:filePath error:&error]){
            NSLog(@"[Error] %@ (%@)", error, filePath);
        }
    }
   return fileURL;
}

- (void)createImagePicker {

    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
    self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;

    self.imagePicker.allowsEditing = NO;
    self.imagePicker.showsCameraControls = NO;
    self.imagePicker.cameraViewTransform = CGAffineTransformIdentity;

    //check if the device has a front camera!
    if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront] ) {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }

    self.imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;
    self.imagePicker.delegate = self;
}

- (void)didTapRecord:(id)didTapRecord {

    [self.recordLabel setHidden:YES];
    [self.stopRecordLabel setHidden:NO];

    __weak RootViewController *weakSelf = self;
    self.audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {

        [weakSelf.fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];

    };

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){

        [weakSelf.birdSoundPlayer retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
        if(weakSelf.birdSoundPlayer.currentTime >= 300){
            NSLog(@"the birdsound is finished playing");
            [weakSelf stopRecord];
        }
    }];

    [self.audioManager play];
    [self.birdSoundPlayer play];

    [self.imagePicker startVideoCapture];
}

- (void)stopRecord {
    self.fileWriter = nil;
    self.audioManager.inputBlock = nil;
    self.audioManager.outputBlock = nil;
    [self.imagePicker stopVideoCapture];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    VideoPlayViewController *videoPlayViewController = [[VideoPlayViewController alloc] initWithVideoURL:videoURL audioURL:self.audioFileURL];
    [self.navigationController pushViewController:videoPlayViewController animated:YES];

    [self.birdSoundPlayer pause];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

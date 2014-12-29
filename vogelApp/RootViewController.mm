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
@property(nonatomic, strong) AudioFileReader *fileReader;
@property(nonatomic) RingBuffer *ringBuffer;
@property(nonatomic, strong) Novocaine *audioManager;
@property(nonatomic, strong) AudioFileWriter *fileWriter;

@property(nonatomic, strong) NSURL *audioFileURL;
@end

@implementation RootViewController

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    __weak RootViewController *weakSelf = self;

    self.ringBuffer = new RingBuffer(32768, 2);
    self.audioManager = [Novocaine audioManager];

    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"bird_1" withExtension:@"wav"];

    self.fileReader = [[AudioFileReader alloc]
            initWithAudioFileURL:inputFileURL
                    samplingRate:(float) self.audioManager.samplingRate
                     numChannels:self.audioManager.numOutputChannels];

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
    {
        [weakSelf.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
    }];

    NSArray *pathComponents = [NSArray arrayWithObjects:
            [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject],
            @"My Recording.m4a",
                    nil];
    self.audioFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSLog(@"URL: %@", self.audioFileURL);

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *filePath = [self.audioFileURL path];
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
     if(fileExists) {
         NSError *error = nil;
         if(![fileManager removeItemAtPath:[self.audioFileURL path] error:&error]){
             NSLog(@"[Error] %@ (%@)", error, filePath);
         }
     }


    self.fileWriter = [[AudioFileWriter alloc] initWithAudioFileURL:self.audioFileURL
                                                       samplingRate:(float) (self.audioManager.samplingRate * 14)
                                                        numChannels:self.audioManager.numInputChannels];


    NSLog(@"samplingrate %f", self.audioManager.samplingRate);

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

    self.imagePicker.cameraOverlayView = cameraOverlayView;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
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
    [self.imagePicker startVideoCapture];

    __weak RootViewController *weakSelf = self;
    __block int counter = 0;
    self.audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];
        counter += 1;
        if (counter > 1600) { // roughly 10 seconds of audio at double speed
            weakSelf.fileWriter = nil;
            weakSelf.audioManager.inputBlock = nil;
            [weakSelf stopRecord];
        }
    };

    [self.audioManager play];
    [self.fileReader play];

}

- (void)stopRecord {
    [self.imagePicker stopVideoCapture];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    VideoPlayViewController *videoPlayViewController = [[VideoPlayViewController alloc] initWithVideoURL:videoURL audioURL:self.audioFileURL];
    [self.navigationController pushViewController:videoPlayViewController animated:YES];

    [self.fileReader pause];
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

@end

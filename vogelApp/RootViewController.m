//
//  RootViewController.m
//  vogelApp
//
//  Created by Marijn Schilling on 17/11/14.
//  Copyright (c) 2014 marijn. All rights reserved.
//

#import "RootViewController.h"
#import "VideoPlayViewController.h"

@interface RootViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) UIImagePickerController * imagePicker;
@property(nonatomic, strong) UILabel *stopRecordLabel;
@property(nonatomic, strong) UILabel *recordLabel;

@property(nonatomic, strong) VideoPlayViewController *videoPlayViewController;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    [self createImagePicker];

    CGRect overlayFrame = [self.imagePicker.view frame];
    UIView * cameraOverlayView = [[UIView alloc] initWithFrame:overlayFrame];

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
    self.stopRecordLabel.text = @"Stop";
    self.stopRecordLabel.textColor = [UIColor redColor];
    [self.stopRecordLabel sizeToFit];
    self.stopRecordLabel.frame = CGRectMake(self.view.bounds.size.width/2-self.stopRecordLabel.frame.size.width/2, self.view.bounds.size.height/2-self.stopRecordLabel.frame.size.height/2,self.stopRecordLabel.frame.size.width,self.stopRecordLabel.frame.size.height);
    [self.stopRecordLabel setHidden:YES];

    [self.stopRecordLabel setUserInteractionEnabled:YES];
    UITapGestureRecognizer *stopRecordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapStopRecord:)];
    [self.stopRecordLabel addGestureRecognizer:stopRecordGesture];
    [cameraOverlayView addSubview:self.stopRecordLabel];

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
    [self.stopRecordLabel setHidden:NO];
    [self.imagePicker startVideoCapture];
}

- (void)didTapStopRecord:(id)didTapStopRecord {

    [self.stopRecordLabel setHidden:YES];
    [self.imagePicker stopVideoCapture];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [picker dismissViewControllerAnimated:YES completion:^{
//        self.imagePicker = nil;
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        VideoPlayViewController *videoPlayViewController = [[VideoPlayViewController alloc] initWithURL:videoURL];
        [self.navigationController pushViewController:videoPlayViewController animated:YES];
    }];
}

@end

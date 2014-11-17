//
//  RootViewController.m
//  vogelApp
//
//  Created by Marijn Schilling on 17/11/14.
//  Copyright (c) 2014 marijn. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@property(nonatomic, strong) UIImagePickerController * imagePicker;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createImagePicker];
}

- (void)viewDidAppear:(BOOL)animated
{
    CGRect overlayFrame = [self.imagePicker.view frame];
    UIView * cameraOverlayView = [[UIView alloc] initWithFrame:overlayFrame];

    UIImage *image = [UIImage imageNamed:@"cameraOverlay"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [cameraOverlayView addSubview:imageView];

    [self presentViewController:self.imagePicker animated:animated completion:nil];
    self.imagePicker.cameraOverlayView = cameraOverlayView;
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

@end

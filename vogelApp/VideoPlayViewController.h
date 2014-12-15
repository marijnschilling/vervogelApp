//
// Created by Marijn Schilling on 18/11/14.
// Copyright (c) 2014 marijn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AudioFileWriter;
@class Novocaine;

@interface VideoPlayViewController : UIViewController

- (id)initWithVideoURL:(NSURL *)url audioURL:(NSURL *)audioURL;

@end
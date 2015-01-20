//
//  MainViewController.m
//  LaunchMe
//
//  Created by Matteo Cortonesi on 9/8/12.
//  Copyright (c) 2012 Matteo Cortonesi. All rights reserved.
//

#import "MainViewController.h"

#import <CoreMotion/CoreMotion.h>

@interface MainViewController ()
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (nonatomic, assign) BOOL ignore;
@property (nonatomic, assign) BOOL flying;
@property (nonatomic, strong) NSDate *launchDate;
@property (nonatomic, assign) double previousAccelerationValue;
@property (nonatomic, assign) double maxHeightPixels;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *scoreView;
@property (nonatomic, assign) double maxHeightMeters;
@property (nonatomic, assign) double screenHeight;
@property (weak, nonatomic) IBOutlet UIButton *seeMyScoreButton;
@property (nonatomic, assign) double h;
@property (weak, nonatomic) IBOutlet UIView *tooltipView;
@property (weak, nonatomic) IBOutlet UILabel *heightLabel;
@property (weak, nonatomic) IBOutlet UIImageView *planeView;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.ignore = YES;
    self.maxHeightPixels = self.backgroundView.bounds.size.height;
    self.screenHeight = 480 - [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect frame = self.backgroundView.frame;
    frame.origin.y = -self.maxHeightPixels + self.screenHeight;
    self.backgroundView.frame = frame;
    self.maxHeightMeters = 3.0;
    self.seeMyScoreButton.hidden = YES;
    
    UIImage *buttonBg = [[UIImage imageNamed:@"throw_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [self.seeMyScoreButton setBackgroundImage:buttonBg forState:UIControlStateNormal];
    [self.button setBackgroundImage:buttonBg forState:UIControlStateNormal];
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self handleAccelerometerData:accelerometerData.acceleration];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonTapped:(id)sender {
    self.button.hidden = YES;
    self.ignore = NO;
    CGRect frame = self.backgroundView.frame;
    frame.origin.y = -self.maxHeightPixels + self.screenHeight;
    self.backgroundView.frame = frame;
    
    frame = self.backgroundView.frame;
    frame.origin.y = -self.maxHeightPixels + self.screenHeight;
    self.backgroundView.frame = frame;
    self.tooltipView.hidden = YES;
    self.planeView.hidden = YES;
}

- (IBAction)seeMyScoreButtonTapped:(id)sender {
    double feet = 3.281 * self.h;
    double roundedFeet = floor(feet);
    double roundedInches = floor((feet - roundedFeet) * 12);

    CGRect frame = self.tooltipView.frame;
    self.tooltipView.hidden = NO;
    frame.origin.y = self.maxHeightPixels;
    self.tooltipView.frame = frame;
    self.planeView.hidden = NO;
    self.seeMyScoreButton.hidden = YES;
    self.seeMyScoreButton.enabled = NO;
    
    [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.backgroundView.frame;
        if (self.h/self.maxHeightMeters < self.screenHeight/self.maxHeightPixels) {
            frame.origin.y = -self.maxHeightPixels + self.screenHeight;
        } /*else if (self.h/self.maxHeightMeters > (self.maxHeightPixels - self.screenHeight)/self.maxHeightPixels) {
            frame.origin.y = 0;
        } */else {
            frame.origin.y = -self.maxHeightPixels + self.h/self.maxHeightMeters * self.maxHeightPixels;
        }
        self.backgroundView.frame = frame;
        
        frame = self.tooltipView.frame;
        frame.origin.y = self.maxHeightPixels - self.h / self.maxHeightMeters * self.maxHeightPixels + self.planeView.bounds.size.height;
        self.tooltipView.frame = frame;
        self.heightLabel.text = [NSString stringWithFormat:@"%.0lf' %.0lf''", roundedFeet, roundedInches];
    } completion:^(BOOL finished) {
        self.button.hidden = NO;
        CGRect frame = self.planeView.frame;
        frame.origin.y = self.maxHeightPixels - self.h / self.maxHeightMeters * self.maxHeightPixels;
        frame.origin.x = 320;
        self.planeView.frame = frame;
        [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            CGRect frame = self.planeView.frame;
            frame.origin.x = 10;
            self.planeView.frame = frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                CGRect frame = self.planeView.frame;
                frame.origin.x = - 90;
                self.planeView.frame = frame;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    CGRect frame = self.planeView.frame;
                    frame.origin.x = -frame.size.width;
                    self.planeView.frame = frame;
                } completion:^(BOOL finished) {
                    
                }];
            }];
        }];
    }];
}

- (void)handleAccelerometerData:(CMAcceleration)anAcceleration {
    double x, y, z;
    x = anAcceleration.x;
    y = anAcceleration.y;
    z = anAcceleration.z;
    double norm = sqrt(x*x + y*y + z*z);
    if (!self.ignore) {
        if (self.flying) {
            if (norm > 1) {
                // Somebody catched the iPhone
                self.flying = NO;
                NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.launchDate];
                // Compute height
                self.h = 9.80665 * time * time / 8;
                
                self.seeMyScoreButton.hidden = NO;
                [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(seeMyScore:) userInfo:nil repeats:NO];
                
                self.ignore = YES;
            }
        } else {
            if (self.previousAccelerationValue - norm >= 0.35 && norm < 0.7) {
                // The iPhone just took off
                self.launchDate = [NSDate date];
                self.flying = YES;
                self.seeMyScoreButton.enabled = NO;
//                [self.textViewContent appendFormat:@"\n***FLYING***\n\n"];
            }
        }
    }
    
//    [self.textViewContent appendFormat:@"%lf\n", norm];
    
    self.previousAccelerationValue = norm;
}

- (void)seeMyScore:(id)sender {
    self.seeMyScoreButton.enabled = YES;
}

@end

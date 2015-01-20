//
//  ViewController.m
//  LaunchMe
//
//  Created by Matteo Cortonesi on 9/8/12.
//  Copyright (c) 2012 Matteo Cortonesi. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface ViewController () <UIAccelerometerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *heightLabel;
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, assign) double previousAccelerationValue;
@property (nonatomic, strong) NSDate *launchDate;
@property (nonatomic, assign) BOOL flying;
@property (nonatomic, assign) BOOL ignore;

@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (nonatomic, assign) NSUInteger count;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSMutableString *textViewContent;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textViewContent = [NSMutableString new];
    self.motionManager = [[CMMotionManager alloc] init];
    self.ignore = YES;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self handleAccelerometerData:accelerometerData.acceleration];
    }];
}
- (IBAction)startButtonTapped:(id)sender {
    self.textViewContent = [NSMutableString new];
    self.ignore = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                double h = 9.80665 * time * time / 8;
                double feet = 3.281 * h;
                double roundedFeet = floor(feet);
                double roundedInches = round((feet - roundedFeet) * 12);
                self.heightLabel.text = [NSString stringWithFormat:@"%.0lf' %.0lf''; %.0lf cm", roundedFeet, roundedInches, round(h * 100)];
                self.countLabel.text = [NSString stringWithFormat:@"%d", ++self.count];
                self.textView.text = self.textViewContent;
                self.textViewContent = [NSMutableString new];
                self.ignore = YES;
            }
        } else {
            if (self.previousAccelerationValue - norm >= 0.35 && norm < 0.7) {
                // The iPhone just took off
                self.launchDate = [NSDate date];
                self.flying = YES;
                [self.textViewContent appendFormat:@"\n***FLYING***\n\n"];
            }
        }
    }
    
    [self.textViewContent appendFormat:@"%lf\n", norm];
    
    self.previousAccelerationValue = norm;
}

@end

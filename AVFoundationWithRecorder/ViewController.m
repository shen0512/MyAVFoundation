//
//  ViewController.m
//  AVFoundationWithRecorder
//
//  Created by 沈志勳 on 2021/6/13.
//

#import "ViewController.h"
#import "MyCamera.h"

@interface ViewController ()<MyCamerDelegate>
@property (nonatomic) MyCamera *myCamera;
@property (nonatomic) NSInteger clickCount;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myCamera = [[MyCamera alloc] init];
    self.myCamera.delegate = self;
    self.recordStatus = 0;
    self.clickCount = 0;
}

- (void)viewDidAppear:(BOOL)animated{
    [self.myCamera startCapture];
}

#pragma mark MyCamer-delegate
- (void)getFrame:(UIImage *)frame{
    dispatch_async(dispatch_get_main_queue(), ^(){
        _imageView.image = frame;
    });
}

- (void)getAlertMsg:(NSString *)msg{
    NSLog(@"%@", msg);
}

- (IBAction)recordClick:(id)sender {
    self.clickCount += 1;
    self.clickCount %= 2;
    if(self.clickCount){
        [self.myCamera startRecord];
    }else{
        [self.myCamera stopRecord];
    }
}

@end

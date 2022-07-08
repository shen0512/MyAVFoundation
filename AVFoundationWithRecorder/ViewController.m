//
//  ViewController.m
//  AVFoundationWithRecorder
//
//  Created by 沈志勳 on 2021/6/13.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupCamera];
    [_captureSession startRunning];
    
    self.recordStatus = 0;
}

- (void)setupCamera{
    // Do any additional setup after loading the view.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    [_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureVideoDataOutput *captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureSession addOutput:captureVideoDataOutput];
    
    AVCaptureConnection *connection = [captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeStandard];
    
    // Create a new serial dispatch queue.
    [captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
}

- (void)setupRecorder{
    NSError *error = nil;
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = pathDocuments[0];
    
    self.videoOutPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", arc4random() % 1000]] stringByAppendingPathExtension:@"mp4"];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    
    NSNumber* width= @1080;
    NSNumber* height = @1920;
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @([width intValue]* [height intValue]* 11.4)};
    
    
    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : width,
                                    AVVideoHeightKey                : height};

    self.assertWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    if([self.assetWriter canAddInput:self.assertWriterInput]){
        [self.assetWriter addInput:self.assertWriterInput];
        [self.assertWriterInput setExpectsMediaDataInRealTime:YES];
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    dispatch_sync(dispatch_get_main_queue(), ^(){
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext createCGImage:ciImage
                                                       fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
            
        UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        
        _imageView.image = uiImage;
        
        if(self.recordStatus == 1){
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            self.recordStatus = 2;
        }else if(self.recordStatus == 2 && self.assertWriterInput.isReadyForMoreMediaData){
            [self.assertWriterInput appendSampleBuffer:sampleBuffer];
        }
        
    });
}
- (IBAction)recordClick:(id)sender {
    UIButton *button = (UIButton*)sender;
    
    if(self.recordStatus == 0){
        NSLog(@"start record");
        
        [self setupRecorder];
        self.recordStatus = 1;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
    }else{
        NSLog(@"end record");
        
        self.recordStatus = 0;
        
        [self.assertWriterInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            NSLog(@"video path: %@", self.videoOutPath);
            
            self.assertWriterInput = nil;
            self.assetWriter = nil;
            self.videoOutPath = nil;
        }];
        
        [button setTitle:@"Record" forState:UIControlStateNormal];
    }
}

@end

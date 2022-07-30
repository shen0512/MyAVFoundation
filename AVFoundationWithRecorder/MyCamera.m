//
//  MyCamera.m
//  AVFoundationWithRecorder
//
//  Created by Shen on 2022/7/9.
//

#import "MyCamera.h"

typedef NS_ENUM(NSInteger, RecorderStatus){
    prepareRecord = 0,
    willRecord = 1,
    didRecord = 2,
};

@interface MyCamera()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;

@property (nonatomic) BOOL isFrontLens;
@property (nonatomic) BOOL isOpenFlash;
@property (nonatomic) NSArray *sessionPresetList;
@property (nonatomic) AVCaptureSessionPreset sessionPreset;
@property (nonatomic) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;
@property (nonatomic) NSString *videoPath;
@property (atomic) BOOL isRecording;
@property (nonatomic) RecorderStatus recorderStatus;

@end

@implementation MyCamera

- (instancetype)init{
    self = [super init];
    
    self.sessionPresetList = @[AVCaptureSessionPreset1920x1080,
                               AVCaptureSessionPreset640x480,
                               AVCaptureSessionPresetLow,
                               AVCaptureSessionPresetMedium,
                               AVCaptureSessionPresetHigh];
    
    [self changeResolution:AVCaptureSessionPreset640x480];
    self.width = 640;
    self.height = 480;
    
    [self changeVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    return self;
}


#pragma mark setting
- (void)cameraInit{
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDeviceInput *input;
    if(self.isFrontLens){
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    }else{
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
        
        
    }
    [self.captureSession addInput:input];
    
    if([self.captureSession canSetSessionPreset:self.sessionPreset]){
        [self.captureSession setSessionPreset:self.sessionPreset];
    }else{
        if([self.delegate respondsToSelector:@selector(getAlertMsg:)]){
            [self.delegate getAlertMsg:@"不支援的解析度"];
        }
    }
    
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureVideoDataOutput *captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureSession addOutput:captureVideoDataOutput];
    
    AVCaptureConnection *connection = [captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeStandard];
    
    // Create a new serial dispatch queue.
    [captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
}

- (void)startCapture{
    if(self.captureSession == nil){
        [self cameraInit];
    }else{
        if([self.captureSession isRunning]){
            [self.captureSession stopRunning];
        }
    }
    
    [self.captureSession startRunning];
}

- (void)stopCapture{
    if([self.captureSession isRunning]){
        [self.captureSession stopRunning];
    }
}

- (void)changeLens:(BOOL)isFrontLens{
    if([self.captureSession isRunning]){
        [self.captureSession stopRunning];
    }
    
    self.isFrontLens = isFrontLens;
}

- (void)changeResolution:(AVCaptureSessionPreset)sessionPreset{
    
    BOOL inSessionPresetList = [self checkResolution:sessionPreset];
    if(inSessionPresetList){
        if([self.captureSession isRunning]){
            [self.captureSession stopRunning];
        }
        
        self.sessionPreset = sessionPreset;
    }else{
        if([self.delegate respondsToSelector:@selector(getAlertMsg:)]){
            [self.delegate getAlertMsg:@"不支援的解析度"];
        }
    }
    
}

- (BOOL)checkResolution:(AVCaptureSessionPreset)sessionPreset{
    
    BOOL inSessionPresetList = NO;
    for(AVCaptureSessionPreset tmpSessionPreset in self.sessionPresetList){
        if([tmpSessionPreset isEqualToString:sessionPreset]){
            inSessionPresetList = YES;
            break;
        }
    }
    
    
    return inSessionPresetList;
}

- (void)changeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation{
    if([self.captureSession isRunning]){
        [self.captureSession stopRunning];
    }
    
    self.videoOrientation = videoOrientation;
}


- (void)getResolutionList{
    NSLog(@"resolution support list: %@", self.sessionPresetList);
}

#pragma mark delegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
//    [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    
    dispatch_sync(dispatch_get_main_queue(), ^(){
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext createCGImage:ciImage
                                                       fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
        
        UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
        UIInterfaceOrientation interfaceOrientation = [[[[[UIApplication sharedApplication] windows] firstObject] windowScene]interfaceOrientation];
        switch(interfaceOrientation){
            case UIInterfaceOrientationLandscapeLeft:
                if(self.recorderStatus == prepareRecord){
                    [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                }
                break;
            
            case UIInterfaceOrientationPortraitUpsideDown:
                if(self.recorderStatus == prepareRecord){
                    [connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                }
                break;
            
            case UIInterfaceOrientationLandscapeRight:
                if(self.recorderStatus == prepareRecord){
                    [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                }
                break;
                
            case UIInterfaceOrientationPortrait:
            default:
                if(self.recorderStatus == prepareRecord){
                    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
                
                break;
                
        }
        CGImageRelease(videoImage);
        
        if(self.recorderStatus == willRecord){
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            self.recorderStatus = didRecord;
        }
        
        if(self.recorderStatus == didRecord){
            [self.assetWriterInput appendSampleBuffer:sampleBuffer];
        }
        
        
        if([self.delegate respondsToSelector:@selector(getFrame:)]){
            [self.delegate getFrame:uiImage];
        }

    });
}

#pragma mark recorder
- (void)recorderInit{
    self.recorderStatus = prepareRecord;
    
    // get video output path
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = [pathDocuments firstObject];
    self.videoPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", arc4random() % 1000]] stringByAppendingPathExtension:@"mp4"];
    
    //
    NSError *error = nil;
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.videoPath] fileType:AVFileTypeMPEG4 error:&error];
    if(error){
        if([self.delegate respondsToSelector:@selector(getAlertMsg:)]){
            [self.delegate getAlertMsg:@"assetWriter error"];
        }
    }
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(self.width* self.height* 11.4)};


    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : @(self.width),
                                    AVVideoHeightKey                : @(self.height)};

    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    if([self.assetWriter canAddInput:self.assetWriterInput]){
        self.recorderStatus = willRecord;
        
        [self.assetWriter addInput:self.assetWriterInput];
        [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    }else{
        if([self.delegate respondsToSelector:@selector(getAlertMsg:)]){
            [self.delegate getAlertMsg:@"錄影設置錯誤"];
        }
    }

}

- (void)startRecord{
    [self recorderInit];
    if(self.recorderStatus == willRecord){
        [self.assetWriter startWriting];
    }
    
}

- (void)stopRecord{
    if(self.recorderStatus == didRecord){
        self.recorderStatus = prepareRecord;
        
        [self.assetWriterInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            NSLog(@"video path: %@", self.videoPath);

            self.assetWriterInput = nil;
            self.assetWriter = nil;
            self.videoPath = nil;
        }];
    }
}

@end

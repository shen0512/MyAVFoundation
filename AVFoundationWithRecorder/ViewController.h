//
//  ViewController.h
//  AVFoundationWithRecorder
//
//  Created by 沈志勳 on 2021/6/13.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assertWriterInput;

@property int recordStatus; //0->no, 1->init ,2->start record
@property (strong, nonatomic) NSString *videoOutPath;

@end


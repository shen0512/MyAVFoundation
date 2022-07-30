//
//  MyCamera.h
//  AVFoundationWithRecorder
//
//  Created by Shen on 2022/7/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AVFoundation/AVFoundation.h"
#import "CoreMedia/CoreMedia.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MyCamerDelegate <NSObject>
- (void)getFrame:(UIImage*)frame;
- (void)getAlertMsg:(NSString*)msg;

@end

@interface MyCamera : NSObject
@property (nonatomic) id<MyCamerDelegate> delegate;

- (instancetype)init;
- (void)startCapture;
- (void)stopCapture;
- (void)changeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;
- (void)startRecord;
- (void)stopRecord;
@end

NS_ASSUME_NONNULL_END

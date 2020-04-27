/*
 NSCameraOption.mm
 
 Created by Xuexing.Zheng on 7/27/15.
 Copyright © 2015 Authen. All rights reserved.
 */

#import "NSCameraOption.h"

#define kCSystemVersion ([[[UIDevice currentDevice] systemVersion] floatValue]) //当前系统版本

//2015.06.19 update
struct VideoRecording {
    int     VideoWriting      = -1;     //-1表示没有开始,1表示可以开始,开始后设置为0,结束后设置为-1
    float   maxRecordingTime  = 30.0;   //录像时长上限
    float   minRecordingTime  = 5.0;    //录像时长下限
    /*
     canStopRecording 可以取消录像, 该属性针对如下情况设置: 
     活体的动作检测只进行了1秒, 而录像至少需要3秒, 此时需要继续进行扫描录像, 直到录像时长达到最低时长限制;
     在启动录像时, 将该属性设置为false, 录像时长达到最低时长限制设置为true
     */
    BOOL    canStopRecording  = TRUE;   //可以终止录像
};
typedef VideoRecording VideoRecording;



@interface NSCameraOption () {
    
    AVCaptureSession            * _session;
    AVCaptureDeviceInput        * _captureInput;
    AVCaptureStillImageOutput   * _captureImageOutput;
    AVCaptureVideoDataOutput    * _videoOutput;
    AVCaptureVideoPreviewLayer  * _preview;
    AVCaptureDevice             * _device;
    
    
    //2015.06.14 update
    AVAssetWriter               * _videoWriter; //写视频
    AVAssetWriterInput          * _videoWriterInput; //写视频输入
    AVAssetWriterInputPixelBufferAdaptor * _adaptor; //适配器
    
    VideoRecording _recording; //录像相关配置
}

@property(nonatomic, strong) CALayer * customLayer; //camera layer层

/**
 时间: 2015.06.14
 用途: 初始化视频录制相关内容
 **/
- (void) initVideoAudioWriter;

@end



@implementation NSCameraOption


/**
 时间: 2015.07.27, 2015.07.28(添加了对 ios6 的支持)
 用途: 检查摄像头权限, 使用该方法时需要实现 AmCameraDelegate 的 - (void)cameraWithAutority:(OSStatus)status; 方法
 status 值为 -1 表示权限获取失败, 0 表示应该提示用户如何为app打开权限, 1 表示权限获取成功, 2 表示当前环境受限, 无法调用摄像头
 **/
- (void) checkCameraAuthority {
    
    if (kCSystemVersion < 7.0) {
            
        //摄像头授权获取结果, 1 表示权限获取成功
        [_delegate cameraWithAutority:1];
        return;
    }
    
    //ios 7.0 +
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if(authStatus == AVAuthorizationStatusRestricted)
    {
        //摄像头授权获取结果, 2 表示当前环境受限, 无法调用摄像头
        [_delegate cameraWithAutority:2];
    }
    else if(authStatus == AVAuthorizationStatusDenied)
    {
        //摄像头授权获取结果, 0 表示应该提示用户如何为app打开权限
        [_delegate cameraWithAutority:0];
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             if (!granted) //获取授权失败
             {
                 //摄像头授权获取结果, -1 表示权限获取失败
                 [_delegate cameraWithAutority:-1];
             }
             else //获取授权成功
             {
                 //摄像头授权获取结果, 1 表示权限获取成功
                 [_delegate cameraWithAutority:1];
             }
         }];
    }
    else if(authStatus == AVAuthorizationStatusAuthorized) //允许访问
    {
        //摄像头授权获取结果, 1 表示权限获取成功
        [_delegate cameraWithAutority:1];
    }
}


/**
 时间: 2015.07.27
 用途: 生成 AVCaptureSession 对象, 用于采集摄像头输出照片和视频采集
 使用: 在使用此方法前, 必须要设置显示视频流视图界面(cameraView), 在获取到 session 之后, 需要使用 - (void)startCameraVideoSession; 方法启动session
 **/
- (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView {

    //1.创建会话层
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPreset640x480];
    
    NSError * error = nil;
    
    //2.创建、配置输入设备
    NSArray *devices;
    devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            [device lockForConfiguration:&error];
            _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            [device unlockForConfiguration];
            if (error) {
                printf("%s error:%s\n\n", __FUNCTION__, [error.description UTF8String]);
            }
        }
    }
    
    if (!_captureInput)
        return nil;
    
    [_session addInput:_captureInput];
    
    
    //data out put
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    
    _queue = dispatch_queue_create("cameraQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue:_queue];
    
    
    NSDictionary * videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:((NSString*)kCVPixelBufferPixelFormatTypeKey)];
    [_videoOutput setVideoSettings:videoSettings];
    [_session addOutput:_videoOutput];
    
    
    //3.创建、配置输出
//    _captureImageOutput = [[AVCaptureStillImageOutput alloc] init];
//    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
//    [_captureImageOutput setOutputSettings:outputSettings];
//    [_session addOutput:_captureImageOutput];

    
    _preview = [AVCaptureVideoPreviewLayer layerWithSession: _session];
    _preview.frame = CGRectMake(0, 0, cameraView.frame.size.width, cameraView.frame.size.height);
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [cameraView.layer addSublayer:_preview];
    
    return _session;
}


/**
 时间: 2015.07.28
 用途: 启动 - (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView; 方法创建的 AVCaptureSession 对象, 开始视频扫描
 **/
- (void)startCameraVideoSession {
    [_session startRunning];
}


/**
 时间: 2015.07.28
 用途: 停止 - (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView; 方法创建的 AVCaptureSession 对象, 终止视频扫描;
 如果此前调用了 - (void) startVideoWriting; 方法, 需要在调用本方法前调用 - (void) stopVideoWriting; 方法终止视频写入, 以防报错
 **/
- (void)stopCameraVideoSession {

    if (_recording.VideoWriting != -1) { //视频没有终止, 终止视频
        [self stopVideoWriting];
    }
    
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}


/**
 时间: 2015.06.14
 用途: 初始化视频录制相关内容
 **/
- (void) initVideoAudioWriter
{
    CGSize size = CGSizeMake(480, 320);
    
    //视频存储路径 demo
    NSString *compressionDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];
    
    NSError *error = nil;
    
    unlink([compressionDir UTF8String]);
    
    //----initialize compression engine
    _videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:compressionDir]
                                             fileType:AVFileTypeQuickTimeMovie //设置编码格式
                                                error:&error];
//    _videoWriter.movieFragmentInterval = CMTimeMake(1, _kFramePerSec);
//    NSParameterAssert(_videoWriter);
    
    if(error)
        printf("error = %s\n\n", [[error localizedDescription] UTF8String]);
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:128.0*1024.0], AVVideoAverageBitRateKey,
                                           nil ];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
//    NSParameterAssert(_videoWriterInput);
    
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
//    NSParameterAssert(_videoWriterInput);
//    NSParameterAssert([_videoWriter canAddInput:_videoWriterInput]);
    
    if ([_videoWriter canAddInput:_videoWriterInput])
        printf("I can add this input\n\n");
    
    [_videoWriter addInput:_videoWriterInput];
}


/**
 时间: 2015.07.27
 用途: 开始录像前的基本设置, 使得程序开始录像
 **/
- (void) startVideoWriting {
    
    [self initVideoAudioWriter]; //初始化视频音频输出, 2015.06.14 update
    
    _recording.VideoWriting = 1; //开始对过程录像
    _recording.canStopRecording = FALSE;
    
    //可以终止录像
    [NSTimer scheduledTimerWithTimeInterval:_recording.minRecordingTime target:self selector:@selector(setCanStopVideoWriting) userInfo:nil repeats:NO];
    
    //终止录像
    [NSTimer scheduledTimerWithTimeInterval:_recording.maxRecordingTime target:self selector:@selector(stopVideoWriting) userInfo:nil repeats:NO];
}



/**
 时间: 2015.07.27
 用途: 获得是否可以停止录像参数状态
 **/
- (BOOL) canStopVideoWriting {
    
    return _recording.canStopRecording;
}



/**
 时间: 2015.07.27
 用途: 设置可以停止录像
 **/
- (void) setCanStopVideoWriting {
    _recording.canStopRecording = TRUE;
}



/**
 时间: 2015.07.27
 用途: 进行停止录像相关设置, 需要ios 6.0+
 **/
- (void) stopVideoWriting {
    
    if (_recording.VideoWriting == 0) { //视频正在写入
        
        _recording.VideoWriting = -1;
        
        dispatch_async(dispatch_get_main_queue(), ^() { //_queue
            //ios 6.0+
            [_videoWriterInput markAsFinished];
            [_videoWriter finishWritingWithCompletionHandler:^() {
                if (AVAssetWriterStatusCompleted == _videoWriter.status)
                    printf("writing success to %s\n\n", [[_videoWriter.outputURL absoluteString] UTF8String]);
                else if (AVAssetWriterStatusFailed == _videoWriter.status)
                    printf ("writer failed with error: %s\n\n", [_videoWriter.error.description UTF8String]);
                
                _videoWriter = nil;
                _videoWriterInput = nil; //写视频输入
                _adaptor = nil; //适配器
            }];
        });
    }
}



/**
 时间: 2015.07.27
 用途: 将mov视频文件转换成mp4文件
 **/
- (void)convertMOV2MP4 {
    
    NSString * _movPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];    //mov视频存储路径
    NSString * _mp4Path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];    //mp4视频存储路径

    NSFileManager * fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:_movPath]) { //文件不存在
        return;
    }
    
    NSError * _error = nil;
    
    if ([fm fileExistsAtPath:_mp4Path]) { //mp4文件存在
        [fm removeItemAtPath:_mp4Path error:&_error];
        if (_error) {
            [fm removeItemAtPath:_mp4Path error:&_error];
        }
    }
    
    NSURL * _videoURL = [NSURL fileURLWithPath:_movPath];
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:_videoURL options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    NSString * _mp4Quality = AVAssetExportPresetHighestQuality;

    if ([compatiblePresets containsObject:_mp4Quality])
    {
        AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset
                                                                              presetName:_mp4Quality];
        exportSession.outputURL = [NSURL fileURLWithPath: _mp4Path];
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    printf("++++++++++++++++ convert failed ++++++++++++++++\n\n");
                    break;
                    
                case AVAssetExportSessionStatusCancelled:
                    printf("++++++++++++++++ convert cancelled ++++++++++++++++\n\n");
                    break;
                    
                case AVAssetExportSessionStatusCompleted:
                    printf("++++++++++++++++ convert Successful! ++++++++++++++++\n\n");
                    break;
                    
                default:
                    break;
            }
        }];
    }
    else
    {
        printf("++++++++++++++++ convert error ++++++++++++++++\n\n");
        //设备不包含设置的目标文件mp4质量
    }
}


#pragma mark - 从摄像头缓冲区获取图像
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    //音频写入与视频写入操作流程类似
    /////////////////////////2015.06.14 视频写入 start/////////////////////////

    CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if(_recording.VideoWriting == 1 && _videoWriter.status != AVAssetWriterStatusWriting)
    {
        [_videoWriter startWriting];
        [_videoWriter startSessionAtSourceTime:lastSampleTime];
        _recording.VideoWriting = 0; //正在写入视频
    }
    
    if (_recording.VideoWriting == 0 && captureOutput == _videoOutput)
    {
        if(_videoWriter.status > AVAssetWriterStatusWriting)
        {
            if(_videoWriter.status == AVAssetWriterStatusFailed)
                printf("Error: %s\n\n", [_videoWriter.error.description UTF8String]);
            
            return;
        }

        if ([_videoWriterInput isReadyForMoreMediaData])
        {
            if(![_videoWriterInput appendSampleBuffer:sampleBuffer])
                printf("Unable to write to video input\n\n");
        }
    }
    /////////////////////////2015.06.14 视频写入 end/////////////////////////
 
    [_delegate sessionOutputSampleBuffer:sampleBuffer];
}

@end

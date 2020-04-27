/*
 AmCameraOption.h
 
 Created by Xuexing.Zheng on 7/27/15.
 Copyright © 2015 Authen. All rights reserved.
 */

#import <Foundation/Foundation.h>

//需引入包含 "AVCaptureVideoDataOutputSampleBufferDelegate"的 AVFoundation.framework
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


@protocol AmCameraDelegate <NSObject>

@optional

/**
 时间: 2015.07.27
 用途: 提供从摄像头获取的视频流
 **/
- (void)sessionOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;


/**
 时间: 2015.07.27
 用途: 获取摄像机授权结果, 该方法的实现与 NSCameraOption 类的 - (void) checkCameraAuthority; 方法绑定使用
 **/
- (void)cameraWithAutority:(OSStatus)status;

@end



NS_CLASS_AVAILABLE_IOS(6_0) @interface NSCameraOption : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, retain) id<AmCameraDelegate>delegate; //摄像头操作协议

@property(nonatomic, readonly) dispatch_queue_t queue; //创建摄像机队列


/**
 时间: 2015.07.27, 2015.07.28(添加了对 ios6 的支持)
 用途: 检查摄像头权限, 使用该方法时需要实现 AmCameraDelegate 的 - (void)cameraWithAutority:(OSStatus)status; 方法
          status 值为 -1 表示权限获取失败, 0 表示应该提示用户如何为app打开权限, 1 表示权限获取成功, 2 表示当前环境受限, 无法调用摄像头
 **/
- (void) checkCameraAuthority;


/**
 时间: 2015.07.27
 用途: 生成 AVCaptureSession 对象, 用于采集摄像头输出照片和视频采集
 使用: 在使用此方法前, 必须要设置显示视频流视图界面(cameraView), 在获取到 session 之后, 需要使用 - (void)startCameraVideoSession; 方法启动session
 **/
- (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView;


/**
 时间: 2015.07.28
 用途: 启动 - (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView; 方法创建的 AVCaptureSession 对象, 开始视频扫描
 **/
- (void)startCameraVideoSession;


/**
 时间: 2015.07.28
 用途: 停止 - (AVCaptureSession*)cameraVideoSessionWithView:(UIView*)cameraView; 方法创建的 AVCaptureSession 对象, 终止视频扫描;
         如果此前调用了 - (void) startVideoWriting; 方法, 需要在调用本方法前调用 - (void) stopVideoWriting; 方法终止视频写入, 以防报错
 **/
- (void)stopCameraVideoSession;


/**
 时间: 2015.07.27
 用途: 开始录像前的基本设置, 使得程序开始录像
 **/
- (void) startVideoWriting;


/**
 时间: 2015.07.27
 用途: 获得是否可以停止录像参数状态
 **/
- (BOOL) canStopVideoWriting;


/**
 时间: 2015.07.27
 用途: 设置可以停止录像
 **/
- (void) setCanStopVideoWriting;


/**
 时间: 2015.07.27
 用途: 进行停止录像相关设置, 需要ios 6.0+
 **/
- (void) stopVideoWriting;


/**
 时间: 2015.07.27
 用途: 将mov视频文件转换成mp4文件
 **/
- (void)convertMOV2MP4;

@end

/*
 AuthenAnti_Spoofing.h
 
 Created by Xuexing.Zheng on 1/13/16.
 Copyright © 2016 Authen. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "CommonVars.h"

//动作检测状态, 2016.01.13
typedef NSInteger DetectState;
NS_ENUM(DetectState) {
    DStateNone    =  0,   //默认值,表示当前阶段检测尚未开始
    DStateSucceed =  1,   //表示当前阶段检测成功
    DStateFailed  = -1,   //表示当前阶段检测失败
};

/**
 时间: 2016.01.13, 2016.01.18
 用途: 检测类型
 **/
typedef NSInteger DetectType;
NS_ENUM(DetectType) {
    DTypeNone    =  0,  //没有检测, 也是检测结束标志
    DTypeNodUp   =  1,  //仰头
    DTypeNodDown =  2,  //点头, unimplemented
    DTypeShakeL  =  4,  //左摇头
    DTypeShakeR  =  8,  //右摇头
    DTypeMouth   = 16,  //张嘴
    DTypeBlink   = 32,  //Eyes Blink
    DTypePrepare = 64,
};

/**
 时间: 2016.01.13, 2016.01.18
 用途: 存储活体检测的结果
 **/
struct DetectResult
{
    bool    isSucceed;      //认证是否成功, default = false, 2018.5.27 mordify
    bool    hasLost;        //是否存在人脸丢失, default = false
    bool    isTimeOut;      //检测是否超时, default = false
    bool    faceNotFound;   //是否发现人脸, default = true
    bool    initFailed;     //初始化失败, 包括活体次数达到限制和key超时两种情形, default = false
    DetectState action[6];  //default = DStateNone, 依次是: 仰头、点头、左摇头、右摇头、张嘴、眨眼
};
typedef struct DetectResult DetectResult;


//活体检测协议方法, 2016.01.13
@protocol AuthenAnti_SpoofingDelegate <NSObject>

/**
 用途: 提供从摄像头获取的、用于进行人脸验证的图像, 当image为nil时, 表示当前为未检测到人脸。
 **/
- (void) faceImageForVerify:(UIImage*)image multiFace:(BOOL)isMultiFace;

/**
 用途: 提供活体检测结果。
 参数: 参数为活体检测的结果结构体, 结构体中包含各阶段检测结果的参数
 **/
- (void) bioAssayResult:(DetectResult)detectResult;

/**
 用途: 在本方法中, 启动等待提示、等待提示结束后、启动后一阶段的检测与提示
 参数: 参数为即将进行的检测类型
 **/
- (void) presentActionTips:(DetectType)detectType isRepeat:(BOOL)isRepeat isSkip:(BOOL)isSkip;

/**
 用途: 当用户的人脸不在指定区域内, 会调用此方法
 参数: 参数的定义参见 CommonVars.h 文件, 参数为当前人脸的边框
 **/
- (void) faceNotInTargetArea:(FaceFrame)flFrame;

/**
 用途: 提供动作幅度, 当动作为左摇头和点头时，动作幅度为负值, not used
 **/
//- (void) actionDegree:(DetectType)detectType degree:(float)degree;

@end


//活体检测类, 2016.01.13
NS_AVAILABLE_IOS(5_0) @interface AuthenAnti_Spoofing : NSObject

@property(nonatomic, strong) id <AuthenAnti_SpoofingDelegate> delegate; //活体检测的协议

@property(nonatomic, assign) float maxActionTime; //各动作时间限制
@property(nonatomic, assign) NSInteger maxActionRepeatCount; //最大动作重复数, 2018.5.17 mordify
@property(nonatomic, assign) NSInteger maxActionSkipCount; //最大动作跳过数, 2018.5.17 mordify

@property(nonatomic, assign) float difficultyLevel; //动作难度, 2016.11.19 mordify

@property(nonatomic, assign) FaceFrame faceFrame; //人脸限制框, 定义参见 CommonVars.h 文件

/*
 存储此次活体检测的动作序列。动作集合及其取值参见 NSActionType, 其中0表示没有动作, 0也被视作检测即将结束。
 比如@[@"0", @"1", @"2"], 表示在检测到人脸后, 先进行仰头检测, 之后是张嘴检测。
 如果开发人员没有进行设置,系统会默认生成一个包含张嘴、眨眼的动作序列组合。
*/
@property(nonatomic, strong) NSMutableArray *actionSequence;

/**
 用途: 启动新阶段的检测处理。方便开发人员根据需要在获取上一阶段完成后、新阶段启动前添加相关活体检测预处理。比如：添加语音操作提示播放等。
 **/
- (void) newDetectAction;

/**
 用途: 从摄像头缓冲区获取图像,以供sdk进行图像分析。
 **/
- (void) imageFromOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/*
 SDK 功能（2016.01.13）
 1.传出的人脸图像具有镜像处理
 2.每个阶段都会捕捉一张图像
 3.摄像头相关处理封装在NSCameraOption类中
 4.sdk支持iOS6及其以上版本的iOS系统
 5.sdk具有动画和语音提示

 SDK 使用（2016.01.13）
 开发人员可以根据需要进行相关设置, 获取相关结果, 基本操作流程如下:
 1.利用 init 方法创建 AuthenAnti_Spoofing 实体对象
 2.设置 AuthenAnti_Spoofing 实体对象的 delegate 协议
 3.根据需要设置 AuthenAnti_Spoofing 实体对象的相关属性和方法, 以达到想要效果
 4.通过 AuthenAnti_Spoofing 实体对象的 delegate 协议获取结果, 进行相关提示操作
 
 详细使用方法请参照 FaceVerifyController 类的相关函数与操作
 
 Constructing pyramid...
 Pyramid level
 cout<<
 */

@end

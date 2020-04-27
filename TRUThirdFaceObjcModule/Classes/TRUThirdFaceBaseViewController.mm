//
//  TRUThirdFaceBaseViewController.m
//  TRUThirdFaceObjcModule_Example
//
//  Created by hukai on 2020/4/27.
//  Copyright © 2020 yeniugo. All rights reserved.
//

#import "TRUThirdFaceBaseViewController.h"

#if TARGET_IPHONE_SIMULATOR
#else
#import <AuthenAnti_SpoofingSDK/AuthenAnti_SpoofingSDK.h>
#import "NSCameraOption.h"
#import "TRUFaceGifView.h"
#import <Masonry/Masonry.h>
#endif

#import <objc/runtime.h>
#define FcameraView CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
#define usingRuntimeProcess NO
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define SCREENH ([UIScreen mainScreen].bounds.size.height)
#define SCREENW ([UIScreen mainScreen].bounds.size.width)
#define TRUEnterBackgroundKey @"TRUEnterBackgroundKey"
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

#if TARGET_IPHONE_SIMULATOR
#else
typedef NSInteger FaceDetectionType;
NS_ENUM(DetectType) {
    FaceDetectionNone    =  0,  //没有检测, 也是检测结束标志
    FaceDetectionWaitResult   =  1,  //开始检测
    FaceDetectionWaitNewDetect =  2  //等待结果
    };
#endif

#if TARGET_IPHONE_SIMULATOR
@interface TRUThirdFaceBaseViewController ()

@end
#else
@interface TRUThirdFaceBaseViewController ()<AmCameraDelegate, AuthenAnti_SpoofingDelegate>{
    BOOL    faceVerifysucceed;
    BOOL    cancelled;          //是否取消过界面
    BOOL    canStopDetection;   //可以取消检测,该属性针对如下情况设置:活体的动作检测只进行了1秒,而录像至少需要3秒
    BOOL    userCancelledVerify;//用户点击了导航栏的返回键, 取消了人脸确认
    BOOL    newAction;          //启动新动作的标志, 要启动新动作检测时设为TRUE, 新动作检测开启后设置为FALSE
    NSInteger actionCount;
    
    NSMutableArray *faceImageArray; //储存活体过程中的输出人脸图像
    AVAudioPlayer  *_audioPlayer; //音频控制
    NSCameraOption *cameraOption;   //摄像头相关操作
    DetectResult dResult;    //活体检测结果
    DetectType  currentAction;  //当前动作类型
    int successTimes; //检测成功次数标记
    UIButton *_voiceButton;//声音按钮开关
    AuthenAnti_Spoofing *Anti_Spoof_Object; //图像处理对象
    CGFloat voiceValue;//音量
    int testCount;//检测数组数量
}
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *cameraView;     //摄像头操作主界面
//@property (nonatomic, strong) UILabel *infoView;       //摄像头获取的各帧图像的显示界面
@property (nonatomic, strong) UIImageView *showView;    //摄像头获取的各帧图像的显示界面
@property (strong, nonatomic) TRUFaceGifView *gifView;       //底部动画视图
@end
#endif
@implementation TRUThirdFaceBaseViewController

#if TARGET_IPHONE_SIMULATOR
- (NSMutableArray *) getActionSequence{
    return [NSMutableArray array];
}
- (void) onDetectSuccessWithImages:(NSMutableArray *) images{
    
}
- (void) onDetectFailWithMessage:(NSString *) message{
    
}
- (void) restartDetection{
    
}
- (void) restartGroupDetection{
    
}
#else
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        faceImageArray = [[NSMutableArray alloc] init];
        newAction = false;
        currentAction = DTypeNone; //默认为没有动作
        
        cameraOption = [[NSCameraOption alloc] init]; //创建摄像头操作对象
        cameraOption.delegate = self;
        canStopDetection  = FALSE;
        userCancelledVerify = FALSE;
        
        //活体检测对象设置 Demo
//        [[LivenessConfig instance] setLivenessObj];
//        [LivenessConfig instance].livenessObj.delegate = self;
        Anti_Spoof_Object = [[AuthenAnti_Spoofing alloc] init];
        Anti_Spoof_Object.delegate = self;
        //Anti_Spoof_Object.faceFrame = {480.0*0.05, 20.0, 480.0*0.95, 640.0*0.95}; //人脸限制区域
        if ([self getActionSequence].count > 0) {
            Anti_Spoof_Object.actionSequence = [self getActionSequence];
//            YCLog(@"ActionSequence = %@",[self getActionSequence]);
            testCount = Anti_Spoof_Object.actionSequence.count-1;
        }
        Anti_Spoof_Object.maxActionRepeatCount = 2;
        Anti_Spoof_Object.maxActionSkipCount = 2;
        Anti_Spoof_Object.difficultyLevel = 3;
        Anti_Spoof_Object.maxActionTime = 5.0;
        cancelled = FALSE;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollView];
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;  //开启保持屏幕唤醒
    self.scrollView.scrollEnabled = NO;
    
    self.navigationController.navigationBarHidden = YES;;
    
    [self.view addSubview:self.gifView];
    
    [self gifView];
    
    
    
#pragma mark - 中间摄像头部分主区域
    //[self.scrollView addSubview:self.cameraView];   //添加cameraView
    //    [self.scrollView addSubview:self.infoView]; //摄像头获取的各帧图像的显示界面
    //[self.scrollView addSubview:self.showView]; //摄像头获取的各帧图像的显示界面
    
}

-(void)enterBackground{
    _audioPlayer.volume = 0.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#pragma mark - 中间摄像头部分主区域
    [self.scrollView addSubview:self.cameraView];   //添加cameraView
    [self.scrollView addSubview:self.showView]; //摄像头获取的各帧图像的显示界面
    [self setUpCancleButton];
    //[self setUpVoiceButton];
#pragma mark - 摄像头初始化
    [cameraOption cameraVideoSessionWithView:_cameraView];  //创建 AVCaptureSession 并启动
    [cameraOption startCameraVideoSession]; //启动扫描
    
    [self newSongWithSongName:@"main"];
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDisappear:) name:@"DismissFaceVerifyController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:TRUEnterBackgroundKey object:nil];
    //延迟4秒说完开始的语音
    [NSTimer scheduledTimerWithTimeInterval:4.0 target:Anti_Spoof_Object selector:@selector(newDetectAction) userInfo:nil repeats:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO; //关闭保持屏幕唤醒
    [self viewDisappear:nil]; //不使用通知模式
}

-(void)viewDisappear:(NSNotification *)note
{
    if ([_audioPlayer isPlaying])
    {
        [_audioPlayer stop];
    }
    //    if ([_audioPlayer isPlaying])
    //    {
    //        [_audioPlayer stop];
    //    }
    
    if (self.gifView.isAnimating)
    {
        [self.gifView stopAnimating];
    }
    _audioPlayer.volume = 0.5;
    userCancelledVerify = TRUE;
    //    [cameraOption setCanStopVideoWriting];  //设置为可以停止录像
    //    [cameraOption stopVideoWriting];        //终止 AVCaptureSession 的录像
    [cameraOption stopCameraVideoSession];  //终止 AVCaptureSession 的扫描
    
    if (note != nil) {
        [self.navigationController popViewControllerAnimated:YES];
//        [HAMLogOutputWindow printLog:@"popViewControllerAnimated"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



//从摄像头缓冲区获取图像 Demo
#pragma mark -
#pragma mark AmCameraDelegate delegate

- (void)sessionOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (newAction) { //启动新的动作检测
        newAction = false;
        [Anti_Spoof_Object newDetectAction];
        //YCLog(@"Anti_Spoof_Object.actionSequence = %@",Anti_Spoof_Object.actionSequence);
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self showActionTips];
        });
    }
    
    if(!canStopDetection) //动作检测没有结束, 继续进行检测
    {
        [Anti_Spoof_Object imageFromOutputSampleBuffer:sampleBuffer];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - 活体检测协议方法
#pragma mark NSBioAssayDelegate

//提供用于对比的人脸图像接口 Demo
-(void)faceImageForVerify:(UIImage *)image multiFace:(BOOL)isMultiFace
{
    if(image == Nil) //未发现人脸相关操作
    {
        //        [cameraOption setCanStopVideoWriting]; //设置为可以停止录像
        return;
    }
    
    [faceImageArray addObject:image];
    if([faceImageArray count] == 1) { //表示已经当前图像为动作检测前截取的
        //        [cameraOption startVideoWriting]; //开始录像
        //        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}


//活体检测结果
- (void) bioAssayResult:(DetectResult)detectResult
{
    //canStopDetection = TRUE;
    
    //用户点击返回按钮, 取消了人脸验证, 不进行后面判断和处理
    if (userCancelledVerify) {
        return;
    }
    dResult = detectResult;
    
    if (![cameraOption canStopVideoWriting]) { //检测结束, 录像尚未结束
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doWithResult) userInfo:nil repeats:NO];
        return;
    }
    
    [self doWithResult];
}


- (void) doWithResult
{
    if (![cameraOption canStopVideoWriting]) { //检测结束, 录像尚未结束
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doWithResult) userInfo:nil repeats:NO];
        return;
    }
    
#pragma 到此处表示视频录像和活体检测均已结束
    
    //    [cameraOption stopVideoWriting]; //终止 AVCaptureSession 的录像
    //[cameraOption stopCameraVideoSession]; //终止 AVCaptureSession 的扫描
    faceVerifysucceed = YES;
    
    //printf("[faceImageArray count]==%d\n\n", (int)[faceImageArray count]);
    
    if (dResult.initFailed || dResult.faceNotFound) {// || [faceImageArray count]==0) {
        faceVerifysucceed = false;
        printf("initFailed or faceNotFound\n\n");
        [self.gifView stopAnimating];
        self.gifView.type = TRUFaceGifTypeFail;
        [self newSongWithSongName:@"failed"];
        [self performSelector:@selector(restartDetection) withObject:nil afterDelay:2];//延迟说完失败语音
        return;
    }
    
//    if (dResult.isSucceed) {
//        self.gifView.type = TRUFaceGifTypeSuccess;
//        [self newSongWithSongName:@"success"];
//        //[self performSelector:@selector(nextViewController) withObject:nil afterDelay:3];
//        [self onDetectSuccessWithImages:faceImageArray];
//        return;
//    }
    
    /*
     初始化失败；
     未发现人脸；
     动作不符合规范；
     检测超时；
     检测成功。
     */
    //仰头、点头、左摇头、右摇头、张嘴、眨眼
//    NSArray *actions = @[@"仰头", @"点头", @"左摇头", @"右摇头", @"张嘴", @"眨眼"];
    for (int actIndex=0; actIndex<testCount; actIndex++)
    {
        if (dResult.action[actIndex] == DStateFailed)
        {
            faceVerifysucceed = false;
//            printf("%s 检测失败\n\n", [[actions objectAtIndex:actIndex] UTF8String]);
            [self.gifView stopAnimating];
            self.gifView.type = TRUFaceGifTypeBlendFail;
            [self newSongWithSongName:@"failed_actionblend"];
            [self performSelector:@selector(restartDetection) withObject:nil afterDelay:3];//延迟说完失败语音
            return;
        }
    }
    [self.gifView stopAnimating];
    switch (currentAction) {
        case DTypeNodUp:
            if(dResult.action[0]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
                
            }
            break;
        case DTypeNodDown:
            if(dResult.action[1]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
            }
            break;
        case DTypeShakeL:
            if(dResult.action[2]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
            }
            break;
        case DTypeShakeR:
            if(dResult.action[3]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
            }
            break;
        case DTypeMouth:
            if(dResult.action[4]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
            }
            break;
        case DTypeBlink:
            if(dResult.action[5]==DStateSucceed){
                successTimes ++;
                if(successTimes>=_maxDetectionTimes){
//                    YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
                    [self onDetectSuccessWithImages:faceImageArray];
                    canStopDetection = YES;
                    [cameraOption stopCameraVideoSession];
                    self.gifView.type = TRUFaceGifTypeSuccess;
                }else{
                    [self restartDetection];
                    self.gifView.type = TRUFaceGifTypeNextStep;
                }
            }else{
                //[self onDetectFailWithMessage:@"验证失败"];
                [self restartDetection];
                self.gifView.type = TRUFaceGifTypeNextStep;
            }
            break;
        default:
            break;
    }
    //[self.gifView stopAnimating];
    //self.gifView.type = TRUFaceGifTypeNextStep;
    
    if (dResult.isTimeOut) {
        faceVerifysucceed = false;
        printf("操作超时。\n\n");
        [self.gifView stopAnimating];
        self.gifView.type = TRUFaceGifTypeTimeOut;
        [self newSongWithSongName:@"failed_timeout"];
        [self performSelector:@selector(restartDetection) withObject:nil afterDelay:2];//延迟说完失败语音
        return;
    }
}

//提示即将进行检测的动作,参数为即将进行检测的动作
- (void) presentActionTips:(DetectType)detectType isRepeat:(BOOL)isRepeat isSkip:(BOOL)isSkip
{
//    YCLog(@"actionCount=%ld detectType=%ld isRepeat=%d, isSkip=%d", (long)actionCount, detectType, isRepeat, isSkip);
    if (detectType == DTypeNone) {
        if (self.gifView.isAnimating) {
            [self.gifView stopAnimating];
        }
        return;
    }
    
    //在此处重新开始计时, 当计时达到规定等待结束的时间, 在视频流输出方法中启动新的动作检测
    isRepeat = (currentAction==detectType);
    currentAction = detectType;
    self.gifView.type = TRUFaceGifTypeHoldOn;
    [self.gifView stopAnimating];
    
    if (actionCount >= 1 && isRepeat) {//在不超过检测时间内的当前动作重复
//        YCLog(@"isRepeat");
        self.gifView.type = TRUFaceGifTypeRepeat;
        [self newSongWithSongName:@"failed_actionblend"];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startNewAction) userInfo:nil repeats:NO];
    } else if (actionCount >= 1 && isSkip) {//失败
//        YCLog(@"isSkip");
        self.gifView.type = TRUFaceGifTypeSkip;
        //        [self newSongWithSongName:@"next_step"];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startNewAction) userInfo:nil repeats:NO];
//        YCLog(@"动作检测失败actionSequence = %@",Anti_Spoof_Object.actionSequence);
    } else if (actionCount >= 1) {//成功
//        YCLog(@"isSuccess");
        successTimes ++;
        if(successTimes>=self.maxDetectionTimes){
//            YCLog(@"[faceImageArray count] = %lu",(unsigned long)[faceImageArray count]);
            [self onDetectSuccessWithImages:faceImageArray];
            self.gifView.type = TRUFaceGifTypeSuccess;
            currentAction = DTypeNone;
            _audioPlayer.volume = 0.0;
            [self newSongWithSongName:@"success"];
        }else{
            self.gifView.type = TRUFaceGifTypeNextStep;
            [self newSongWithSongName:@"next_step"];
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startNewAction) userInfo:nil repeats:NO];
        }
        
    } else {
//        YCLog(@"isStartNewAction");
        [self startNewAction];
    }
    
    actionCount ++;//++后变为第二个动作
}



//人脸不在指定区域
- (void)faceNotInTargetArea:(FaceFrame)flFrame {
//    YCLog(@"faceNotInTargetArea");
    UILabel *faceOutOfFrame = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 45)];
    faceOutOfFrame.textAlignment = NSTextAlignmentCenter;
    faceOutOfFrame.text = @"您的脸不在指定区域";
    faceOutOfFrame.textColor = [UIColor redColor];
    faceOutOfFrame.numberOfLines = 0;
    faceOutOfFrame.font = [UIFont boldSystemFontOfSize:25];
    faceOutOfFrame.backgroundColor = RGBACOLOR(10, 10, 10, 0.65); //RGB(209, 209, 209, 1.0);
    [self.scrollView addSubview:faceOutOfFrame];
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:faceOutOfFrame selector:@selector(removeFromSuperview) userInfo:nil repeats:NO];
}

#pragma mark -- self defined method

//显示即将进行的检测阶段
- (void) showActionTips {
//    YCLog(@"showActionTips");
    if (currentAction == DTypeNodUp)
    {
        //printf("Nod Up detect start\n");
        [self newSongWithSongName:@"detection_type_pitch_up"];
        self.gifView.type = TRUFaceGifTypeHeadRise;
        [self.gifView startAnimating];
    }
    else if (currentAction == DTypeNodDown)
    {
        //printf("Nod Down detect start\n");
        [self newSongWithSongName:@"detection_type_pitch_down"];
        self.gifView.type = TRUFaceGifTypeHeadDown;
        [self.gifView startAnimating];
    }
    else if (currentAction == DTypeShakeL)
    {
        //printf("Shake Left detect start\n");
        [self newSongWithSongName:@"detection_type_yaw_left"];
        self.gifView.type = TRUFaceGifTypeShakeLeft;
        [self.gifView startAnimating];
    }
    else if (currentAction == DTypeShakeR)
    {
        //printf("Shake Right detect start\n");
        [self newSongWithSongName:@"detection_type_yaw_right"];
        self.gifView.type = TRUFaceGifTypeShakeRight;
        [self.gifView startAnimating];
    }
    else if (currentAction == DTypeMouth)
    {
        //printf("Mouth detect start\n");
        [self newSongWithSongName:@"detection_type_mouth_open"];
        self.gifView.type = TRUFaceGifTypeMouthOpen;
        [self.gifView startAnimating];
    }
    else if (currentAction == DTypeBlink)
    {
        //printf("blink detect start\n");
        [self newSongWithSongName:@"detection_type_eye_blink"];
        self.gifView.type = TRUFaceGifTypeBlink;
        [self.gifView startAnimating];
    }
}

- (void)startNewAction {
    newAction = TRUE;
}

#pragma mark - runtime process

+(BOOL)resolveInstanceMethod:(SEL)sel
{
    class_addMethod([self class], sel, (IMP)methodNotImplemented, "v@:");
    return [super resolveInstanceMethod:sel];
}

void methodNotImplemented (id self, SEL _cmd)
{
    if (!usingRuntimeProcess) {
        return;
    }
    
    NSString * method = NSStringFromSelector(_cmd);
    if (_cmd == @selector(faceNotInTargetArea:) || _cmd == @selector(actionDegree: degree:))
    {
        printf("Warning: [AuthenAnti_SpoofingDelegate %s] not implemented in %s\n", [method UTF8String], [NSStringFromClass([self class]) UTF8String]);
    }
}

- (NSMutableArray *)getActionSequence {
    return  [NSMutableArray array];//[[NSMutableArray alloc] initWithArray:@[@"0", @"1", @"2", @"16"]];
}
- (void)onDetectSuccessWithImages:(NSMutableArray *)images {
    //    self.infoView.text = [NSString stringWithFormat:@"成功:%lu",(unsigned long)images.count];
//    YCLog(@"onDetectSuccessWithImages:%lu",(unsigned long)images.count);
}
- (void)onDetectFailWithMessage:(NSString *)message {
    //    self.infoView.text = [NSString stringWithFormat:@"失败请重新开始验证"];
    //[self restartDetection];
    
}

- (UIScrollView *)scrollView
{
    if (_scrollView == nil)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.scrollEnabled = YES;
    }
    return _scrollView;
}




//重新一组中的单个动作
-(void)restartDetection{
//    YCLog(@"restartDetection");
    //    faceImageArray = [[NSMutableArray alloc] init];
    //    newAction = false;
    //    currentAction = DTypeNone; //默认为没有动作
    //    cameraOption = [[NSCameraOption alloc] init]; //创建摄像头操作对象
//    cameraOption.delegate = self;
//    canStopDetection  = FALSE;
//    userCancelledVerify = FALSE;
    
    //活体检测对象设置 Demo
    //    Anti_Spoof_Object = [[AuthenAnti_Spoofing alloc] init];
    //    Anti_Spoof_Object.delegate = self;
    //    Anti_Spoof_Object.faceFrame = {480.0*0.05, 20.0, 480.0*0.95, 640.0*0.95}; //人脸限制区域
    if ([self getActionSequence].count > 0) {
        if (Anti_Spoof_Object.actionSequence.count>1) {
            Anti_Spoof_Object.actionSequence = [self getActionSequence];
            testCount = Anti_Spoof_Object.actionSequence.count-1;
        }
//        else{
//            Anti_Spoof_Object.actionSequence = [self getActionSequence];
//            testCount = Anti_Spoof_Object.actionSequence.count-1;
//            Anti_Spoof_Object.maxActionRepeatCount = 2;
//            Anti_Spoof_Object.maxActionSkipCount = 2;
//            Anti_Spoof_Object.difficultyLevel = 3;
//            Anti_Spoof_Object.maxActionTime = 5.0;
//        }
    }
    Anti_Spoof_Object.maxActionRepeatCount = 2;
    Anti_Spoof_Object.maxActionSkipCount = 2;
    Anti_Spoof_Object.difficultyLevel = 3;
    Anti_Spoof_Object.maxActionTime = 5.0;
    newAction = TRUE;
//    YCLog(@"Anti_Spoof_Object.maxActionTime = %f",Anti_Spoof_Object.maxActionTime);
    //    Anti_Spoof_Object.maxActionRepeatCount = 2;
//    Anti_Spoof_Object.maxActionSkipCount = 2;
//    Anti_Spoof_Object.difficultyLevel = 3;
//    Anti_Spoof_Object.maxActionTime = 5.0;
//    cancelled = FALSE;
//    [cameraOption cameraVideoSessionWithView:_cameraView];
//    [cameraOption startCameraVideoSession]; //启动扫描
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:Anti_Spoof_Object selector:@selector(newDetectAction) userInfo:nil repeats:NO];
}

- (void)restartGroupDetection{
    faceImageArray = [[NSMutableArray alloc] init];
    newAction = false;
    currentAction = DTypeNone; //默认为没有动作
    cameraOption = [[NSCameraOption alloc] init]; //创建摄像头操作对象
    cameraOption.delegate = self;
    canStopDetection  = FALSE;
    userCancelledVerify = FALSE;
    
    //活体检测对象设置 Demo
    Anti_Spoof_Object = [[AuthenAnti_Spoofing alloc] init];
    Anti_Spoof_Object.delegate = self;
    //Anti_Spoof_Object.faceFrame = {480.0*0.05, 20.0, 480.0*0.95, 640.0*0.95}; //人脸限制区域
    if ([self getActionSequence].count > 0) {
        Anti_Spoof_Object.actionSequence = [self getActionSequence];
        testCount = Anti_Spoof_Object.actionSequence.count-1;
    }
    Anti_Spoof_Object.maxActionRepeatCount = 2;
    Anti_Spoof_Object.maxActionSkipCount = 2;
    Anti_Spoof_Object.difficultyLevel = 3;
    Anti_Spoof_Object.maxActionTime = 5.0;
    
    actionCount = 0;
    _audioPlayer.volume = 0.5;
    cancelled = FALSE;
    [cameraOption cameraVideoSessionWithView:_cameraView];
    [cameraOption startCameraVideoSession]; //启动扫描
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:Anti_Spoof_Object selector:@selector(newDetectAction) userInfo:nil repeats:NO];
}


//添加语音
- (void)newSongWithSongName:(NSString *)songName
{
    if (_audioPlayer.isPlaying)
    {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    
    NSError *error;
    NSString *fileName = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Audio.bundle/%@",songName] ofType:@"mp3"];
    NSData *data = [NSData dataWithContentsOfFile:fileName];
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    if (error)
    {
        printf("songError = %s\n\n",[error.description UTF8String]);
    }
    audioPlayer.enableRate = YES;
    audioPlayer.rate = 1.0;
    audioPlayer.volume = 1.0;
    [audioPlayer prepareToPlay];
    [audioPlayer play];
    _audioPlayer = audioPlayer;
}

#pragma mark - getter and setter

- (TRUFaceGifView *)gifView {
    if (_gifView == nil) {
        CGFloat height = SCREENH * 0.3;
        _gifView = [[TRUFaceGifView alloc] init];
        [self.view addSubview:_gifView];
        _gifView.type = TRUFaceGifTypePreShow;
        [_gifView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            make.height.equalTo(@(height));
        }];
    }
    return _gifView;
}

- (UIImageView *)showView {
    if (_showView == nil) {
        _showView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, SCREENW, SCREENW - 20)];
        _showView.image = [UIImage imageNamed:@"Image.bundle/FaceFrame.png"];
        _showView.contentMode = UIViewContentModeScaleAspectFit;
        _showView.userInteractionEnabled = YES;
    }
    return _showView;
}

- (UIView *)cameraView {
    if (_cameraView == nil) {
        _cameraView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENW, SCREENH-40)];
    }
    return _cameraView;
}

#pragma mark 退出按钮
- (void)setUpCancleButton{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundImage:[UIImage imageNamed:@"facecancle"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(calcelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.showView addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@40.0);
        make.height.equalTo(@39.0);
        make.left.equalTo(self.showView).offset(20.0);
        make.top.equalTo(self.showView).offset(5.0);
    }];
    
}
- (void)setUpVoiceButton{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundImage:[UIImage imageNamed:@"facevoice"] forState:UIControlStateNormal];
    [self.showView addSubview:btn];
    [btn addTarget:self action:@selector(voiceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@28.0);
        make.height.equalTo(@25.0);
        make.right.equalTo(self.showView).offset(-20.0);
        make.top.equalTo(self.showView).offset(5.0);
    }];
    
}

-(void)voiceButtonClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        voiceValue = _audioPlayer.volume;
        _audioPlayer.volume = 0.0;
    }else{
        _audioPlayer.volume = 1.0;
    }
}


- (void)calcelButtonClick{
    userCancelledVerify = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

@end

//
//  TRUThirdFaceBaseViewController.h
//  TRUThirdFaceObjcModule_Example
//
//  Created by hukai on 2020/4/27.
//  Copyright © 2020 yeniugo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRUThirdFaceBaseViewController : UIViewController
@property (assign, nonatomic) int maxDetectionTimes;//最大检测次数
//@property (nonatomic, copy) void (^authFailure)();//检测失败后执行
- (NSMutableArray *) getActionSequence;
- (void) onDetectSuccessWithImages:(NSMutableArray *) images;
- (void) onDetectFailWithMessage:(NSString *) message;
- (void) restartDetection;
- (void) restartGroupDetection;
@end

NS_ASSUME_NONNULL_END

//
//  TRUFaceGifView.h
//  UniformIdentityAuthentication
//
//  Created by Trusfort on 2017/1/5.
//  Copyright © 2017年 Trusfort. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, TRUFaceGifType)
{
    TRUFaceGifTypePreShow,
    TRUFaceGifTypeShakeLeft,
    TRUFaceGifTypeShakeRight,
    TRUFaceGifTypeHeadRise,
    TRUFaceGifTypeHeadDown,
    TRUFaceGifTypeMouthOpen,
    TRUFaceGifTypeBlink,
    TRUFaceGifTypeFail,
    TRUFaceGifTypeBlendFail,
    TRUFaceGifTypeTimeOut,
    TRUFaceGifTypeNextStep,
    TRUFaceGifTypeRepeat,
    TRUFaceGifTypeSkip,
    TRUFaceGifTypeHoldOn,
    TRUFaceGifTypeSuccess
};
@interface TRUFaceGifView : UIView

@property (strong,nonatomic) NSArray  *gifArray;
@property (assign, nonatomic) TRUFaceGifType type;
@property (assign, nonatomic) BOOL isPrepare; //动作前准备判断
@property (assign, nonatomic) BOOL isAnimating;//动画判断

- (void)stopAnimating;
- (void)startAnimating;

@end

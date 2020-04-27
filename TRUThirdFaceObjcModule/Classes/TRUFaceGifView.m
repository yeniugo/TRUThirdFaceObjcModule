//
//  TRUFaceGifView.m
//  UniformIdentityAuthentication
//
//  Created by Trusfort on 2017/1/5.
//  Copyright © 2017年 Trusfort. All rights reserved.
//

#import "TRUFaceGifView.h"

@interface TRUFaceGifView ()
@property (strong, nonatomic) UIImageView  *gifImageView;
@property (strong, nonatomic) UILabel *infoLabel;
@end

@implementation TRUFaceGifView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.7;
        
        [self addSubview:self.gifImageView];
        [self addSubview:self.infoLabel];
    }
    return self;
}

- (void)setType:(TRUFaceGifType)type
{
    _type = type;
    switch (_type)
    {
        case TRUFaceGifTypeShakeLeft:
        {
            self.infoLabel.text = @"请向左摇头并回位";
            self.gifArray = @[[UIImage imageNamed:@"AMGifRes.bundle/shake1.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake2.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake3.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake4.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake5.png"] ];
            break;
        }
        case TRUFaceGifTypeShakeRight:
        {
            self.infoLabel.text = @"请向右摇头并回位";
            self.gifArray = @[[UIImage imageNamed:@"AMGifRes.bundle/shake5.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake6.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake7.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake8.png"],
                              [UIImage imageNamed:@"AMGifRes.bundle/shake9.png"] ];
            break;
        }
        case TRUFaceGifTypeHeadRise:
        {
            self.infoLabel.text = @"请缓慢仰头并回位";
            self.gifArray = @[ [UIImage imageNamed:@"AMGifRes.bundle/open1.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise1.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise2.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise3.png"] ];
            break;
        }
        case TRUFaceGifTypeHeadDown:
        {
            self.infoLabel.text = @"请缓慢点头并回位";
            self.gifArray = @[ [UIImage imageNamed:@"AMGifRes.bundle/open1.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise1.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise2.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/rise3.png"] ];
            break;
        }
        case TRUFaceGifTypeMouthOpen:
        {
            self.infoLabel.text = @"请反复张嘴";
            self.gifArray = @[ [UIImage imageNamed:@"AMGifRes.bundle/open2.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/open3.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/open4.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/open1.png"] ];
            break;
        }
        case TRUFaceGifTypePreShow:  self.infoLabel.text = @"请将头像位于取景框内，等待动作提示"; break;
        case TRUFaceGifTypeBlink:
        {
            self.infoLabel.text = @"请眨眼";
            self.gifArray = @[ [UIImage imageNamed:@"AMGifRes.bundle/open1.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/blink.png"],
                               [UIImage imageNamed:@"AMGifRes.bundle/open1.png"] ];
            break;
        }
            
        case TRUFaceGifTypeFail:      self.infoLabel.text = @"验证失败，请重试";          break;
        case TRUFaceGifTypeTimeOut:   self.infoLabel.text = @"检测超时，请重试";          break;
        case TRUFaceGifTypeNextStep:  self.infoLabel.text = @"很好，下一步";             break;
        case TRUFaceGifTypeRepeat:    self.infoLabel.text = @"请重试";                  break;
        case TRUFaceGifTypeSkip:      self.infoLabel.text = @"跳过,下一项";              break;
        case TRUFaceGifTypeSuccess:   self.infoLabel.text = @"验证成功，感谢你的配合";     break;
        case TRUFaceGifTypeHoldOn:    self.infoLabel.text = @"请等待";                  break;
        case TRUFaceGifTypeBlendFail: self.infoLabel.text = @"抱歉，动作不符合规范，请重试";break;
        default:
            break;
    }
}

- (void)setGifArray:(NSArray *)gifArray
{
    _gifArray = gifArray;
    self.gifImageView.animationImages = _gifArray;
    self.gifImageView.animationDuration = 2.5;
    self.gifImageView.animationRepeatCount = 0;
}

- (void)startAnimating
{
    [self.gifImageView startAnimating];
    self.isAnimating = YES;
}

- (void)stopAnimating
{
    [self.gifImageView stopAnimating];
    self.isAnimating = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat margin = 10;
    CGFloat gifWidth = (height - 3 * margin) * 0.8;
    CGFloat gifX = (self.bounds.size.width - gifWidth) * 0.5;
    self.gifImageView.frame = CGRectMake(gifX, margin, gifWidth, gifWidth);
    
    self.infoLabel.frame = CGRectMake(0, CGRectGetMaxY(self.gifImageView.frame) + 10, CGRectGetWidth(self.bounds), gifWidth * 0.2);
}


#pragma mark - setter and getter

-(UILabel*)infoLabel
{
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont boldSystemFontOfSize:18];
        _infoLabel.numberOfLines = 0;
        _infoLabel.backgroundColor = [UIColor clearColor];
    }
    return _infoLabel;
}

-(UIImageView*)gifImageView
{
    if (!_gifImageView) {
        _gifImageView = [[UIImageView alloc] init];
        _gifImageView.image = [UIImage imageNamed:@"AMGifRes.bundle/open1.png"];
        _gifImageView.opaque = YES;
    }
    return _gifImageView;
}


@end

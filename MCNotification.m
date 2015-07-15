//
//  MCNotification.m
//  Bennett
//
//  Created by Bennett on 12-11-8.
//
//

#import "MCNotification.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#define kTransitionDuration  0.18
#define kDuration            1.6

#define WAIT_VIEW_MIN_HEIGHT           93.0f
#define WAIT_VIEW_WIDTH  185.0f


typedef enum : NSUInteger {
    AnimationTypeHide,
    AnimationTypeShow,
} AnimationType;

typedef void (^MCNotificationCompletionBloock)(void);


@implementation MCNotificationConfig


@end

static MCNotification *noti;

@interface MCNotification()
@property (nonatomic,weak) UIWindow *window;
@property (nonatomic,strong) UIImageView *waitView;
@property (nonatomic,strong) UILabel *tipsLabel;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic,weak) UIView *view;

@property (nonatomic,assign) AnimationType type;

@end

@implementation MCNotification
@synthesize window = _window;
@synthesize waitView = _waitView;
@synthesize tipsLabel = _tipsLabel;
@synthesize indicatorView = _indicatorView;
@synthesize view = _view;


#pragma mark - getter and setter
- (UIWindow*)window {
    if (!_window) {
        _window = [[UIApplication sharedApplication] keyWindow];
    }
    return _window;
}

- (UILabel*)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, 54, WAIT_VIEW_WIDTH, 20)];
		_tipsLabel.font=[UIFont systemFontOfSize:15];
		_tipsLabel.textAlignment = NSTextAlignmentCenter;
		_tipsLabel.backgroundColor=[UIColor clearColor];
		_tipsLabel.textColor=[UIColor whiteColor];
        _tipsLabel.numberOfLines = 0;
		_tipsLabel.text=@"请稍候...";
    }
    return _tipsLabel;
}

- (UIActivityIndicatorView*)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 35.0f, 35.0f)];
        _indicatorView.center=CGPointMake(93.5, 32.0f);
        [_indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return _indicatorView;
}


- (UIImageView*)waitView {
    if (!_waitView) {
        _waitView=[[UIImageView alloc] init];
        _waitView.backgroundColor = [UIColor colorWithWhite:(CGFloat)42/255 alpha:1.0];
//        [_waitView setImage:[UIImage imageNamed:@"loading_bg.png"]];
        _waitView.layer.masksToBounds = YES;
        _waitView.layer.cornerRadius = 10;
		_waitView.hidden=YES;
		_waitView.frame=CGRectMake(0, 0, WAIT_VIEW_WIDTH, 93.0f);
		CGPoint point=CGPointMake(self.window.center.x, self.window.center.y);
		_waitView.center=point;
        
        [_waitView addSubview:self.indicatorView];
        [_waitView addSubview:self.tipsLabel];
    }
    return _waitView;
}


#pragma mark -
+ (MCNotification*)shareNotification {
    if (!noti) {
        noti = [[MCNotification alloc] init];
    }
    return noti;
}


+ (MCNotificationConfig*)defaultConfig {
    static dispatch_once_t onceToken;
    static MCNotificationConfig *config;
    dispatch_once(&onceToken, ^{
        config = [[MCNotificationConfig alloc] init];
        config.animation = YES;
        config.targetView = [[UIApplication sharedApplication] keyWindow];
        config.showIndicator = YES;
        config.hideWhenFinish = NO;
    });
    return config;
}

#pragma mark - hide method


- (void)removeWaitView {
    self.view = self.view ? self.view : self.window;
    self.view.userInteractionEnabled=YES;
    [self.waitView stopAnimating];
    [self.waitView removeFromSuperview];
    
}


-(void)hiddenWaitView:(BOOL)animated {
    
	if (animated) {
        
        self.type = AnimationTypeHide;
        //缩放动画
        CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        scale.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity] ,
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.2)] ,
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(.8, .8, .8)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(.5, .5, .5)] ,
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0, 0, 0)]];
        scale.removedOnCompletion = NO;
        
        //透明动画
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"alpha"];
        opacityAnim.fromValue = [NSNumber numberWithFloat:1.0];
        opacityAnim.toValue = [NSNumber numberWithFloat:0.];
        opacityAnim.removedOnCompletion = NO;
        
        //动画组
        CAAnimationGroup *animGroup = [CAAnimationGroup animation];
        animGroup.animations = [NSArray arrayWithObjects: scale, opacityAnim, nil];
        animGroup.duration = kTransitionDuration;
        
        animGroup.removedOnCompletion = NO;
        
        __weak typeof(self) weak = self;
        weak.waitView.alpha = 1.0;
        [UIView animateWithDuration:kTransitionDuration animations:^{
            weak.waitView.alpha = 0.;
        } completion:^(BOOL finished) {
            [weak removeWaitView];
            [weak.waitView.layer removeAllAnimations];
        }];
        
        [self.waitView.layer addAnimation:animGroup forKey:@"hide"];
        
	} else {
        [self removeWaitView];
	}
}


- (void)hiddenWaitView:(BOOL)animated completion:(void(^)(void))completion {
    
    void (^animations)(void) = ^(void) {
        [self hiddenWaitView:animated];
    };
    
    void (^comp)(BOOL finish) = ^(BOOL finish) {
        if (completion) {
            completion();
        }
    };
    
    [UIView animateWithDuration:kTransitionDuration animations:animations completion:comp];
}



#pragma mark show method

- (void)show:(MCNotificationParamer)paramer {
    [self show:paramer completion:NULL];
}

- (void)show:(MCNotificationParamer)paramer completion:(MCNotificationCompletion)completion {
    MCNotificationConfig *config = [[self class] defaultConfig];
    
    if (paramer) {
        paramer(config);
    } else {
        
    }
    
    if (_view) {
        self.view.userInteractionEnabled = YES;
    }
    self.view = config.targetView;
    self.view.userInteractionEnabled = NO;
    
    [self.view addSubview:self.waitView];
    self.waitView.hidden=NO;
    [self.indicatorView startAnimating];
    
    CGFloat margin = 8;
    
    if (!config.text.length) {
        config.text = @"正在处理\n请稍候...";
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attri = @{NSFontAttributeName : self.tipsLabel.font ,
                            NSParagraphStyleAttributeName : paragraphStyle ,
                            NSForegroundColorAttributeName : [UIColor grayColor]};
    
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:config.text];
    [attrText setAttributes:attri range:NSMakeRange(0, config.text.length)];
    
    CGSize textSize = [attrText boundingRectWithSize:CGSizeMake(WAIT_VIEW_WIDTH - margin*2, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                             context:NULL].size;
    
    
    if (config.showIndicator) [self.indicatorView startAnimating];
    else [self.indicatorView stopAnimating];
    self.tipsLabel.frame = CGRectMake(0,
                                      config.showIndicator ? CGRectGetMaxY(self.indicatorView.frame)+margin : margin*2,
                                      textSize.width,
                                      textSize.height);
    
    CGFloat height = CGRectGetMaxY(self.tipsLabel.frame) + margin + (config.showIndicator ? 0:margin*2);
    height = height > WAIT_VIEW_MIN_HEIGHT ? height : WAIT_VIEW_MIN_HEIGHT;
    
    self.waitView.frame = CGRectMake(CGRectGetMinX(self.waitView.frame),
                                     CGRectGetMinY(self.waitView.frame),
                                     CGRectGetWidth(self.waitView.frame),
                                     height);
    
    self.tipsLabel.center = CGPointMake(CGRectGetWidth(self.waitView.frame)/2,
                                        config.showIndicator ? self.tipsLabel.center.y : height/2);
    
    self.tipsLabel.attributedText=attrText;
    
    
    
    CGPoint point = [self.window convertPoint:self.window.center toView:self.view];
    self.waitView.center = point;
    [self.window bringSubviewToFront:self.waitView];
    
    self.waitView.alpha = 0;
    if (!config.animation) self.waitView.alpha = 0.99;
    
    
    self.type = AnimationTypeShow;
    //贝塞尔曲线路径
    UIBezierPath *movePath = [UIBezierPath bezierPath];
    [movePath moveToPoint:CGPointMake(10.0, 10.0)];
    [movePath addQuadCurveToPoint:CGPointMake(100, 300) controlPoint:CGPointMake(300, 100)];
    
    //关键帧动画（位置）
    CAKeyframeAnimation * posAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    posAnim.path = movePath.CGPath;
    posAnim.removedOnCompletion = YES;
    
    
    CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    scale.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0, 0, 0)] ,
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(.5, .5, .5)] ,
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(.8, .8, .8)] ,
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.2)] ,
                     [NSValue valueWithCATransform3D:CATransform3DIdentity]];
    scale.removedOnCompletion = YES;
    
    
    
    //透明动画
    CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"alpha"];
    opacityAnim.fromValue = [NSNumber numberWithFloat:0.1];
    opacityAnim.toValue = [NSNumber numberWithFloat:1.0];
    opacityAnim.removedOnCompletion = YES;
    
    //动画组
    CAAnimationGroup *animGroup = [CAAnimationGroup animation];
    animGroup.animations = [NSArray arrayWithObjects: scale, opacityAnim, nil];
    animGroup.duration = kTransitionDuration;
    
    [self.waitView.layer addAnimation:animGroup forKey:nil];

    __weak typeof(self) weak = self;
    
    [UIView animateWithDuration:kTransitionDuration animations:^{
        self.waitView.alpha = 1;
    } completion:^(BOOL finished) {
        [weak.waitView.layer removeAllAnimations];
    }];
    
    if (config.hideWhenFinish) {
        
        
        double delayInSeconds = config.duration ?: kDuration;
        
        delayInSeconds = delayInSeconds > kTransitionDuration ? delayInSeconds : kTransitionDuration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if (completion) {
                completion();
            }
            
            [weak hiddenWaitView:YES];
        });
    }
    
    
    if (config.animation) {
    } else {
        self.waitView.alpha = 1;
    }
}



#pragma mark -
- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}


- (void)dealloc {
    
    self.waitView = nil;
    self.tipsLabel = nil;
    self.indicatorView = nil;
    self.view = nil;
}

@end

//
//  MCNotification.h
//  Bennett
//
//  Created by Bennett on 12-11-8.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MCNotificationConfig : NSObject

@property (nonatomic,weak) UIView *targetView;//现在在哪个页面
@property (nonatomic,assign) BOOL animation;//弹出时，是否显示动画
@property (nonatomic,strong) NSString *text;//text内容
@property (nonatomic,assign) CGFloat duration;//显示时长
@property (nonatomic,assign) BOOL hideWhenFinish;//显示后是否隐藏
@property (nonatomic,assign) BOOL showIndicator;//是否显示菊花

@end


typedef void(^MCNotificationParamer)(MCNotificationConfig *config);
typedef void(^MCNotificationCompletion)(void);

@interface MCNotification : NSObject


- (void)show:(MCNotificationParamer)paramer ;
- (void)show:(MCNotificationParamer)paramer completion:(MCNotificationCompletion)completion;

- (void)hiddenWaitView:(BOOL)animated ;
- (void)hiddenWaitView:(BOOL)animated completion:(MCNotificationCompletion)completion ;

+ (MCNotification*)shareNotification;

#define Notification [MCNotification shareNotification]

@end

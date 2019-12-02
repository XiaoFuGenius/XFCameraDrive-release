//
//  XFCameraViewController.m
//  WiredDemo-OC
//
//  Created by 胡文峰 on 2019/6/24.
//  Copyright © 2019 xiaofutech. All rights reserved.
//

#import "XFCameraViewController.h"

@interface XFCameraViewController ()
@property (nonatomic, strong) UIView *interactionView;
@property (nonatomic, assign) BOOL tapFlag;
@property (nonatomic, strong) NSArray *lastCheckImages;
@property (nonatomic, strong) UIView *photoCheckView;

@property (nonatomic, strong) UIView *cameraView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) BOOL isSwitching;
@property (nonatomic, strong) UIButton *switchBtn;
@end

@implementation XFCameraViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = [UIColor cyanColor]; // XFColor(0x000000, 1.0f);
    
    [[CTUVCHelper Shared] setupBearerView:self.cameraView LightMode:0
                          StartCompletion:nil StopCompletion:nil];

    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(ApplicationWillResignActiveNoti:)
                       name:UIApplicationWillResignActiveNotification object:nil];
    [notiCenter addObserver:self selector:@selector(ApplicationDidBecomeActiveNoti:)
                       name:UIApplicationDidBecomeActiveNotification object:nil];

    [self setupMainUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[CTUVCHelper Shared] startCamera];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setupMainUI
{
    [self.view addSubview:self.cameraView];
    [self.view addSubview:self.interactionView];

    self.lastCheckImages = [NSArray array];
    [self.interactionView addSubview:self.photoCheckView];
}

- (UIView *)interactionView
{
    if (!_interactionView) {
        CGRect frame = CGRectMake(0, 0, XFWidth, XFHeight);
        _interactionView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
        {
            frame = CGRectMake(0, 0, XFWidth, XFNaviBarHeight);
            UIView *topView = [UIView XF_ViewWithColor:XFColor(0x000000, 0.15f) Frame:frame];
            {
                frame = CGRectMake(0, (XFSafeTop-20)+27 +7, XFWidth, 17);
                UILabel *label = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:@"镜头预览"
                                                       Font:XFFont(15)
                                                  TextColor:XFColor(0xffffff, 1.0f) Frame:frame];
                label.textAlignment = NSTextAlignmentCenter;
                [topView addSubview:label];

                frame = CGRectMake(10, (XFSafeTop-20)+27, 30, 30);
                UIButton *closeBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil Title:nil
                                                             Font:nil TitleColor:nil Target:self
                                                           Action:@selector(interactionView_closeBtnClick:)
                                                            Frame:frame];
                [closeBtn xf_SetBackgroundColor:XFColor(0x000000, 0.5f) forState:UIControlStateNormal];
                [closeBtn xf_SetBackgroundColor:XFColor(0x000000, 0.7f) forState:UIControlStateHighlighted];
                [closeBtn setImage:[[UIImage imageNamed:@"cross"]
                                    xf_ImageWithTintColor:XFColor(0xffffff, 1.0f)]
                          forState:UIControlStateNormal];
                [closeBtn setImage:[[UIImage imageNamed:@"cross"]
                                    xf_ImageWithTintColor:XFColor(0xffffff, 0.7f)]
                          forState:UIControlStateHighlighted];
                closeBtn.imageEdgeInsets = UIEdgeInsetsMake(9, 9, 9, 9);
                closeBtn.layer.cornerRadius = [closeBtn xf_GetHeight]/2;
                closeBtn.clipsToBounds = YES;
                [topView addSubview:closeBtn];
            }

            frame = CGRectMake(0, XFHeight-XFSafeBottom-100, XFWidth, XFSafeBottom+100);
            UIView *bottomView = [UIView XF_ViewWithColor:XFColor(0x000000, 0.15f) Frame:frame];
            {
                frame = CGRectMake((int)((XFWidth-65)/2.0), (int)((100-65)/2.0), 65, 65);
                UIButton *captureBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil Title:nil
                                                               Font:nil TitleColor:nil Target:self
                                                             Action:@selector(interactionView_captureBtnClick:)
                                                              Frame:frame];
                [captureBtn xf_SetBackgroundColor:XFColor(0xffffff, 1.0f) forState:UIControlStateNormal];
                [captureBtn xf_SetBackgroundColor:XFColor(0xefefef, 1.0f) forState:UIControlStateHighlighted];
                captureBtn.layer.cornerRadius = [captureBtn xf_GetHeight]/2;
                captureBtn.clipsToBounds = YES;
                {
                    frame = CGRectMake(([captureBtn xf_GetWidth]-8.4f)/2,
                                       ([captureBtn xf_GetWidth]-8.4f)/2, 8.4f, 8.4f);
                    UIView *point = [UIView XF_ViewWithColor:XFColor(0x489cf9, 1.0f) Frame:frame];
                    point.layer.cornerRadius = [point xf_GetHeight]/2;
                    point.clipsToBounds = YES;
                    [captureBtn addSubview:point];
                }
                [bottomView addSubview:captureBtn];

                CGFloat left = (int)((XFWidth-[captureBtn xf_GetRight] -50)/2.0);
                frame = CGRectMake(left, (100-50)/2.0, 50, 50+34);
                UIView *lastCheckView = [self setupLastCheckView:frame];
                [bottomView addSubview:lastCheckView];

                left = (int)((XFWidth-[captureBtn xf_GetRight] -52)/2.0);
                frame = CGRectMake((int)[captureBtn xf_GetRight]+left,
                                   (100-52)/2.0, 52, 52+34);
                UIView *switchView = [self setupSwitchView:frame];
                switchView.tag = 1;
                self.switchBtn = switchView.subviews[0];
                [bottomView addSubview:switchView];
            }

            UIView *tapView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:_interactionView.bounds];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(interactionView_disabledSelf:)];
            [tapView addGestureRecognizer:tap];

            [_interactionView addSubview:tapView];
            [_interactionView addSubview:topView];
            [_interactionView addSubview:bottomView];
        }
    }
    return _interactionView;
}

- (UIView *)setupLastCheckView:(CGRect)frame
{
    UIView *lastCheckView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
    {
        frame = CGRectMake(0, 0, [lastCheckView xf_GetWidth], [lastCheckView xf_GetWidth]);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.backgroundColor = XFColor(0xf6f6f6, 1.0f);
        //imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.layer.cornerRadius = [imageView xf_GetHeight]/2;
        imageView.clipsToBounds = YES;
        imageView.layer.borderWidth = 1.0f;
        imageView.layer.borderColor = XFColor(0xffffff, 1.0f).CGColor;
        imageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        [lastCheckView addSubview:imageView];

        frame = CGRectMake(1, 1, [lastCheckView xf_GetWidth]-2, [lastCheckView xf_GetWidth]-2);
        UIButton *maskBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil Title:nil
                                                    Font:nil TitleColor:nil Target:self
                                                  Action:@selector(interactionView_lastCheckViewClick:)
                                                   Frame:frame];
        [maskBtn xf_SetBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [maskBtn xf_SetBackgroundColor:XFColor(0x000000, 0.25f) forState:UIControlStateHighlighted];
        maskBtn.layer.cornerRadius = [maskBtn xf_GetHeight]/2;
        maskBtn.clipsToBounds = YES;
        [lastCheckView addSubview:maskBtn];

        frame = CGRectMake(0, [imageView xf_GetBottom]+5-1, [imageView xf_GetWidth], 11);
        UILabel *lab = [UILabel XF_LabelWithColor:[UIColor clearColor]
                                             Text:@"查看大图" Font:XFFont(10)
                                        TextColor:XFColor(0xffffff, 1.0f) Frame:frame];
        lab.textAlignment = NSTextAlignmentCenter;
        [lastCheckView addSubview:lab];
    }
    lastCheckView.hidden = YES;
    return lastCheckView;
}
- (void)lastCheckViewStartAnimation {
    UIView *bottomView = self.interactionView.subviews[2];
    UIView *lastCheckView = bottomView.subviews[1];

    if (lastCheckView.hidden==NO) {
        UIImageView *imageView = lastCheckView.subviews.firstObject;
        imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:0.3f animations:^{
            imageView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            if (finished) {
                imageView.transform = CGAffineTransformMakeScale(1, 1);
            }
        }];
    }
}

- (UIView *)setupSwitchView:(CGRect)frame
{
    UIView *switchView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
    {
        UIButton *switchBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil
                                                     Title:nil Font:nil TitleColor:nil Target:self
                                                    Action:@selector(interactionView_switchViewClick:)
                                                     Frame:CGRectMake(0, 0,
                                                                      [switchView xf_GetWidth],
                                                                      [switchView xf_GetWidth])];
        [switchBtn setImage:[[UIImage imageNamed:@"switch"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 1.0f)]
                   forState:UIControlStateNormal];
        [switchBtn setImage:[[UIImage imageNamed:@"switch"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 0.7f)]
                   forState:UIControlStateHighlighted];
        [switchBtn setImage:[[UIImage imageNamed:@"switch"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 1.0f)]
                   forState:UIControlStateSelected];
        [switchBtn setImage:[[UIImage imageNamed:@"switch"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 0.7f)]
                   forState:UIControlStateSelected | UIControlStateHighlighted];
        switchBtn.imageEdgeInsets = UIEdgeInsetsMake(([switchBtn xf_GetWidth]-28)/2,
                                                     ([switchBtn xf_GetWidth]-16)/2,
                                                     ([switchBtn xf_GetWidth]-28)/2,
                                                     ([switchBtn xf_GetWidth]-16)/2);
        [switchView addSubview:switchBtn];

        NSString *str = @"切换基底层";
        CGFloat height = [str boundingRectWithSize:CGSizeMake([switchView xf_GetWidth], MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:XFFont(10)} context:nil].size.height;
        UILabel *lab = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:str Font:XFFont(10)
                                        TextColor:XFColor(0xffffff, 1.0f)
                                            Frame:CGRectMake(0, [switchBtn xf_GetBottom]+5-1,
                                                             [switchBtn xf_GetWidth], height+1)];
        lab.numberOfLines = 0;
        lab.textAlignment = NSTextAlignmentCenter;
        [switchView addSubview:lab];
    }
    return switchView;
}

- (void)interactionView_disabledSelf:(UITapGestureRecognizer *)tap
{
    UIView *interactionView = tap.view.superview;
    UIView *topView = interactionView.subviews[1];
    UIView *bottomView = interactionView.subviews[2];

    self.tapFlag = !self.tapFlag;
    [UIView animateWithDuration:0.3f animations:^{
        if (self.tapFlag) {
            [topView xf_SetY:-[topView xf_GetHeight]];
            [bottomView xf_SetY:[interactionView xf_GetHeight]];
        } else {
            [topView xf_SetY:0];
            [bottomView xf_SetY:[interactionView xf_GetHeight]-[bottomView xf_GetHeight]];
        }
    } completion:^(BOOL finished) {
        ///
    }];
}

- (void)interactionView_closeBtnClick:(UIButton *)sender
{
    XFWeakSelf(weakSelf);
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"提示" message:@"退出当前镜头预览"
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [[CTUVCHelper Shared] stopCamera];
        [[CTUVCHelper Shared] releasedCamera];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)interactionView_captureBtnClick:(UIButton *)sender
{
    [XFLoadingWindow ShowSreenLock:YES];

    XFWeakSelf(weakSelf);
    [[CTUVCHelper Shared] capture:^(NSInteger ret, UIImage * _Nonnull rgbImage, UIImage * _Nonnull plImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret!=0 && ret!=1) {
                [XFLoadingWindow Hide];
                [XFPromptWindow ShowMsg:@"拍摄失败，请重试"];
                return;
            }

            if (ret!=0) {
                //NSLog(@"当前取得第一张图片");
                return;
            }
            //NSLog(@"当前取得第二张图片");

            //rgbImage = [UIImage XF_ImageWithColor:[UIColor XF_GetArc4randomColor:1.0f] \
                                             size:CGSizeMake(720, 1280)];
            //plImage = [UIImage XF_ImageWithColor:[UIColor XF_GetArc4randomColor:1.0f] \
                                            size:CGSizeMake(720, 1280)];
            weakSelf.lastCheckImages = @[rgbImage, plImage];

            UIView *bottomView = weakSelf.interactionView.subviews[2];
            UIView *lastCheckView = bottomView.subviews[1];
            UIImageView *imageView = lastCheckView.subviews[0];
            imageView.image = [plImage xf_imageAutoSize:imageView.bounds.size];

            lastCheckView.hidden = NO;
            [weakSelf lastCheckViewStartAnimation];

            [XFLoadingWindow Hide];
        });
    }];
}

- (void)interactionView_switchViewClick:(UIButton *)sender
{
    if (sender.superview.tag==1 && self.isSwitching) {
        [XFPromptWindow ShowMsg:@"切换太快啦~"];
        return;
    }

    sender.selected = !sender.selected;
    NSString *str = sender.selected?@"切换表皮层":@"切换基底层";
    CGFloat height = [str boundingRectWithSize:CGSizeMake([sender.superview xf_GetWidth], MAXFLOAT)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName:XFFont(10)} context:nil].size.height;
    UILabel *lab = sender.superview.subviews.lastObject;
    [lab xf_SetHeight:height];
    lab.text = str;

    if (sender.superview.tag==1) {
        self.isSwitching = true;
        XFWeakSelf(weakSelf);
        [[CTUVCHelper Shared] setLightMode:sender.selected?1:0 Completion:^(NSInteger ret, NSInteger lightMode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.isSwitching = false;
                weakSelf.switchBtn.selected = lightMode==1?true:false;
                NSString *str = weakSelf.switchBtn.selected?@"切换表皮层":@"切换基底层";
                CGFloat height = [str boundingRectWithSize:CGSizeMake([weakSelf.switchBtn.superview xf_GetWidth], MAXFLOAT)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:XFFont(10)} context:nil].size.height;
                UILabel *lab = weakSelf.switchBtn.superview.subviews.lastObject;
                [lab xf_SetHeight:height];
                lab.text = str;
            });
        }];
    } else if (sender.superview.tag==2) {
        UIImageView *imageView = self.photoCheckView.subviews[0];
        imageView.image = sender.selected?self.lastCheckImages[1]:self.lastCheckImages[0];
    }
}

- (void)interactionView_lastCheckViewClick:(UIButton *)sender
{
    //if (self.lastCheckImages.count != 2) {
    //    return;
    //}

    UIImageView *imageView = self.photoCheckView.subviews[0];
    UIButton *switchBtn = self.photoCheckView.subviews[1].subviews[1].subviews[0];
    switchBtn.selected = NO;
    [self interactionView_switchViewClick:switchBtn];
    imageView.image = switchBtn.selected?self.lastCheckImages[1]:self.lastCheckImages[0];

    self.photoCheckView.layer.anchorPoint = [(NSValue *)self.photoCheckView.xf_object CGPointValue];
    CGFloat width_new = XFHeight*9/16;
    self.photoCheckView.frame = CGRectMake((int)((XFWidth-width_new)/2), 0, width_new, XFHeight);
    self.photoCheckView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.photoCheckView.hidden = NO;
    [UIView animateWithDuration:0.3f animations:^{
        self.photoCheckView.transform = CGAffineTransformMakeScale(1, 1);
        self.photoCheckView.alpha = 1.0f;
    } completion:nil];
}

- (void)interactionView_backBtnClick:(UIButton *)sender
{
    [UIView animateWithDuration:0.3f animations:^{
        self.photoCheckView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.photoCheckView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.photoCheckView.hidden = YES;
        self.photoCheckView.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

- (UIView *)photoCheckView
{
    if (!_photoCheckView) {
        CGFloat width_new = XFHeight*9/16;
        CGRect frame = CGRectMake((int)((XFWidth-width_new)/2), 0, width_new, XFHeight);
        UIView *photoCheckView = [UIView XF_ViewWithColor:XFColor(0x000000, 1.0f) Frame:frame];
        {
            frame = photoCheckView.bounds;
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.contentMode = UIViewContentModeScaleToFill;
            [photoCheckView addSubview:imageView];

            frame = CGRectMake(0, XFHeight-XFSafeBottom-100, XFWidth, XFSafeBottom+100);
            UIView *bottomView = [UIView XF_ViewWithColor:XFColor(0x000000, 0.15f) Frame:frame];
            {
                frame = CGRectMake((int)((XFWidth-65)/2.0), (int)((100-65)/2.0), 65, 65);
                UIView *captureBtn = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];

                CGFloat left = (int)((XFWidth-[captureBtn xf_GetRight] -50)/2.0);
                frame = CGRectMake(left, (100-50)/2.0, 50, 50+34);
                UIView *deleteView = [self setupBackViewFrame:frame];
                [bottomView addSubview:deleteView];

                left = (int)((XFWidth-[captureBtn xf_GetRight] -52)/2.0);
                frame = CGRectMake((int)[captureBtn xf_GetRight]+left,
                                   (100-52)/2.0, 52, 52+34);
                UIView *switchView = [self setupSwitchView:frame];
                switchView.tag = 2;
                [bottomView addSubview:switchView];
            }
            [photoCheckView addSubview:bottomView];
        }

        UIView *bottomView = self.interactionView.subviews[2];
        UIView *lastCheckView = bottomView.subviews[1];

        CGFloat x = ([lastCheckView xf_GetRelativeFrame].origin.x+[lastCheckView xf_GetWidth]/2) / XFWidth;
        CGFloat y = ([lastCheckView xf_GetRelativeFrame].origin.y+[lastCheckView xf_GetWidth]/2) / XFHeight;
        photoCheckView.xf_object = [NSValue valueWithCGPoint:CGPointMake(x, y)];

        photoCheckView.alpha = 0.0f;
        photoCheckView.hidden = YES;

        _photoCheckView = photoCheckView;
    }
    return _photoCheckView;
}

- (UIView *)setupBackViewFrame:(CGRect)frame {
    UIView *backView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
    {
        UIButton *switchBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil
                                                     Title:nil Font:nil TitleColor:nil Target:self
                                                    Action:@selector(interactionView_backBtnClick:)
                                                     Frame:CGRectMake(0, 0,
                                                                      [backView xf_GetWidth],
                                                                      [backView xf_GetWidth])];
        [switchBtn setImage:[[UIImage imageNamed:@"back"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 1.0f)]
                   forState:UIControlStateNormal];
        [switchBtn setImage:[[UIImage imageNamed:@"back"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 0.7f)]
                   forState:UIControlStateHighlighted];
        [switchBtn setImage:[[UIImage imageNamed:@"back"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 1.0f)]
                   forState:UIControlStateSelected];
        [switchBtn setImage:[[UIImage imageNamed:@"back"]
                             xf_ImageWithTintColor:XFColor(0xffffff, 0.7f)]
                   forState:UIControlStateSelected | UIControlStateHighlighted];
        switchBtn.imageEdgeInsets = UIEdgeInsetsMake(([switchBtn xf_GetWidth]-28)/2,
                                                     ([switchBtn xf_GetWidth]-16)/2,
                                                     ([switchBtn xf_GetWidth]-28)/2,
                                                     ([switchBtn xf_GetWidth]-16)/2);
        [backView addSubview:switchBtn];

        NSString *str = @"返回";
        CGFloat height = [str boundingRectWithSize:CGSizeMake([backView xf_GetWidth], MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:XFFont(10)} context:nil].size.height;
        UILabel *lab = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:str Font:XFFont(10)
                                        TextColor:XFColor(0xffffff, 1.0f)
                                            Frame:CGRectMake(0, [switchBtn xf_GetBottom]+5-1,
                                                             [switchBtn xf_GetWidth], height+1)];
        lab.numberOfLines = 0;
        lab.textAlignment = NSTextAlignmentCenter;
        [backView addSubview:lab];
    }
    return backView;
}

- (UIView *)cameraView
{
    if (!_cameraView) {
        // 默认全屏
        CGFloat width_new = XFHeight*9/16;
        CGRect frame = CGRectMake((int)((XFWidth-width_new)/2), 0, width_new, XFHeight);
        _cameraView = [UIView XF_ViewWithColor:XFColor(0x000000, 1.0f) Frame:frame];

        // 16:9 非全屏
        //_cameraView.frame = CGRectMake(0, 0, XFWidth, XFWidth *16/9);

        // 自定义大小 非全屏
        //_cameraView.frame = CGRectMake(50, (XFHeight-(XFWidth-100))/2, XFWidth-100, XFWidth-100);
        //_cameraView.layer.cornerRadius = [_cameraView xf_GetHeight]/2;
        //_cameraView.clipsToBounds = YES;
    }
    return _cameraView;
}

- (void)ApplicationWillResignActiveNoti:(NSNotification *)noti
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CTUVCHelper Shared] stopCamera];
    });
}

- (void)ApplicationDidBecomeActiveNoti:(NSNotification *)noti
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CTUVCHelper Shared] startCamera];
    });
}

@end

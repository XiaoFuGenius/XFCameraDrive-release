//
//  XFIndexViewController.m
//  WiredDemo-OC
//
//  Created by 胡文峰 on 2019/6/24.
//  Copyright © 2019 xiaofutech. All rights reserved.
//

#import "XFIndexViewController.h"

@interface XFIndexViewController ()
@property (nonatomic, strong) NSMutableString *log;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL updating;
@property (nonatomic, assign) BOOL lowPowerHint;
@end

@implementation XFIndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = XFColor(0xf6f6f6, 1.0f);

    [self.view addSubview:[self topView]];
    [self.view addSubview:[self buttonView_firmware]];
    [self.view addSubview:[self buttonView_preview]];

    CGRect frame = CGRectMake(0, XFHeight-XFSafeBottom -10 -37, XFWidth, 37);
    NSString *version = [XFUIAdaptationHelper AppShortVersion];
    version = [NSString stringWithFormat:@"%@ - build (%@)\n2019.11.11 R", version, [XFUIAdaptationHelper AppBuildVersion]];
    UILabel *label = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:version Font:XFFont(15)
                                      TextColor:XFColor(0x000000, 0.66f) Frame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [self.view addSubview:label];

    frame = CGRectMake(10, XFNaviBarHeight +45 +15, XFWidth -10*2,
                       XFHeight-58-48 -28-48 -20 -(XFNaviBarHeight +45 +15));
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.layer.borderWidth = 1.0f;
    textView.layer.borderColor = XFColor(0x333333, 1.0f).CGColor;
    textView.layer.cornerRadius = 3.0f;
    textView.clipsToBounds = YES;
    textView.font = XFFont(10);
    textView.textColor = XFColor(0x333333, 1.0f);

    textView.editable = NO;
    //textView.selectable = NO;  // iOS 11 + 会触发 滚动至最后一行 功能出现Bug；

    textView.layoutManager.allowsNonContiguousLayout = NO;
    [self.view addSubview:textView];
    self.textView = textView;

    [self performSelector:@selector(activateInitialize) withObject:nil afterDelay:1.0f];
}

- (void)activateInitialize
{
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(AccessoryPlugInNoti:)
                       name:kCTNotis_AccessoryPlugIn object:nil];
    [notiCenter addObserver:self selector:@selector(AccessoryUnplugInNoti:)
                       name:kCTNotis_AccessoryUnplugIn object:nil];
    [notiCenter addObserver:self selector:@selector(XFSessionPreparedStatusNoti:)
                       name:kCTNotis_SessionStatus object:nil];
    [notiCenter addObserver:self selector:@selector(XFBatteryPollingNoti:)
                       name:kCTNotis_BatteryPolling object:nil];
    
    XFWeakSelf(weakSelf);
//    [CTUVCHelper Shared].batteryPollingInterval = 1.0f;  // 重置电量轮询间隔
    [CTUVCHelper Shared].sessionControlEnabled = YES;
    [CTUVCHelper Shared].logHandler = ^(NSInteger level, NSString * _Nonnull log) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (level==0 || level==1) {
                [weakSelf xf_Log:log];
            } else {
                NSLog(@"[%ld] %@", (long)level, log);
            }
        });
    };
}

- (void)AccessoryPlugInNoti:(NSNotification *)noti
{
    NSLog(@"Index - AccessoryPlugInNoti");
}

- (void)AccessoryUnplugInNoti:(NSNotification *)noti
{
    NSLog(@"Index - AccessoryUnplugInNoti");
}

- (void)XFSessionPreparedStatusNoti:(NSNotification *)noti
{
    XFWeakSelf(weakSelf);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger sessionActivated = [noti.userInfo[@"Status"] integerValue];
        weakSelf.connected = sessionActivated==2;
        [weakSelf updateUI];

        if (sessionActivated != 1) {
            [weakSelf xf_Log:weakSelf.connected?@"外设已连接.":@"外设已断开或未成功连接."];
            [weakSelf xf_Log:[NSString stringWithFormat:@"Session Status: %ld", (long)sessionActivated]];
            if (!weakSelf.connected) {
//                [CTUVCHelper Shared].batteryPollingInterval = 1.0f;  // 重置电量轮询间隔
                [weakSelf xf_Log:@"-------- -------- -------- -------- --------\n"];
            } else {
                weakSelf.lowPowerHint = false;
            }
        }
    });
}

- (void)XFBatteryPollingNoti:(NSNotification *)noti
{
    XFWeakSelf(weakSelf);
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateBatteryInfo];
        if ([CTUVCHelper Shared].battery!=-1) {
            [weakSelf xf_Log:[NSString stringWithFormat:@"电量获取成功 %ld%%", (long)[CTUVCHelper Shared].battery]];
//            [CTUVCHelper Shared].batteryPollingInterval = 30.0f;  // 恢复电量轮询间隔
        } else {
            [weakSelf xf_Log:@"电量获取失败"];
        }
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateUI
{
    UIView *topView = self.view.subviews[0];
    {
        UIView *titleView = topView.subviews[0];
        {
            UIView *lightView = titleView.subviews[0];
            UILabel *title = titleView.subviews[1];
            lightView.backgroundColor = self.connected?XFColor(0x00ff84, 1.0f):XFColor(0xc9c9c9, 1.0f);
            title.text = self.connected?@"设备已连接":@"设备未连接";
        }

        [self updateBatteryInfo];
    }

    UIView *firmwareView = self.view.subviews[1];
    {
        UIButton *btn = firmwareView.subviews[0];

        UIColor *norColor = (self.connected && !self.updating)?XFColor(0x007aff, 1.0f):XFColor(0xc9c9c9, 1.0f);
        UIColor *highColor = (self.connected && !self.updating)?XFColor(0x007aff, 0.79f):XFColor(0xc9c9c9, 0.79f);
        [btn xf_SetBackgroundColor:norColor forState:UIControlStateNormal];
        [btn xf_SetBackgroundColor:highColor forState:UIControlStateHighlighted];
    }

    UIView *preView = self.view.subviews[2];
    {
        UIButton *btn = preView.subviews[0];

        UIColor *norColor = (self.connected && !self.updating)?XFColor(0x007aff, 1.0f):XFColor(0xc9c9c9, 1.0f);
        UIColor *highColor = (self.connected && !self.updating)?XFColor(0x007aff, 0.79f):XFColor(0xc9c9c9, 0.79f);
        [btn xf_SetBackgroundColor:norColor forState:UIControlStateNormal];
        [btn xf_SetBackgroundColor:highColor forState:UIControlStateHighlighted];
    }
}

- (void)updateBatteryInfo
{
    UIView *topView = self.view.subviews[0];
    {
        UIView *batteryView = topView.subviews[1];
        {
            UILabel *title = batteryView.subviews[0];
            UIProgressView *prgView = batteryView.subviews[1];
            NSString *battery = [NSString stringWithFormat:@"电量：%ld%%", (long)[CTUVCHelper Shared].battery];
            title.text = (self.connected && [CTUVCHelper Shared].battery!=-1)?battery:@"电量：未知";
            prgView.progress = (self.connected && [CTUVCHelper Shared].battery!=-1)?[CTUVCHelper Shared].battery/100.0f:0.0f;

            [self lowPowerAlert];
        }
    }
}

- (void)lowPowerAlert
{
    if (self.lowPowerHint==false
        && [CTUVCHelper Shared].battery <= 10
        && [CTUVCHelper Shared].battery != -1) {
        self.lowPowerHint = true;
        [self xf_Log:@"电量低，请充电"];
    }
}

- (UIView *)topView
{
    CGRect frame = CGRectMake(0, 0, XFWidth, XFNaviBarHeight+45);
    UIView *topView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
    {
        frame = CGRectMake((int)((XFWidth-156)/2.0), XFSafeTop+11, 156, 22);
        UIView *titleView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
        {  // 0x00ff84, 0xc9c9c9
            frame = CGRectMake(21, 6, 8, 8);
            UIView *lightView = [UIView XF_ViewWithColor:XFColor(0xc9c9c9, 1.0f) Frame:frame];
            lightView.layer.cornerRadius = [lightView xf_GetHeight]/2;
            lightView.clipsToBounds = YES;
            [titleView addSubview:lightView];

            frame = CGRectMake([lightView xf_GetRight]+8, 0, [titleView xf_GetWidth] -21 -16,
                               [titleView xf_GetHeight]);
            UILabel *label = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:@"设备未连接"
                                                   Font:XFFont_bold(17)
                                              TextColor:XFColor(0x000000, 1.0f) Frame:frame];
            [titleView addSubview:label];
        }
        [topView addSubview:titleView];

        frame = CGRectMake(16, XFNaviBarHeight+10, XFWidth-16-19, 18);
        UIView *batteryView = [UIView XF_ViewWithColor:[UIColor clearColor] Frame:frame];
        {  // 70, 28, 182
            frame = CGRectMake(0, 0, 70, [batteryView xf_GetHeight]);
            UILabel *label = [UILabel XF_LabelWithColor:[UIColor clearColor] Text:@"电量：未知"
                                                   Font:XFFont(13) TextColor:XFColor(0x000000, 0.5f)
                                                  Frame:frame];
            label.adjustsFontSizeToFitWidth = YES;
            [batteryView addSubview:label];

            CGFloat leftWidth = [batteryView xf_GetWidth]-70;
            frame = CGRectMake([label xf_GetRight]+(int)(leftWidth *28.0/(28+182)),
                               ([batteryView xf_GetHeight]-4)/2, leftWidth *182.0/(28+182), 4);
            UIProgressView *prgView = [[UIProgressView alloc] initWithFrame:frame];
            prgView.progressViewStyle = UIProgressViewStyleDefault;
            prgView.progressTintColor = XFColor(0x007aff, 1.0f);
            prgView.trackTintColor = XFColor(0xe5e5ea, 1.0f);
            prgView.progress = 0.0f;
            [batteryView addSubview:prgView];
        }
        [topView addSubview:batteryView];

        frame = CGRectMake(0, [topView xf_GetHeight]-1.0f, XFWidth, 1.0f);
        UIView *line = [UIView XF_ViewWithColor:XFColor(0x000000, 0.21f) Frame:frame];
        [topView addSubview:line];
    }

    return topView;
}

- (UIView *)buttonView_firmware
{
    CGFloat top = XFHeight-58-48;
    CGRect frame = CGRectMake(16, top -28-48, XFWidth-16*2, 48);
    UIView *view = [UIView XF_ViewWithColor:XFColor(0xffffff, 1.0f) Frame:frame];
    view.layer.cornerRadius = 10.0f;
    view.clipsToBounds = YES;

    UIButton *firmwareBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil
                                                  Title:@"固件升级" Font:XFFont_bold(17)
                                             TitleColor:XFColor(0xffffff, 1.0f) Target:self
                                                 Action:@selector(buttonView_firmwareBtnClick:)
                                                  Frame:view.bounds];
    [firmwareBtn xf_SetBackgroundColor:XFColor(0xc9c9c9, 1.0f) forState:UIControlStateNormal];
    [firmwareBtn xf_SetBackgroundColor:XFColor(0xc9c9c9, 0.79f) forState:UIControlStateHighlighted];
    firmwareBtn.layer.cornerRadius = 10.0f;
    firmwareBtn.clipsToBounds = YES;

    [view addSubview:firmwareBtn];  // 0x007aff, 0xc9c9c9
    
    view.hidden = YES;
    
    return view;
}

- (void)buttonView_firmwareBtnClick:(UIButton *)sender
{
    if (!self.connected) {
        return;
    }

    XFWeakSelf(weakSelf);
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"固件 版本选择" message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"fw_10001"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf FwVersion:@"fw_10001"];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)FwVersion:(NSString *)version
{
    self.updating = true;
    [self updateUI];

    XFWeakSelf(weakSelf);
    NSString *zip_all = [[NSBundle mainBundle] pathForResource:version ofType:@"zip"];
    [[CTUVCHelper Shared] updateFirmware:zip_all Response:^(NSInteger ret, int status, int value) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret!=0) {
                if (ret==-3) {
                    [weakSelf xf_Log:@"Fw 未成功完成升级，电量不足"];
                } else {
                    [weakSelf xf_Log:[NSString stringWithFormat:@"Fw 未成功完成升级，errCode：%ld", (long)ret]];
                }

                weakSelf.updating = false;
                [weakSelf updateUI];
                return;
            }

            if (status==1) {
                if (value>0 && (value % 10==0 || value <=5 || value >= 96)) {
                    [weakSelf xf_Log:[NSString stringWithFormat:@"Fw 固件升级进度：%d", value]];
                }
                return;
            }

            weakSelf.updating = false;
            [weakSelf updateUI];
            [weakSelf xf_Log:@"Fw 升级完成，设备已自动关闭"];
        });
    }];
}

- (UIView *)buttonView_preview
{
    CGFloat top = XFHeight-58-48;
    CGRect frame = CGRectMake(16, top, XFWidth-16*2, 48);
    UIView *view = [UIView XF_ViewWithColor:XFColor(0xffffff, 1.0f) Frame:frame];
    view.layer.cornerRadius = 10.0f;
    view.clipsToBounds = YES;

    UIButton *connectBtn = [UIButton XF_ButtonWithColor:[UIColor clearColor] Image:nil
                                                  Title:@"镜头预览" Font:XFFont_bold(17)
                                             TitleColor:XFColor(0xffffff, 1.0f) Target:self
                                                 Action:@selector(buttonView_connectBtnClick:)
                                                  Frame:view.bounds];
    [connectBtn xf_SetBackgroundColor:XFColor(0xc9c9c9, 1.0f) forState:UIControlStateNormal];
    [connectBtn xf_SetBackgroundColor:XFColor(0xc9c9c9, 0.79f) forState:UIControlStateHighlighted];
    connectBtn.layer.cornerRadius = 10.0f;
    connectBtn.clipsToBounds = YES;

    [view addSubview:connectBtn];  // 0x007aff, 0xc9c9c9

    return view;
}

- (void)buttonView_connectBtnClick:(UIButton *)sender
{
    if (!self.connected) {
        return;
    }

    XFViewController *ctr = [NSClassFromString(@"XFCameraViewController") new];
    ctr.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:ctr animated:YES completion:nil];
}

#pragma mark >> Log <<

- (NSMutableString *)log
{
    if (!_log) {
        _log = [NSMutableString string];
    }
    return _log;
}

- (void)xf_Log:(NSString *)logX
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"[HH:mm:ss.SSS]："];
        NSString *date = [formatter stringFromDate:[NSDate date]];

        [self.log appendFormat:@"%@%@\r\n", date, logX];
        //NSLog(@"%@%@\r\n", date, logX);

        self.textView.text = self.log;
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 1)];
    });
}

@end

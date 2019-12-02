//
//  CTUVCHelper.h
//  XFCameraDrive
//
//  Created by 胡文峰 on 2019/7/8.
//  Copyright © 2019 xiaofutech. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 检测到外设插入
 通知无返回参数
 */
extern NSNotificationName const kCTNotis_AccessoryPlugIn;

/**
 检测到外设拔出
 通知无返回参数
 */
extern NSNotificationName const kCTNotis_AccessoryUnplugIn;

/**
 会话状态
 通知内置返回参数：noti.userInfo['Status']
 Status：2 已创建，1 创建中，0 外设拔出致session关闭，-1 创建失败a，-2 创建失败b
 */
extern NSNotificationName const kCTNotis_SessionStatus;

/**
 电量轮询 单次完成
 通知无返回参数，可由属性 battery 获取结果
 注1：外设刚开机状态下的电量成功获取会有延迟，详见demo中的”电量轮询“相关代码
 注2：若不设置轮询，则外设首次连接成功后，该通知仅返回初次电量查询结果
 */
extern NSNotificationName const kCTNotis_BatteryPolling;


@interface CTUVCHelper : NSObject

/**
 日志输出控制回调
 @param level 日志级别：0 关键日志，1 调试日志
 @param log 日志内容
 */
@property (nonatomic, copy) void(^logHandler)(NSInteger level, NSString *log);

/**
 电量轮询时间间隔；默认值 0，不轮询；自定义值需 >= 1，否则设置不生效
 设定轮询间隔后，可由通知 kCTNotis_BatteryPolling 接收轮询结果
 */
@property (nonatomic, assign) NSTimeInterval batteryPollingInterval;
@property (nonatomic, assign, readonly) NSInteger battery;  // 电量信息，-1 暂未读取到/读取失败

@property (nonatomic, strong, readonly) NSString *protocolName; // iAP2 外设协议名称

/**
 会话自动启停控制开关，默认 NO
 开启状态下：
 应用退至后台时，Sdk会尝试主动停用当前会话
 应用回到前台时，Sdk会尝试主动激活新的会话
 */
@property (nonatomic, assign) BOOL sessionControlEnabled;
@property (nonatomic, assign, readonly) BOOL sessionActivated;  // 会话激活状态

@property (nonatomic, strong, readonly) NSString *ID;  // 外设ID
@property (nonatomic, assign, readonly) NSInteger KernalVersion;  // 外设核心固件版本

@property (nonatomic, strong, readonly) NSString *serialNumber;  // 外设序列号
@property (nonatomic, strong, readonly) NSString *fw1247Version; // 1247芯片 固件版本

@property (nonatomic, assign, readonly) BOOL cameraActivated;  // 摄像头激活状态
@property (nonatomic, assign) BOOL captureMaskEnabled;  // 拍照遮罩(隐藏灯光切换的效果)，默认YES
@property (nonatomic, assign, readonly) NSInteger lightMode;  // 0 标准光，1 偏振光，默认 0

/**
 UVC协议驱动对象
 @return 唯一实例
 */
+ (CTUVCHelper *)Shared;

#pragma mark ======== ======== ======== 基础能力支持 ======== ======== ========

/**
 固件升级
 @param fw_local_path 固件升级数据zip包本地缓存地址
 @param response 升级回调
 注：ret==0 表示成功，-1 固件升级不成功，-2 外设未连接，-3 外设电量低，-4 zip文件解压缩失败，-5 已解压固件包文件错误，
 status：当前升级状态，0 升级完成，1 正在升级
 value：当前升级进度，0~100
 */
- (void)updateFirmware:(NSString *_Nullable)fw_local_path
              Response:(nullable void(^)(NSInteger ret, int status, int value))response;

/**
 固件版本状态校验（检查固件版本是否无差错）
 @return 校验状态：-1 外设未连接，0 正常，1 固件版本有差错，需要升级
 */
- (NSInteger)firmwareStatusCheck;


#pragma mark ======== ======== ======== 图像预览处理 ======== ======== ========

/**
 预配置 图像预览 相关参数
 @param bearerView 图像预览 承载视图
 @param lightMode 初始灯光模式
 @param startCompletion 开启 完成回调
 @param stopCompletion 关闭 完成回调
 注：ret==0 表示成功
 */
- (void)setupBearerView:(UIView *)bearerView
              LightMode:(NSInteger)lightMode
        StartCompletion:(nullable void(^)(NSInteger ret))startCompletion
         StopCompletion:(nullable void(^)(NSInteger ret))stopCompletion;

/**
 释放摄像头控制对象（在释放掉图像预览界面时，与 -setupBearerView: 成对出现）
 */
- (void)releasedCamera;

/**
 开启 图像预览
 */
- (void)startCamera;

/**
 关闭 图像预览
 */
- (void)stopCamera;

/**
 拍照
 @param completion 完成回调
 注：ret==0 表示成功，rgbImage：标准光图片，plImage：偏振光图片
 ret==1 表示已取得第一张图片，与当前灯光模式相对应
 */
- (void)capture:(void(^)(NSInteger ret, UIImage * _Nullable rgbImage,
                         UIImage * _Nullable plImage))completion;

/**
 设置灯光模式
 @param lightMode 目标模式
 @param completion 完成回调
 注：ret==0 表示成功，lightMode：当前灯光模式
 */
- (void)setLightMode:(NSInteger)lightMode
          Completion:(nullable void(^)(NSInteger ret, NSInteger lightMode))completion;

@end

NS_ASSUME_NONNULL_END

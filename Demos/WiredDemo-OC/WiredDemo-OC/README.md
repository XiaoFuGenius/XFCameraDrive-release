#  WiredDemo

## <工程配置>
### Alpha.集成 ~
##### ~> ```Pods```集成```XFCameraDrive```，详情见```Demo```中的```Podfile```文件；
> a1. 添加```source```；
```source 'https://github.com/CocoaPods/Specs.git'```
```source 'https://github.com/XiaoFuGenius/xiaofu-specs.git'```
> a2.支持```iOS```版本 8.0+ ；
> b1.```pod 'XFCameraDrive-release'```，发布版本，用于发布到```appstore```或```外部测试版本```；
> b2.```pod 'XFCameraDrive-develop'```，开发版本，用于支持模拟器运行，```Sdk```内部方法将不会执行；

###### ps.```[CocoaPods]```帮助；
> a.```#import ""```方式，```Xcode```不提示```Pods```中的头文件的问题；
    解决方法：```TARGETS``` -> ```Build Settings```  -> ```User Header Search Paths``` ->  添加```$(SRCROOT)```，设置为```recursive```；

##### ~> ```手动```集成```XFCameraDrive```
> a1.从```https://github.com/XiaoFuGenius/XFCameraDrive-release``` 下载```Sdk```的发布版本；
> a2.从```https://github.com/XiaoFuGenius/XFCameraDrive-develop``` 下载```Sdk```的开发版本；
> b1.将发布(或开发)版本的```XFCameraDrive.framework```加入工程；
iOS 13：
> b2. ```TARGETS``` -> ```General``` -> ```Frameworks, Libraries, and Embedded Content``` 设定为 ```Embed& Sign```
iOS 12 及以前：
> b2.```TARGETS``` -> ```General``` -> ```Linked Frameworks and Libraries```删除```XFCameraDrive.framework```；
> b3.```TARGETS``` -> ```General``` -> ```Embedded Binaries```添加```XFCameraDrive.framework```；

##### ~> 相关配置 ~
> a1.（建议新增预编译文件）```PrefixHeader.pch```预编译文件中添加```#import <XFCameraDrive/XFCameraDrive.h>```；
> a2.（可能的）```TARGETS``` -> ```Build Settings``` -> ```Enable Bitcode``` 设置为```NO```；
> a3.```Info.plist```文件中添加```Supported external accessory protocols``` <Array>，
    并增加元素 ```com.xxxxxx.protocolx```（此处为样例，具体协议名称，请向```Sdk```支持同事获取）
    以将应用支持的外设协议添加进“手机系统”外设协议支持列表
> a4.```TARGETS``` -> ```Capabilities``` -> ```Background Modes``` -> 勾选```External accessory communication```
    以开启，应用即使退到后台，仍能与外设保持连接的能力

## <Sdk功能api说明，及示例代码>
#### ~> api简述
> ```CTUVCHelper.h```

#### ~> 示例代码
> a1.示例代码见```WiredDemo```中的相关```api```调用；
> a2.建议参考```WiredDemo```中的```api```调用方式和逻辑；
> a3.更多详情或疑问，请联系我们的``Sdk``支持同事；

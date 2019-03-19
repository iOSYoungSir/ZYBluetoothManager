//
//  ZYBluetoothManager.h
//  BluetoothManager
//
//  Created by tzyang on 2019/3/19.
//  Copyright © 2019年 tzyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

//设备类型
typedef NS_ENUM(NSInteger,PeripheralType) {
    PeripheralTypeA,
    PeripheralTypeB
};

/**
 特征值改变
 */
typedef void (^BlueToothUpdateValueCallBack) (PeripheralType type ,id updatedResult);

/**
 订阅特征值
 */
typedef void (^BlueToothUpdateNotifiyCallBack) (PeripheralType type);

/**
 蓝牙不可用
 */
typedef void (^BlueToothUnavailableCallBack) (void);

/**
 连接断开
 */
typedef void (^BlueToothDisConnectCallBack) (void);

@interface ZYBluetoothManager : NSObject

@property (nonatomic , copy) BlueToothUpdateValueCallBack updateValueCallBack;
@property (nonatomic , copy) BlueToothUpdateNotifiyCallBack updateNotifiyCallBack;
@property (nonatomic , copy) BlueToothUnavailableCallBack unavailableCallBack;
@property (nonatomic , copy) BlueToothDisConnectCallBack disConnectCallBack;

+ (instancetype)shareManager;

/**
 开始扫描设备
 @param macAddress mac地址
 @param number 设备编号
 */
- (void)startScanWithMacAddress:(NSString *)macAddress
                   deviceNumber:(NSString *)number;

/**
 停止扫描
 */
- (void)stopScan;

/**
 扫描服务
 */
- (void)scanService;

/**
 写入命令
 @param data 数据
 */
- (void)writeValue:(id)data;

/**
 手动断开连接
 */
- (void)disConnect;

@end

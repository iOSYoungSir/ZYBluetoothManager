//
//  ZYBluetoothManager.m
//  BluetoothManager
//
//  Created by tzyang on 2019/3/19.
//  Copyright © 2019年 tzyang. All rights reserved.
//

#import "ZYBluetoothManager.h"
#import "ZYHandleDataManager.h"

static ZYBluetoothManager * manager = nil;

//广播包key
static NSString * const kAdDataKey = @"kCBAdvDataManufacturerData";

#pragma mark 阿斯丹顿
//服务UUID
static NSString * const kServiceUUID = @"";
//特征值 - 读
static NSString * const kCharacteristicReadUUID = @"";
//特征值 - 写
static NSString * const kCharacteristicWriteUUID = @"";
////通知UUID
//static NSString * const kNotifyUUID = @"";
////写入UUID
//static NSString * const kWriteDataUUID = @"";

@interface ZYBluetoothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>

#pragma mark 蓝牙
//中心管理者
@property (nonatomic , strong) CBCentralManager * centralManager;
//蓝牙状态
@property (nonatomic , assign) CBCentralManagerState centralState;
//设备
@property (nonatomic , strong) CBPeripheral * peripheral;
//特征值 - 写
@property (nonatomic , strong) CBCharacteristic * writeCharacteristic;
//特征值 - 通知
@property (nonatomic , strong) CBCharacteristic * notifyCharacteristic;

#pragma mark 数据源
//存储的设备
@property (nonatomic , strong) NSMutableArray * peripheralArray;

#pragma mark 设备信息
//设备mac地址
@property (nonatomic , copy) NSString * peripheralMacAddress;
//设备编号
@property (nonatomic , copy) NSString * peripheralNumber;
//设备类型
@property (nonatomic , assign) PeripheralType peripheralType;
//设备连接状态
@property (nonatomic , assign) BOOL isConnected;

@end

@implementation ZYBluetoothManager

#pragma mark init

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZYBluetoothManager alloc]init];
    });
    return manager;
}

- (id)init{
    if (self = [super init]) {
        if (self.centralManager == nil) {
            self.isConnected = NO;
            self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        }
    }
    return self;
}

/**
 从制定的内存区域读取信息创建实例，如果需要的单例已经有了，就需要禁止修改当前单例，返回nil
 */
+ (id)allocWithZone:(struct _NSZone *)zone{
    
    @synchronized(self){
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}

- (NSMutableArray *)peripheralArray{
    if (!_peripheralArray) {
        _peripheralArray = [[NSMutableArray alloc]init];
    }
    return _peripheralArray;
}

#pragma mark Public

//开始扫描
- (void)startScanWithMacAddress:(NSString *)macAddress deviceNumber:(NSString *)number{
    
    self.peripheralMacAddress = macAddress;
    self.peripheralNumber = number;
    
    //如果初始化centralManager后马上调用扫描会报错 需要延迟执行
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startScanning];
    });
}

//扫描外设
- (void)startScanning{
    ZYLog(@"开始扫描");

    //先判断是否有连接设备
    if (self.peripheral) {
        if (self.peripheral.state == CBPeripheralStateConnected || self.isConnected == YES) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
            ZYLog(@"断开上次连接的设备成功");
        }
        self.peripheral = nil;
    }
    
    if (self.centralManager.delegate == nil) {
        self.centralManager.delegate = self;
    }
    
    if (self.centralState == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    else{
        [self stopScan];
        
        ZYLog(@"蓝牙不可用，请开启或检查蓝牙后操作");
        !self.unavailableCallBack ? : self.unavailableCallBack();
    }
}

//停止扫描
- (void)stopScan{
    ZYLog(@"停止扫描");
    [self.centralManager stopScan];
}

/**
 扫描服务
 */
- (void)scanService{
    if (self.peripheral) {
        //如果断开连接，重连
        if (self.isConnected == NO || self.peripheral.state != CBPeripheralStateConnected) {
            //重新连接设备
            [self.centralManager connectPeripheral:self.peripheral options:nil];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //扫描服务
            [self.peripheral discoverServices:nil];
        });
    }
}

/**
 写入命令
 */
- (void)writeValue:(id)data{
    
    if (data) {
        [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
//        [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse | CBCharacteristicWriteWithoutResponse];
    }
    else{
        ZYLog(@"写入指令有误");
    }
}

//手动断开连接
- (void)disConnect{
    //断开连接
    if (self.peripheral) {
        if (self.peripheral.state == CBPeripheralStateConnected || self.isConnected == YES) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
            ZYLog(@"断开连接成功");
            self.isConnected = NO;
        }
        self.peripheral = nil;
    }
    self.peripheral.delegate = nil;
}

#pragma mark Private

//获取外设mac地址 默认16位
- (NSString *)macAddressWith:(NSString *)aString{
    NSMutableString *macString = [[NSMutableString alloc] init];
    if (aString.length >= 16) {
        [macString appendString:[[aString substringWithRange:NSMakeRange(4, 2)] uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[aString substringWithRange:NSMakeRange(6, 2)] uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[aString substringWithRange:NSMakeRange(8, 2)] uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[aString substringWithRange:NSMakeRange(10, 2)] uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[aString substringWithRange:NSMakeRange(12, 2)] uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[aString substringWithRange:NSMakeRange(14, 2)] uppercaseString]];
    }
    
    ZYLog(@"macString:%@",macString);
    return macString;
}

#pragma mark CBCentralManagerDelegate
// 当状态更新时调用(如果不实现会崩溃)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            ZYLog(@"蓝牙状态-> 未知");
            break;
        case CBCentralManagerStateResetting:
            ZYLog(@"蓝牙状态-> 重置");
            break;
        case CBCentralManagerStateUnsupported:
            ZYLog(@"蓝牙状态-> 不支持");
            break;
        case CBCentralManagerStateUnauthorized:
            ZYLog(@"蓝牙状态-> 未授权");
            break;
        case CBCentralManagerStatePoweredOff:
            ZYLog(@"蓝牙状态-> 关闭");
            break;
        case CBCentralManagerStatePoweredOn:
            ZYLog(@"蓝牙状态-> 可用");
            break;
        default:
            break;
    }
    
    self.centralState = (CBCentralManagerState)central.state;
    
    if (central.state != CBCentralManagerStatePoweredOn) {//关闭
        
        [self stopScan];
        
        ZYLog(@"蓝牙不可用");
    }
}

/**
 发现设备
 @param central 中心管理者
 @param peripheral 扫描到的设备
 @param advertisementData 广告信息
 @param RSSI 信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    ZYLog(@"发现设备->\n name=%@\n advertisementData=%@\n UUIDString=%@\n services=%@\n 信号->%@",peripheral.name,advertisementData,peripheral.identifier.UUIDString,peripheral.services,RSSI);
    
    NSData *data = advertisementData[kAdDataKey];
    NSString *str = [ZYHandleDataManager transformStringWithData:data];
    
    if ([[self macAddressWith:str] isEqualToString:self.peripheralMacAddress]) {//mac地址匹配，连接设备
        //停止扫描
        [self.centralManager stopScan];
        
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:self.peripheral options:nil];
        
        if (![self.peripheralArray containsObject:peripheral]){
            [self.peripheralArray addObject:self.peripheral];
        }
    }
}

/**
 连接成功
 @param central 中心管理者
 @param peripheral 连接成功的设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    ZYLog(@"连接设备成功-> %@",peripheral.name);
    
    //停止扫描
    [self.centralManager stopScan];
    self.peripheral.delegate = self;
    
    self.isConnected = YES;
    
    //扫描服务
    [self scanService];
}

/**
 连接失败
 @param central 中心管理者
 @param peripheral 连接失败的设备
 @param error 错误信息
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (error) {
        ZYLog(@"连接失败-> %@",error.description);
        self.isConnected = NO;
    }
}

/**
 连接断开
 @param central 中心管理者
 @param peripheral 连接断开的设备
 @param error 错误信息
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if (error) {
        self.isConnected = NO;
        ZYLog(@"连接断开-> %@",error.description);
        if (self.peripheral) {
            //重新连接
            [self.centralManager connectPeripheral:self.peripheral options:nil];
        }
    }
}

#pragma mark CBPeripheralDelegate
/**
 扫描到服务
 @param peripheral 服务对应的设备
 @param error 扫描错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *service in peripheral.services) {
        ZYLog(@"服务UUID: %@",service.UUID);
        // 获取对应的服务
        if ([service.UUID.UUIDString isEqualToString:kServiceUUID]){
            // 根据服务去扫描特征
            [self.peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

/**
 扫描到对应的特征
 @param peripheral 设备
 @param service 特征对应的服务
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    ZYLog(@"发现特征值=%@", service.characteristics);
    if (!error) {
        // 遍历所有的特征
        [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull characteristic, NSUInteger idx, BOOL * _Nonnull stop) {
            ZYLog(@"特征的读写等属性=%lu", (unsigned long)characteristic.properties);
            
            if (characteristic.properties == CBCharacteristicPropertyNotify ||
                [characteristic.UUID.UUIDString isEqualToString:kCharacteristicReadUUID]) {
                self.notifyCharacteristic = characteristic;
                // 订阅, 实时接收
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else if (characteristic.properties == CBCharacteristicPropertyWrite){
                self.writeCharacteristic = characteristic;
            }
        }];
    }
    else{
        ZYLog(@"发现特征error-> %@",error.description);
    }
}

/**
 根据特征读到数据
 @param peripheral 读取到数据对应的设备
 @param characteristic 特征
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    ZYLog(@"didUpdateValue 特征值=%@",characteristic);
    
    if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicReadUUID]){
        
        if (error) {
            ZYLog(@"特征值=%@ == error %@",characteristic.UUID, error);
        }
        else{
            ZYLog(@"收到特征值=%@ updated 发来的数据: %@", characteristic.UUID, characteristic.value);
            
            if (characteristic.value) {
                NSMutableDictionary * dataValueDic = [[NSMutableDictionary alloc]init];
                [dataValueDic setValue:self.peripheral forKey:@"peripheral"];
                [dataValueDic setValue:characteristic.value forKey:@"value"];
                
                !_updateValueCallBack ? : _updateValueCallBack(self.peripheralType,dataValueDic);
            }
        }
    }
}

//更新描述值的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    ZYLog(@"描述(%@)",descriptor.description);
}

//发现外设的特征的描述数组
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    // 在此处读取描述即可
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        //self.descriptor = descriptor;
        ZYLog(@"发现外设的特征descriptor(%@)",descriptor);
        [self.peripheral readValueForDescriptor:descriptor];
    }
}

//写入指令 是否成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        ZYLog(@"特征值=%@ 写入失败 error %@",characteristic.UUID,error.description);
    }
    else{
        ZYLog(@"特征值=%@ 写入成功",characteristic.UUID);
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    ZYLog(@"通知发生改变->特征值=%@,isNotifying=%@",characteristic.UUID,characteristic.isNotifying?@"YES":@"NO");
    if (characteristic.isNotifying == YES) {//订阅成功
        !_updateNotifiyCallBack ? : _updateNotifiyCallBack(self.peripheralType);
    }
}


@end

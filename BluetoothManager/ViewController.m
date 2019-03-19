//
//  ViewController.m
//  BluetoothManager
//
//  Created by tzyang on 2019/3/19.
//  Copyright © 2019年 tzyang. All rights reserved.
//

#import "ViewController.h"

//Tool
#import "ZYBluetoothManager.h"
#import "ZYHandleDataManager.h"

@interface ViewController ()

@property (nonatomic , strong) ZYBluetoothManager *btManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //扫描设备
    [self.btManager startScanWithMacAddress:@"Mac地址" deviceNumber:@"设备编号"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self bluetooth];
}


- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    //断开连接
    [self.btManager disConnect];
}

- (void)bluetooth{
    
    self.btManager = [ZYBluetoothManager shareManager];

    __weak typeof(self) weakSelf = self;
    
    self.btManager.updateNotifiyCallBack = ^(PeripheralType type) {
        //写入指令
        [weakSelf.btManager writeValue:[weakSelf getTokenCommand]];
    };
    
    self.btManager.updateValueCallBack = ^(PeripheralType type, id updatedResult) {
        //拿到数据的相关操作
    };
}

// 获取令牌指令 加密
- (NSData *)getTokenCommand{
    //key
    Byte keyByte[] = {0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01};
    Byte byte[] = {0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02};
    
    NSData *aData = [[NSData alloc] initWithBytes:byte length:16];
    NSData *aesData = [ZYHandleDataManager aes128EncryptWithData:aData key:keyByte];
    return aesData;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

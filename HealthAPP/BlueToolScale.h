//
//  BlueTools.h
//  Midea-engine
// 体质秤
//  Created by ios－dai on 15/8/26.
//  Copyright (c) 2015年 Midea. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BlueToolDelegate.h"

@interface BlueToolScale : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
{
     NSTimer *scanOutTimer; //扫描外围设备超时
     CBPeripheral *currPeripheral; //当前外围设备（蓝牙秤）
     NSMutableData *currData;//接收到的数据
     NSMutableString *currStr;
     CBCharacteristic *noticyCBCharacteristic;//读取特征
     CBCharacteristic *writeCBCharacteristic;//写数据特征
}
@property(nonatomic,weak)id<BlueToolDelegate>delegate;

@property (strong, nonatomic) CBCentralManager  *centralManager; //当前中心设备（手机）
@property(strong,nonatomic)NSString *idString;//用来区分设备类别，是体质秤还是血压计，这里写死了体质秤

+(BlueToolScale*)shareBlueTool;

#pragma mark- 连接蓝牙
-(void)scanBlueAndConnect;
#pragma mark- 写数据
-(void)writeData:(NSString*)strData;
#pragma mark- 断开蓝牙
-(void)disConnectBlue;



@end

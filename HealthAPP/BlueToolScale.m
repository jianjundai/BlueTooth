//
//  BlueTools.m
//  Midea-engine
//
//  Created by ios－dai on 15/8/26.
//  Copyright (c) 2015年 Midea. All rights reserved.
//

#import "BlueToolScale.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <memory.h>
@implementation BlueToolScale

#pragma mark - crc16验证
unsigned short CRC16(unsigned char *buff,unsigned char length)
{
    unsigned short message;
    unsigned char temp,i,j;
    message=0;
    message=((message^(*buff))<<8)^(*(buff+1));
    for(j=2;j<length;j++){
        temp=*(buff+j);
        for(i=8;i>0;i--){
            if((message&0x8000)==0x8000){
                if((temp&0x80)==0x80)
                    message=(((message<<1)|0x01)^0x1021);
                else
                    message=((message<<1)^0x1021);
            }
            else
            { if((temp&0x80)==0x80)
                message=((message<<1)|0x01);
            else
                message=(message<<1);
            }
            temp=temp<<1;
        }
    
    }
    NSLog(@"message==%0x",message);
      return message;
}


bool CheckCRC16(unsigned char *puchMsg, unsigned short usDataLen){
    
    unsigned char check[100]={0};
    memcpy(check, puchMsg, usDataLen-2);
    unsigned short crc16= CRC16(check, usDataLen-2);
    
    unsigned char crcChar1=crc16>>8;
    unsigned char crcChar2=crc16;
    if(crcChar1==puchMsg[usDataLen-2]&&crcChar2==puchMsg[usDataLen-1]){
        return YES;
    }
    
    return NO;
}



#pragma mark- 单利
+(BlueToolScale*)shareBlueTool
{
    static BlueToolScale *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}
- (id)init
{
    self = [super init];
    if (self != nil) {
        currData=[[NSMutableData alloc]init];
        currStr=[[NSMutableString alloc]init];
        self.idString=@"MW-S1";
           }
    return self;
}


#pragma mark - 检查蓝牙是否可用
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"stateee==%ld",(long)central.state);
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        return;
    }
    [self scan];

}
#pragma mark - 扫描蓝牙连接蓝牙
-(void)scanBlueAndConnect{
    if(_centralManager&&_centralManager.state==CBCentralManagerStatePoweredOn){
        [self scan];
        
    }else{
        _centralManager =  nil;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
}
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:nil];
    
    NSLog(@"Scanning started");
    //设置6秒扫描超时
    scanOutTimer=[NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(scanOutTime) userInfo:nil repeats:YES];
    
    
    
}
#pragma mark- 连接蓝牙
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if(peripheral){
        
        if([peripheral.name hasPrefix:@"MW-S"]){
           //根据蓝牙名称来判断是非是体质秤
                [self.centralManager stopScan];
                NSLog(@"Scanning stopped");
                NSLog(@"连接蓝牙 name== %@  id== %@  state==%ld", peripheral.name, peripheral.identifier,(long)peripheral.state);
                currPeripheral=peripheral;
                [self.centralManager connectPeripheral:peripheral options:nil];
            }
    
    }
    
    
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接蓝牙Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    
    if(scanOutTimer){
        [scanOutTimer invalidate];
        scanOutTimer=nil;
    }

    if(self.delegate&&[self.delegate respondsToSelector:@selector(connectBlueFaild:)]){
        [self.delegate connectBlueFaild:1001];
    }
    
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接蓝牙 suceed＝%@",peripheral.name);
    if(self.delegate&&[self.delegate respondsToSelector:@selector(connectBlueSucceed:)]){
        
        NSString *blueStr=[NSString stringWithFormat:@"%@===%@",self.idString,peripheral.identifier.UUIDString];
        
        [self.delegate connectBlueSucceed:blueStr];
    }

    if(scanOutTimer){
        [scanOutTimer invalidate];
        scanOutTimer=nil;
    }

    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    
}

#pragma mark -  发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    if (error)
    {
        NSLog(@"发现服务Error discovering services: %@", [error localizedDescription]);
       
         [self cleanup];
      
        return;
    }
    
   
    for (CBService *service in peripheral.services)
    {
         NSLog(@"serviceuuid=%@",service.UUID);
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFB0"]]){
            
             [peripheral discoverCharacteristics:nil forService:service];
    
        }

    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    
    if (error) {
        NSLog(@"发现特征Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
   
    for (CBCharacteristic *characteristic in service.characteristics)
    {        
        if([characteristic.UUID.UUIDString isEqual:@"FFB2"]){
            
              //监听设备
            NSLog(@"监听设备characteristics:%@ for service: %@ pp=%0lx", characteristic.UUID, service.UUID,(unsigned long)characteristic.properties);
            
            if(characteristic.properties==CBCharacteristicPropertyNotify){
                noticyCBCharacteristic=characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else{
                writeCBCharacteristic=characteristic;
            }
        }
    }
    
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
#pragma mark- 扫描到数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
     NSLog(@"characteristic.value.===%@",characteristic.value);
    
    if(characteristic.value.length>0){
        //开始接收
            NSData *startValue=characteristic.value;
            char *start=(char*)[startValue bytes];
            
            NSMutableString *mStr=[[NSMutableString alloc]initWithCapacity:0];
            
            for (int i=0;i<startValue.length;i++)
            {
                [mStr appendFormat:@"%02X",start[i]&0xff];
            }
            NSLog(@"单次sssss===%@",mStr);
        
        
        //开始标志
        if([mStr hasPrefix:@"AA55"]){
            [currData setLength:0];
            currStr=[NSMutableString stringWithFormat:@""];
        }
        else{
            return;
        }
        
        [currData appendData:characteristic.value];
       
        //计算长度
        int length;
        unsigned char *allChar=(unsigned char*)[currData bytes];
        if(currData.length>2){
            length=allChar[2]&0xff;
        }
        NSLog(@"数据长度＝＝＝%d",length);
        
        //接收完成
        if(currData.length>=length){
            //crc16验证
          BOOL isCrc16  =  CheckCRC16(allChar, length);
            NSLog(@"crc16验证==%d",isCrc16);
            if(isCrc16){
            
            }
            else{
               
            }
            
                char *currChar=(char*)[currData bytes];
                for (int i=0;i<length;i++)
                {
                    printf("%02X",allChar[i]&0xff);//16进制
                    //截取给H5 的数据
                    if(i>2&&i<length-2){
                        [currStr appendFormat:@"%02X",currChar[i]&0xff];
                    }
                }
                NSLog(@"接收数据成功currstr==%@",currStr);
                
                if(self.delegate&&[self.delegate respondsToSelector:@selector(receiveBlueData:)]){
                    [self.delegate receiveBlueData:currStr];
                }
           
            [currData setLength:0];
            currStr=[NSMutableString stringWithFormat:@""];
        }
    
    }
    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    
    if (error)
    {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
        [self cleanup];

    }
    // Notification has started
    if (characteristic.isNotifying)
    {
        NSLog(@"Notification began on %@", characteristic);
        
      
    }
    // Notification has stopped
    else {
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self cleanup];
        
    }
}

#pragma mark- 蓝牙断开
-(void)disConnectBlue{
    NSLog(@"断开蓝牙");
    [self.centralManager cancelPeripheralConnection:currPeripheral];
    [self cleanup];
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected：%@",peripheral);
    if(self.delegate&&[self.delegate respondsToSelector:@selector(blueDisConnect:)]){
        
        [self.delegate blueDisConnect:self.idString];
    }

    
   
}

- (void)cleanup
{
    if(scanOutTimer){
        [scanOutTimer invalidate];
        scanOutTimer=nil;
    }
    if(currPeripheral.state==CBPeripheralStateConnected||currPeripheral.state==CBPeripheralStateConnecting){
        //断开连接
        NSLog(@"断开蓝牙");
        [self.centralManager cancelPeripheralConnection:currPeripheral];
    }
    else{
        NSLog(@"cleanup");
    }
   
    
}
-(void)scanOutTime{
    
    if(scanOutTimer){
        [scanOutTimer invalidate];
        scanOutTimer=nil;
        NSLog(@"连接超时");
        if(self.delegate&&[self.delegate respondsToSelector:@selector(connectBlueFaild:)]){
            [self.delegate connectBlueFaild:1000];
        }
    }

}

-(void)writeData:(NSString*)strData{
    
    
    unsigned long length1=strData.length;
    
    NSLog(@"llll==%lu",length1);
    if(length1%2!=0){
        NSLog(@"写的数据错误＝%@",strData);
        return;
    }
   
    unsigned char  writeChar[100]={0};
    
    writeChar[0]=0xaa;
    writeChar[1]=0x55;
    writeChar[2]=5+length1/2;
    
    for(int i=0;i<length1;i++){
    
        if(i%2==0){
            int j=i/2;
            unsigned char ch1 = [strData characterAtIndex: i];
            unsigned char ch2 = [strData characterAtIndex: i+1];
            
           
            int chInt = 0;
            
            if(ch1>=48&&ch1<=57){
                chInt=(ch1-48)*16;
            }
            if(ch1>=65&&ch1<=70){
                chInt=(ch1-55)*16;
            }
            if(ch1>=97&&ch1<=102){
                chInt=(ch1-87)*16;
            }
            
            if(ch2>=48&&ch2<=57){
                chInt=chInt+ch2-48;
            }
            if(ch2>=65&&ch2<=70){
                 chInt=chInt+ch2-55;
            }
            if(ch2>=97&&ch2<=102){
                chInt=chInt+ch2-87;
            }
      
            writeChar[j+3]=chInt;
          
        }
        
    }
    
     unsigned short crc16= CRC16(writeChar, length1/2+3);
    //ea95
    writeChar[length1/2+3]=crc16>>8;
     writeChar[length1/2+4]=crc16;
   
    for(int i=0;i<length1/2+5;i++){
        printf("%02X-",writeChar[i]);
    }
    
    
    NSLog(@"check==%d",CheckCRC16(writeChar, length1/2+5));
    
    if(writeCBCharacteristic&&currPeripheral){
    NSData *adata = [[NSData alloc] initWithBytes:writeChar length:length1/2+5];
   [currPeripheral writeValue:adata forCharacteristic:writeCBCharacteristic type:CBCharacteristicWriteWithoutResponse];
        NSLog(@"写数据");
    }
    
   
}





@end

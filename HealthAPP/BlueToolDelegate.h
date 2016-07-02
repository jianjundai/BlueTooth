//
//  BlueToolProtoclo.h
//  HealthAPP
//
//  Created by ios－dai on 15/10/1.
//  Copyright © 2015年 ios－dai. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BlueToolDelegate <NSObject>

//接收到数据
- (void)receiveBlueData:(NSString*)dataString;

//连接蓝牙成功
-(void)connectBlueSucceed:(NSString*)blueId;
//连接蓝牙失败
-(void)connectBlueFaild:(NSInteger)faildTag;

//断开连接
-(void)blueDisConnect:(NSString*)blueString;

@end



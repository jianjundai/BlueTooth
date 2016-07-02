//
//  ViewController.m
//  HealthAPP
//
//  Created by ios－dai on 15/8/22.
//  Copyright (c) 2015年 ios－dai. All rights reserved.
//

#import "ViewController.h"
#import "BlueToolScale.h"
@interface ViewController ()<BlueToolDelegate,UITableViewDataSource>
{
    NSMutableArray *mArray;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //[BlueTools shareBlueTool];
    [BlueToolScale shareBlueTool].delegate=self;
    mArray=[[NSMutableArray alloc]initWithCapacity:0];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)scan:(id)sender {
    
    //扫描并连接蓝牙，连接成功后会自动接收体重数据
    [[BlueToolScale shareBlueTool]scanBlueAndConnect];
}
- (IBAction)connect:(id)sender {
    //向体制秤发送测量体制的数据，成功发送后会收到体质数据
    [[BlueToolScale shareBlueTool]writeData:@"0101A32001"];
    
}

- (IBAction)disConnect:(id)sender {
     //先向体质秤发送断开指令，再断开蓝牙
    [[BlueToolScale shareBlueTool]writeData:@"0102"];
    [[BlueToolScale shareBlueTool]disConnectBlue];
}

#pragma mark -接收到数据并做成表格
-(void)receiveBlueData:(NSString *)dataString{
    if(![mArray containsObject:dataString]){
        [mArray insertObject:dataString atIndex:0];
        [_tableView reloadData];
        self.textLB.text=dataString;
    }
 
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

{
    return mArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if(cell==nil){
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
  
    cell.textLabel.text=[NSString stringWithFormat:@"%ld--%@",(long)indexPath.row,[mArray objectAtIndex:indexPath.row]];
    return cell;
}
//连接蓝牙成功
-(void)connectBlueSucceed:(NSString*)blueId{

}
//连接蓝牙失败
-(void)connectBlueFaild:(NSInteger)faildTag{

}
//断开连接
-(void)blueDisConnect:(NSString*)blueString{

  
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:blueString message:@"断开连接" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    
    [alert show];
}



@end

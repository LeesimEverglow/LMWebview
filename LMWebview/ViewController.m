//
//  ViewController.m
//  LMWebview
//
//  Created by Leesim on 2018/6/25.
//  Copyright © 2018年 LiMing. All rights reserved.
//

#import "ViewController.h"
#import "LMWebviewController.h"

@interface ViewController ()

@property (nonatomic,strong) UIButton * pushButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.pushButton];
}

-(void)pushAction:(UIButton*)button{
    LMWebviewController * webController = [[LMWebviewController alloc]init];
    //测试链接
    webController.urlString = @"http://www.baidu.com";
    [self.navigationController pushViewController:webController animated:YES];
}

-(UIButton *)pushButton{
    if (!_pushButton) {
        _pushButton = [[UIButton alloc]init];
        _pushButton.frame =CGRectMake(0, 0, 300, 100);
        _pushButton.backgroundColor = [UIColor blackColor];
        _pushButton.center = self.view.center;
        [_pushButton setTitle:@"进入LMWebViewController" forState:UIControlStateNormal];
        _pushButton.titleLabel.font = [UIFont systemFontOfSize:16];

        [_pushButton addTarget:self action:@selector(pushAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pushButton;
}

@end

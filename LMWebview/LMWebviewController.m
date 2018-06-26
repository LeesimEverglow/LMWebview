//
//  LMWebviewController.m
//  LMWebview
//
//  Created by Leesim on 2018/6/25.
//  Copyright © 2018年 LiMing. All rights reserved.
//

#import "LMWebviewController.h"
#import <WebKit/WebKit.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define NAV_HEIGHT (([[UIApplication sharedApplication] statusBarFrame].size.height)+44.0f)

#define LMRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

@interface LMWebviewController ()<WKNavigationDelegate,WKUIDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) WKWebView * webview;
@property (nonatomic,strong) UIBarButtonItem * customBackBarItem;
@property (nonatomic,strong) UIBarButtonItem * closeButtonItem;
@property (nonatomic,strong) UIBarButtonItem* refreshBarItem;
@property (nonatomic,strong) UIView * progressGetView;
@property (nonatomic,strong) UIView * errorShowView;
//为了
@property (nonatomic,assign) id delegate;

//注入方法名 用于接受JS调用原生方法 让Web端掉用iOS端代码
@property (nonatomic,strong) WKWebViewConfiguration *webConfig;

@end

@implementation LMWebviewController

//由于，手动设置了导航栏左按钮，因此我们会发现系统自带的侧滑返回功能失效了，为了网页所在视图控制器的侧滑返回功能可实现，需要再修复其失效的问题。
#pragma mark - 让自定义的导航栏左侧按钮支持侧滑手势的处理
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController.viewControllers.count > 1) {
        //记录原来的代理
        self.delegate = self.navigationController.interactivePopGestureRecognizer.delegate;
        //修复手势操作代理
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //把手势代理在传递给原来的代理对象
    self.navigationController.interactivePopGestureRecognizer.delegate = self.delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [self.view addSubview:self.webview];
    [self.refreshBarItem class];
    [self.view addSubview:self.progressGetView];
    [self.view addSubview:self.errorShowView];
    
    //更新左侧按钮
    [self updateNavigationItems];
    
}

-(void)dealloc{
    //移除观察者在离开界面的时候
    [self.webview removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webview removeObserver:self forKeyPath:@"title"];
    
}

#pragma mark - delegate or observer

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    //判断左侧按钮状态
    [self updateNavigationItems];
}

// 页面加载失败时调用 开始加载后失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    
    self.title = @"加载失败";
    //加载失败时
    [self showLoadErrorView];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self.webview) {
            self.progressGetView.hidden = NO;
            [UIView animateWithDuration:0.1 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressGetView.frame =CGRectMake(0,NAV_HEIGHT,SCREEN_WIDTH*self.webview.estimatedProgress, 3);
            } completion:nil];
            //下面动画是为了防止加载进度在快速请求另外的网页的时候
            //出现进度条回缩的问题
            if(self.webview.estimatedProgress >= 1.0f) {
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{

                } completion:^(BOOL finished) {
                    self.progressGetView.frame =CGRectMake(0,NAV_HEIGHT,0, 3);
                    self.progressGetView.hidden = YES;
                }];
            }
        }
    }else if ([keyPath isEqualToString:@"title"])
    {
        if (object == self.webview) {
            self.title = self.webview.title;
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}


#pragma mark - pravite method

-(void)setUrlString:(NSString *)urlString{
    _urlString = urlString;
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webview loadRequest:request];
}

//更新左侧按钮
-(void)updateNavigationItems{
    if (self.webview.canGoBack) {
        
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem,self.closeButtonItem] animated:NO];
        
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}

-(void)customBackItemClicked{
    //如果可以返回 则返回网页上一级
    if (self.webview.goBack) {
        [self.webview goBack];
    }else{
        [self closeItemClicked];
    }
}

-(void)closeItemClicked{
    //移除js监控 要在pop界面之前 不然会内存泄露
    //[self popControllerDealloc];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)refreshClicked{
    [self.webview reload];
    self.errorShowView.hidden = YES;
}

-(void)errorRefreshClick{
    [self.webview reload];
    self.errorShowView.hidden = YES;
}

//当加载网页失败后 展示加载失败界面
- (void)showLoadErrorView{
    self.errorShowView.hidden = NO;
}


#pragma mark - lazy load
-(UIBarButtonItem *)customBackBarItem{
    if (!_customBackBarItem) {
        //自定义左侧返回按钮
        _customBackBarItem = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"nav_btn_back_black"]
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(customBackItemClicked)];
       
    }
    return _customBackBarItem;
}

-(UIBarButtonItem*)closeButtonItem{
    if (!_closeButtonItem) {
        _closeButtonItem = [[UIBarButtonItem alloc]
                            initWithImage:[UIImage imageNamed:@"icon_close"]
                            style:UIBarButtonItemStylePlain
                            target:self
                            action:@selector(closeItemClicked)];
        
        [_closeButtonItem setImageInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
        
    }
    return _closeButtonItem;
}

-(UIBarButtonItem *)refreshBarItem{
    
    if (!_refreshBarItem) {
        _refreshBarItem = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"icon_fresh"]
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(refreshClicked)];
        self.navigationItem.rightBarButtonItem = _refreshBarItem;
    }
    return _refreshBarItem;
    
}


-(WKWebView *)webview{
    if (!_webview) {
        _webview = [[WKWebView alloc]initWithFrame:CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_HEIGHT)];
        _webview.navigationDelegate = self;
        _webview.UIDelegate = self;
        //侧滑返回上层
        _webview.allowsBackForwardNavigationGestures = YES;

        //观察进度变化
        [_webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionOld context:NULL];
        //观察网页标题
        [_webview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return _webview;
}

-(UIView *)progressGetView
{
    if (!_progressGetView) {
        _progressGetView = [[UIView alloc]init];
        _progressGetView.frame =CGRectMake(0, NAV_HEIGHT,0 , 3);
        _progressGetView.backgroundColor = LMRGBAColor(67, 138, 230, 1);
    }
    return _progressGetView;
}

-(UIView *)errorShowView{
    
    if (!_errorShowView) {
        
        _errorShowView = [[UIView alloc]init];
        _errorShowView.backgroundColor = [UIColor whiteColor];
        _errorShowView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_HEIGHT);
        
        UIButton * refreshButton = [[UIButton alloc]init];
        refreshButton.bounds = CGRectMake(0, 0, 120, 44);
        refreshButton.layer.masksToBounds = YES;
        refreshButton.layer.cornerRadius = 22;
        refreshButton.layer.borderColor = [UIColor blackColor].CGColor;
        refreshButton.layer.borderWidth = 1;
        [refreshButton setTitle:@"刷新" forState:UIControlStateNormal];
        [refreshButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [refreshButton addTarget:self action:@selector(errorRefreshClick) forControlEvents:UIControlEventTouchUpInside];
        [_errorShowView addSubview:refreshButton];
        
        refreshButton.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2-NAV_HEIGHT+22+80);
        
        
        UILabel * showLabel = [[UILabel alloc]init];
        showLabel.numberOfLines = 0;
        showLabel.font = [UIFont systemFontOfSize:16];
        showLabel.textColor = LMRGBAColor(0, 0, 0, 0.48);
        showLabel.text =@"当前网络状态不佳，您可以尝试点击下方按钮刷新重试O~";
        showLabel.bounds = CGRectMake(0, 0, SCREEN_WIDTH-88, 1);
        [showLabel sizeToFit];
        [_errorShowView addSubview:showLabel];
        
        showLabel.frame =CGRectMake(44, CGRectGetMinY(refreshButton.frame)-60-showLabel.bounds.size.height, showLabel.bounds.size.width, showLabel.bounds.size.height);
  
        UILabel * errorLabel = [[UILabel alloc]init];
        errorLabel.font = [UIFont boldSystemFontOfSize:18];
        errorLabel.textColor = LMRGBAColor(0, 0, 0, 0.8);
        errorLabel.text =@"很抱歉，加载失败了";
        errorLabel.textAlignment = NSTextAlignmentCenter;
        [_errorShowView addSubview:errorLabel];
        
        errorLabel.frame =CGRectMake(0, CGRectGetMinY(showLabel.frame)-20-18, SCREEN_WIDTH, 18);
        
        
        _errorShowView.hidden = YES;
        
    }
    return _errorShowView;
}

@end

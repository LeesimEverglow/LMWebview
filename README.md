# LMWebview

[详细介绍地址](https://www.jianshu.com/p/e127b7479ca1)<br /> 

![UIWebview.jpeg](https://upload-images.jianshu.io/upload_images/1197929-4e3b3d2f8449a9ea.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
今年的WWDC之后，有一条关于UIWebview的弃用消息出来了，UIWebview会在iOS12之后弃用，全面普及WKWebview。所以还在使用UIWebview的话需要考虑一下迁移到WKWebview了。下面是把项目WKWebview脱敏之后的一些基础功能的封装。

### 基本效果图
![基本效果图.gif](https://upload-images.jianshu.io/upload_images/1197929-8bf44e5623eb7e9b.gif?imageMogr2/auto-orient/strip)

### 功能<br /> 
1.手势滑动返回上个页面<br /> 
2.导航的返回、关闭、刷新页面<br /> 
3.网页加载进度提示<br /> 
4.网页加载失败提示<br /> 
5.网页标题提示<br /> 

1.更新导航左侧按钮，根据是否webview可以返回来设置左侧按钮的个数
```
-(void)updateNavigationItems{
self.errorShowView.hidden = YES;
if (self.webview.canGoBack) {
[self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem,self.closeButtonItem] animated:NO];
}else{
self.navigationController.interactivePopGestureRecognizer.enabled = YES;
[self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
}
}
```
2.对于WKWebView，使用KVO来监听属性estimatedProgress，即可获取加载进度的变化。监听title，即可以监听网页的标题
```
//观察进度变化
[_webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionOld context:NULL];
//观察网页标题
[_webview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
```
对于KVO一定要在控制器dealloc内进行销毁
```
-(void)dealloc{
//移除观察者在离开界面的时候
[self.webview removeObserver:self forKeyPath:@"estimatedProgress"];
[self.webview removeObserver:self forKeyPath:@"title"];
}
```
3.由于自定义了左侧leftBarButtonItems,所以导致系统的手势侧滑返回上一级功能失效，需要手动修复该方法。然后打开WKWebview的allowsBackForwardNavigationGestures，即可以完成Webview的手势移动到上一层

```
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
//两个手势代理是为了让界面响应侧滑手势
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
return self.navigationController.viewControllers.count > 1;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
return self.navigationController.viewControllers.count > 1;
}

//侧滑返回上层 在webview懒加载内打开该属性
_webview.allowsBackForwardNavigationGestures = YES;
```
4.在网址请求失败显示占位图提示用户。需要在网页请求失败时加以判断。
```
// 页面加载失败时调用 开始加载后失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
self.title = @"加载失败";
//加载失败时
[self showLoadErrorView];

}
```

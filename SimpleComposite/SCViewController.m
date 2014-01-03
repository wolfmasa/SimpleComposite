//
//  SCViewController.m
//  CompositApp2
//
//  Created by ICP223G on 2013/10/02.
//  Copyright (c) 2013年 ICP223G. All rights reserved.
//

#import "SCViewController.h"

@interface SCViewController ()

@end

enum ADJUST_MODE {
    ADJUST_MODE_COMPOSITE = 0,
    ADJUST_MODE_DRAG = 1
};

@implementation SCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.isDrag = false;
    self.progress.progress = 1.0;
    self.adjustMode = ADJUST_MODE_COMPOSITE;
    
    self.imageManager = [SCImageManager new];
    
    [self.modeButton setTitle:[self.imageManager.compositList objectAtIndex:self.imageManager.compositMode] forState:UIControlStateNormal];
    
    [self.resetButton setEnabled:NO];
    [self changeButtonStatus:NO];
    self.scrollView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:panGesture];
    [self.tabBarController setDelegate:self];
    [self updateImageView];
    
}

-(void)changeButtonStatus:(BOOL)isEnable
{
    [self.adjustModeButton setEnabled:isEnable];
    [self.compositSlider setEnabled:isEnable];
    [self.saveButton setEnabled:isEnable];
    [self.modeButton setEnabled:isEnable];
    [self.nextImageButton setEnabled:isEnable];
}

-(void)adjustScrollView:(CGSize)size Scale:(float)scale MinScale:(float)minScale MaxScale:(float)maxScale
{
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.scrollEnabled = YES;
    [self.scrollView setContentSize:size];
    [self.scrollView setDelegate:self];
    [self.scrollView setMinimumZoomScale:minScale];
    [self.scrollView setMaximumZoomScale:maxScale];
    [self.scrollView setZoomScale:scale];
    self.scrollView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    //[self.view addSubview:self.scrollView];
    
}

-(float)calcFitScale:(CGSize)baseSize ContentsSize:(CGSize)contenteSize
{
    float scaleW = baseSize.width / contenteSize.width;
    float scaleH = baseSize.height/ contenteSize.height;
    
    float scale = scaleW;
    if(scaleW > scaleH)
        scale  = scaleH;
    
    NSLog(@"%.2f", scale);
    
    return scale;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    UIView *view = nil;
    if (scrollView == self.scrollView) {
        if(self.adjustMode == ADJUST_MODE_DRAG)
        {
            view = self.baseView;
            [view addSubview:self.layerView];
        }
        else
            view = self.compositImageView;
    }
    return view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateCompositSliderEnableStatus
{
    BOOL ret = [self.imageManager isNeedRatio];
    if(self.adjustMode == ADJUST_MODE_DRAG)
        ret = false;
    
    [self.compositSlider setEnabled:ret];
}


- (IBAction)changeRatio:(id)sender {
    if(self.imageManager.ratio != self.compositSlider.value)
    {
        self.imageManager.needUpdate = YES;
    }
    self.imageManager.ratio = self.compositSlider.value;
    
    [self updateImageView];
}

- (IBAction)resetPoint:(id)sender {
    if(self.adjustMode == ADJUST_MODE_DRAG)
        self.imageManager.needUpdate = YES;
    self.imageManager.startPoint = CGPointZero;
    [self updateImageView];
}

- (IBAction)pushAdjustModeButton:(id)sender {
    
    if(self.adjustMode == ADJUST_MODE_COMPOSITE)
    {
        self.adjustMode = ADJUST_MODE_DRAG;
        [self.adjustModeButton setTitle:@"移動モード" forState:UIControlStateNormal];
        [self.modeButton setEnabled:NO];
        [self.saveButton setEnabled:NO];
        [self.resetButton setEnabled:YES];
        [self.nextImageButton setEnabled:NO];
    }
    else if(self.adjustMode == ADJUST_MODE_DRAG){
        self.adjustMode = ADJUST_MODE_COMPOSITE;
        [self.adjustModeButton setTitle:@"合成モード" forState:UIControlStateNormal];
        [self.modeButton setEnabled:YES];
        [self.saveButton setEnabled:YES];
        [self.resetButton setEnabled:NO];
        [self.nextImageButton setEnabled:YES];
    }
    else{
        return;
    }
    self.imageManager.needUpdate = YES;
    [self updateImageView];
}

#pragma mark UpdateView

-(void)updateImageView
{
    if(self.imageManager.needUpdate != YES) return;
    if([self.timer isValid] == YES) return;
    if(self.imageManager.image1==nil && self.imageManager.image2==nil) return;
    
    if(self.imageManager.image1==nil || self.imageManager.image2==nil)
    {
        [self clearScrollView];
        UIImage *tempImage = self.imageManager.image2==nil? self.imageManager.image1:self.imageManager.image2;
        self.baseView = [[UIImageView alloc]initWithImage:tempImage];
        self.baseView.alpha = 0.8;
        self.scrollView.scrollEnabled = NO;
        
        [self adjustScrollView:tempImage.size Scale:self.baseViewScale MinScale:self.baseViewScale MaxScale:self.baseViewScale];
        
        self.baseView.center = self.scrollView.center;
        [self.scrollView addSubview:self.baseView];
    }
    else
    {
        if(self.adjustMode == ADJUST_MODE_DRAG)
        {
            [self clearScrollView];
            self.layerView = [[UIImageView alloc]initWithImage:self.imageManager.image2];
            self.layerView.alpha = 0.5;
            self.layerView.frame = CGRectMake(self.imageManager.startPoint.x, self.imageManager.startPoint.y, self.layerView.image.size.width, self.layerView.image.size.height);
            self.baseView = [[UIImageView alloc]initWithImage:self.imageManager.image1];
            
            self.scrollView.scrollEnabled = NO;
            
            [self adjustScrollView:self.imageManager.image1.size Scale:self.baseViewScale MinScale:self.baseViewScale MaxScale:self.baseViewScale];
            
            self.baseView.center = self.scrollView.center;
            [self.scrollView addSubview:self.baseView];
            [self.baseView addSubview:self.layerView];
            
        }
        else
        {
            [self setProgressTimer];
            [self.imageManager composit];
        }
    }
    
    [self updateCompositSliderEnableStatus];
}


-(void)updateCompositImageView
{
    if([self.timer isValid]==YES) return ;
    [self clearScrollView];
    self.compositImageView = [[UIImageView alloc] initWithImage:self.imageManager.result];
    
    [self adjustScrollView:self.compositImageView.frame.size Scale:self.baseViewScale MinScale:0.1 MaxScale:5.0];
    self.compositImageView.center = self.scrollView.center;
    [self.scrollView addSubview:self.compositImageView];
}

-(void)clearScrollView
{
    for (UIView* v in [self.scrollView subviews]) {
        [v removeFromSuperview];
    }
}

#pragma mark SavePicture

- (IBAction)saveImage:(id)sender {
    //画像保存完了時のセレクタ指定
    SEL selector = @selector(onCompleteCapture:didFinishSavingWithError:contextInfo:);
    //画像を保存する
    UIImageWriteToSavedPhotosAlbum(self.imageManager.result, self, selector, NULL);
}

//画像保存完了時のセレクタ
- (void)onCompleteCapture:(UIImage *)screenImage
 didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = @"画像を保存しました";
    if (error) message = @"画像の保存に失敗しました";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"" message: message delegate: nil
                                          cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [alert show];
}


#pragma mark Touch Event

//Viewにくるタッチイベント全般を処理。
//ドラッグ中や終了時には描画を決定する。
- (void) handlePanGesture:(UIPanGestureRecognizer*) pan {
    
    if(self.adjustMode == ADJUST_MODE_COMPOSITE) return ;
    
    if(pan.state == UIGestureRecognizerStateBegan)
    {
        self.touchStart = self.imageManager.startPoint;
        self.isDrag = YES;
        if(CGRectContainsPoint(self.scrollView.frame, [pan locationInView:self.view])!=YES)
        {
            self.isDrag = NO;
            return ;
        }
    }
    else if(pan.state == UIGestureRecognizerStateEnded)
    {
        self.isDrag = NO;
        self.imageManager.needUpdate = YES;
    }
    
    
    if((pan.state == UIGestureRecognizerStateChanged
        || pan.state == UIGestureRecognizerStateEnded) &&self.isDrag==YES)
    {
        CGPoint location = [pan translationInView:self.view];
        location.x /= self.scrollView.zoomScale;
        location.y /= self.scrollView.zoomScale;
        self.imageManager.startPoint = CGPointMake(self.touchStart.x + location.x, self.touchStart.y + location.y);
        NSLog(@"startPoint x=%f, y=%f", self.imageManager.startPoint.x, self.imageManager.startPoint.y);
        [self updateImageView];
    }
}

#pragma mark Timer

//タイマーを起動する
//一応、今起動中かどうかを判断している。
-(void)setProgressTimer
{
    if ([self.timer isValid] == NO)
    {
        [self changeButtonStatus:NO];
        [self.openImage1Button setEnabled:NO];
        [self.openImage2Button setEnabled:NO];
        [self.compositSlider setEnabled:NO];
        self.imageManager.progress = 0.0;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(setProgressVal) userInfo:nil repeats:YES];
        [self.timer fire];
    }
    
    return;
}

//タイマーのコールバック関数
//プログレスバーを制御する
-(void)setProgressVal
{
    if([self.timer isValid]==YES && self.imageManager.progress >= 1.0)
    {
        [self.timer invalidate];
        [self updateCompositImageView];
        [self changeButtonStatus:YES];
        [self.openImage1Button setEnabled:YES];
        [self.openImage2Button setEnabled:YES];
        [self updateCompositSliderEnableStatus];
        if(self.imageManager.progress >= 1.0) self.imageManager.progress = 0;
    }
    self.progress.progress = self.imageManager.progress;
}

#pragma mark ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    self.imageManager.compositMode = buttonIndex;
    
    [self.modeButton setTitle:[self.imageManager.compositList objectAtIndex:self.imageManager.compositMode] forState:UIControlStateNormal];
    
    self.imageManager.needUpdate =YES;
    [self updateImageView];
}

- (IBAction)pushModeButton:(id)sender {
    UIActionSheet *sheet =[[UIActionSheet alloc]
                           initWithTitle:@"合成方法"
                           delegate:self
                           cancelButtonTitle:nil
                           destructiveButtonTitle:nil
                           otherButtonTitles:nil];
    
    // ボタンを追加
    for (NSString* buttonTitle in self.imageManager.compositList) {
        [sheet addButtonWithTitle:buttonTitle];
    }
    
    //Action Sheet のスタイルを指定
    [sheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    //表示するビューを指定して Action Sheet を表示
    [sheet showInView:self.view];
}

#pragma mark PickerView

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *image;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // ユーザーの選択した写真を取得し、imageViewというUIImageView型のフィールドのイメージに設定する
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // UIPopoverControllerを閉じる
        [self.imagePopController dismissPopoverAnimated:YES];
    }
    else
    {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //NSLog(@"picker:%.2fx%.2f", image.size.width, image.size.height);
    
    if(self.openMode == 1)
    {
        self.imageManager.image1 = image;
        self.baseViewScale = [self calcFitScale:self.scrollView.frame.size ContentsSize:image.size];
    }
    else if(self.openMode == 2)
    {
        self.imageManager.image2 = image;
        if(self.imageManager.image1 == nil)
            self.baseViewScale = [self calcFitScale:self.scrollView.frame.size ContentsSize:image.size];
    }
    
    if(self.imageManager.image1 !=nil && self.imageManager.image2 !=nil)
        [self changeButtonStatus:YES];
    
    self.imageManager.needUpdate = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self updateImageView];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self updateImageView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)startPicker:(id)sender
{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad
        // PhotoLibraryが取得元として利用出来ない場合は、その後の処理は実行しない。
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) {
            // ここで何かしらの、失敗メッセージを出すとユーザーに優しい。
            return;
        }
        
        // UIImagePickerControllerのインスタンスを作成して、
        // 必要な入手元の設定や、delegateの設定を行う。
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.delegate = self;
        
        // 表示に使うPopoverのインスタンスを作成する。 imagePopControllerは、UIPopoverController型のフィールド変数。
        // PopoverのコンテンツビューにImagePickerを指定する。
        self.imagePopController = [[UIPopoverController alloc] initWithContentViewController:imgPicker];
        
        // Popoverを表示する。
        // senderはBarButtonItem型の変数で、このボタンを起点にPopoverを開く。
        //[self.imagePopController presentPopoverFromBarButtonItem:sender
        //                          permittedArrowDirections:UIPopoverArrowDirectionAny
        //                                           animated:YES];
        UIView *b = (UIView*)sender;
        [self.imagePopController presentPopoverFromRect:b.bounds inView:b permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        // それ以外
        UIImagePickerController *picker = [UIImagePickerController new];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}


- (IBAction)openImage1:(id)sender {
    self.openMode=1;
    [self startPicker:sender];
}

- (IBAction)openImage2:(id)sender {
    self.openMode =2;
    [self startPicker:sender];
}
- (IBAction)nextImage:(id)sender {
    self.imageManager.image1 = self.imageManager.result;
    self.openMode = 2;
    [self startPicker:sender];
}

#pragma mark iAd Delegate
//iAd取得成功
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"iAd取得成功");
    self.adBanner.hidden = NO;
    
    [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
    // Assumes the banner view is just off the bottom of the screen.
    banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
    [UIView commitAnimations];
    
}

//iAd取得失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"iAd取得失敗");
    self.adBanner.hidden = YES;
}

@end

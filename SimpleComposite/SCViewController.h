//
//  SCViewController.h
//  CompositApp2
//
//  Created by ICP223G on 2013/10/02.
//  Copyright (c) 2013年 ICP223G. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "SCImageManager.h"

@interface SCViewController : UIViewController<UITabBarControllerDelegate, UIScrollViewDelegate
, UIActionSheetDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate
, ADBannerViewDelegate>

//ImageViews
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic,retain) UIImageView *compositImageView;
@property (nonatomic) UIImageView *layerView;
@property (nonatomic) UIImageView *baseView;

@property (retain, nonatomic) SCImageManager *imageManager;

//Read Image
- (IBAction)openImage1:(id)sender;
- (IBAction)openImage2:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *openImage1Button;
@property (weak, nonatomic) IBOutlet UIButton *openImage2Button;

@property (weak, nonatomic) IBOutlet UIButton *nextImageButton;
- (IBAction)nextImage:(id)sender;


//View Items
- (IBAction)resetPoint:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
- (IBAction)pushModeButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;


//Mode Controll
@property (weak, nonatomic) IBOutlet UIButton *adjustModeButton;
- (IBAction)pushAdjustModeButton:(id)sender;
@property int adjustMode;

//Ratio Slider
@property (weak, nonatomic) IBOutlet UISlider *compositSlider;
- (IBAction)changeRatio:(id)sender;

//Save
- (IBAction)saveImage:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

//Timer
@property(weak, nonatomic)NSTimer *timer;

//Progress
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

//param
@property(nonatomic)CGPoint touchStart;
@property(nonatomic)BOOL isDrag;
@property int openMode;
@property float baseViewScale;

@property (weak, nonatomic) IBOutlet ADBannerView *adBanner;

//Picker View
@property (nonatomic)UIPopoverController *imagePopController;

-(void)updateImageView;

@end

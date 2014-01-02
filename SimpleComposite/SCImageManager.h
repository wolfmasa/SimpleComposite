//
//  SCImageManager.h
//  CompositApp
//
//  Created by 上原 将司 on 2014/01/02.
//  Copyright (c) 2014年 ProjectSC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCImageManager : NSObject

@property(retain, nonatomic)UIImage *image1;//背景
@property(retain, nonatomic)UIImage *image2;//重ね画像
@property(retain, nonatomic)UIImage *result;//合成結果

@property float ratio;
@property float ratio_copy;
@property CGPoint startPoint;

@property BOOL needUpdate;

@property NSInteger compositMode;
@property(nonatomic)NSMutableArray *compositList;

@property float progress;

-(void)composit;
-(BOOL)isNeedRatio;
@end

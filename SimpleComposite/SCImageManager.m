//
//  SCImageManager.m
//  CompositApp
//
//  Created by 上原 将司 on 2014/01/02.
//  Copyright (c) 2014年 ProjectSC. All rights reserved.
//

#import "SCImageManager.h"

enum ImageComposit {
    IMAGE_COMPOSIT_KASAN
    , IMAGE_COMPOSIT_KAJU_HEIKIN
    , IMAGE_COMPOSIT_GENSAN
    , IMAGE_COMPOSIT_HIKAKU_MEI
    , IMAGE_COMPOSIT_HIKAKU_AN
};

@implementation SCImageManager

- (id)init
{
    self.compositList = [NSMutableArray new];
    [self.compositList addObject:@"加算"];
    [self.compositList addObject:@"加重平均"];
    [self.compositList addObject:@"減算"];
    [self.compositList addObject:@"比較：明"];
    [self.compositList addObject:@"比較：暗"];
    
    self.compositMode = 0;
    self.ratio = 0.5;
    self.progress = 1.0;
    self.startPoint = CGPointMake(0, 0);
    
    self.needUpdate = NO;
    
    return self;
}

-(CFDataRef)getBytes:(UIImage *)image BytesPerLine:(size_t*)bytesPerRow CGBitmapInfo:(CGBitmapInfo*)info
{
    CGImageRef cgImage = [image CGImage];
    *bytesPerRow = CGImageGetBytesPerRow(cgImage);
    *info = CGImageGetBitmapInfo(cgImage);
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    return CGDataProviderCopyData(provider);
}

-(void)composit_KasanGensan:(UInt8*)src1 target:(UInt8*)src2 result:(UInt8*)dst mode:(NSInteger)mode{
    if(src1==nil) return;
    if(src2==nil)
    {
        memcpy(dst, src1, sizeof(UInt8)*4);
        return;
    }
    
    for(int i=0; i<3; i++)
    {
        UInt16 p = src1[i];
        SInt16 result = 0;
        UInt16 q = src2[i];
        switch (mode) {
            case IMAGE_COMPOSIT_KASAN:
                result = p + q;
                break;
            case IMAGE_COMPOSIT_KAJU_HEIKIN:
                result = (SInt16)((float)self.ratio_copy*p + (float)(1.0-self.ratio_copy)*q);
                break;
            case IMAGE_COMPOSIT_GENSAN:
                result = (SInt16)((float)p - (float)q*(1.0 - self.ratio_copy));
            default:
                break;
        }
        
        if(result < 0) result = 0;
        else if(result >255) result=255;
        dst[i] = (UInt8)result;
        
    }
    
    dst[3] = 255;
    //RGBAに変換して返す
}

-(void)composit_HikakuMeiAn:(UInt8*)src1 target:(UInt8*)src2 result:(UInt8*)dst mode:(BOOL)isMei
{
    /*
     Y =   0.257R + 0.504G + 0.098B + 16
     Cb = -0.148R - 0.291G + 0.439B + 128
     Cr =  0.439R - 0.368G - 0.071B + 128
     */
    
    if(src1==nil) return;
    memcpy(dst, src1, sizeof(UInt8)*4);
    
    if (src2==nil) return;
    
    UInt8 y1 = 0.257*src1[0] + 0.504*src1[1] + 0.098*src1[2] + 16;
    UInt8 y2 = 0.257*src2[0] + 0.504*src2[1] + 0.098*src2[2] + 16;
    
    if((y1 < y2 && (isMei==YES)) || (y1 > y2&& (isMei==NO)))
    {
        memcpy(dst, src2, sizeof(UInt8)*4);
    }
    
    //RGBAに変換して返す
    return;
}

-(void)getOffset:(CGBitmapInfo)bitmapInfo offset:(int*)offset
{
    int bitOffsetRed = 0;
    int bitOffsetGreen = 0;
    int bitOffsetBlue = 0;
    int bitOffsetAlpha = 0;
    
    if(bitmapInfo == kCGImageAlphaPremultipliedLast ||
       bitmapInfo == kCGImageAlphaLast
       ){
        bitOffsetRed = 0;
        bitOffsetGreen = 1;
        bitOffsetBlue = 2;
        bitOffsetAlpha = 3;
        //NSLog(@"RGBA");
    } else if (bitmapInfo == kCGImageAlphaPremultipliedFirst ||
               bitmapInfo == kCGImageAlphaFirst){
        bitOffsetRed = 1;
        bitOffsetGreen = 2;
        bitOffsetBlue = 3;
        bitOffsetAlpha = 0;
        //NSLog(@"ARGB");
    } else if (bitmapInfo == kCGImageAlphaNone ||
               bitmapInfo == kCGImageAlphaNoneSkipLast){
        bitOffsetRed = 0;
        bitOffsetGreen = 1;
        bitOffsetBlue = 2;
        bitOffsetAlpha = -1;
        //NSLog(@"RGB_");
    } else if (bitmapInfo == kCGImageAlphaNoneSkipFirst){
        bitOffsetRed = 1;
        bitOffsetGreen = 2;
        bitOffsetBlue = 3;
        bitOffsetAlpha = -1;
        //NSLog(@"_RGB");
    } else if (bitmapInfo == kCGImageAlphaOnly){
        bitOffsetRed = -1;
        bitOffsetGreen = -1;
        bitOffsetBlue = -1;
        bitOffsetAlpha = 0;
        //NSLog(@"A___");
    } else if (bitmapInfo == 8194){
        //iOS3.1.3や3.2とか
        bitOffsetRed = 0;
        bitOffsetGreen = 1;
        bitOffsetBlue = 2;
        bitOffsetAlpha = 3;
        //NSLog(@"RGBA");
    } else {
        bitOffsetRed = 0;
        bitOffsetGreen = 1;
        bitOffsetBlue = 2;
        bitOffsetAlpha = 3;
        //NSLog(@"RGBA");
    }
    
    offset[0] = bitOffsetRed;
    offset[1] = bitOffsetGreen;
    offset[2] = bitOffsetBlue;
    offset[3] = bitOffsetAlpha;
}

-(void)compositPixel:(UInt8*)src1 target:(UInt8*)src2 result:(UInt8*)dst offset1:(int*)offset1 offset2:(int*)offset2
{
    //RGBAに変換
    UInt8 _src1[4] = { src1[offset1[0]], src1[offset1[1]], src1[offset1[2]], (offset1[3]>0 ? src1[offset1[3]]:255)};
    UInt8 *pSrc2 = nil;
    UInt8 _src2[4] = {0};
    if(src2!=nil)
    {
        _src2[0] = src2[offset2[0]];
        _src2[1] = src2[offset2[1]];
        _src2[2] = src2[offset2[2]];
        _src2[3] = offset2[3]>0 ? src2[offset2[3]]:255;
        pSrc2 = _src2;
    }
    
    switch (self.compositMode) {
        case IMAGE_COMPOSIT_KASAN:
        case IMAGE_COMPOSIT_GENSAN:
        case IMAGE_COMPOSIT_KAJU_HEIKIN:
            [self composit_KasanGensan:_src1 target:pSrc2 result:dst mode:self.compositMode];
            break;
        case IMAGE_COMPOSIT_HIKAKU_MEI:
            [self composit_HikakuMeiAn:_src1 target:pSrc2 result:dst mode:YES];
            break;
        case IMAGE_COMPOSIT_HIKAKU_AN:
            [self composit_HikakuMeiAn:_src1 target:pSrc2 result:dst mode:NO];
            break;
        default:
            break;
    }
}

-(void)createResultImage:(UInt8*)buff size:(size_t)buffSize W:(size_t)width H:(size_t)height
{
    CFDataRef resultData = CFDataCreate(NULL, buff, buffSize);
    CGDataProviderRef resultDataProvider = CGDataProviderCreateWithCFData(resultData);
    CGImageRef resultCgImage = CGImageCreate(width, height,8,32,width*4*sizeof(UInt8),
                                             CGColorSpaceCreateDeviceRGB(),kCGBitmapByteOrderDefault,resultDataProvider, NULL, YES, kCGRenderingIntentDefault);
    
    self.result = [[UIImage alloc] initWithCGImage:resultCgImage];
    
    CGImageRelease(resultCgImage);
    CFRelease(resultDataProvider);
    CFRelease(resultData);
}

-(void)compositByAnotherThread
{
    //@autoreleasepool
    {
        
        self.result = nil;
        self.ratio_copy = self.ratio;
        
        //背景画像の抽出
        UIImage *img = self.image1;
        size_t bytesPerRow1 = 0;
        CGBitmapInfo info1;
        CFDataRef data1 = [self getBytes:self.image1 BytesPerLine:&bytesPerRow1 CGBitmapInfo:&info1];
        UInt8 *pixels1 = (UInt8*)CFDataGetBytePtr(data1);
        int offset1[4];
        [self getOffset:info1 offset:offset1];
        
        //重ね画像の抽出
        size_t bytesPerRow2 = 0;
        CGBitmapInfo info2;
        CFDataRef data2 = [self getBytes:self.image2 BytesPerLine:&bytesPerRow2 CGBitmapInfo:&info2];
        UInt8 *pixels2 = (UInt8*)CFDataGetBytePtr(data2);
        int offset2[4];
        [self getOffset:info2 offset:offset2];
        
        //結果のバッファ
        long buffSize =sizeof(UInt8)*img.size.width*img.size.height*4;
        UInt8 *buff = (UInt8 *)malloc(buffSize);
        
        //NSLog(@"Image1 %.2fx%.2f", self.image1.size.width, self.image1.size.height);
        //NSLog(@"Image2 %.2fx%.2f", self.image2.size.width, self.image2.size.height);
        
        // 画像処理
        int startPointX = floorf(self.startPoint.x);
        int startPointY = floorf(self.startPoint.y);
        self.progress = 0;
        UInt8* dst = buff;
        
        for (int y = 0 ; y < img.size.height; y++){
            for (int x = 0; x < img.size.width; x++){
                UInt8* src1 = pixels1 + y * bytesPerRow1 + x * 4;
                UInt8* src2 = nil;
                int pointX = x-startPointX;
                int pointY = y-startPointY;
                if(pointX >= 0 && pointY>=0 && (pointX <self.image2.size.width) && (pointY < self.image2.size.height))
                    src2 = pixels2 + (pointY) * bytesPerRow2 + (pointX) * 4;
                
                [self compositPixel:src1 target:src2 result:dst offset1:offset1 offset2:offset2];
                dst += 4;
            }
            self.progress = (float)y/img.size.height;
        }
        
        self.progress = 1;
        
        // pixel値からUIImageの再合成
        [self createResultImage:buff size:buffSize W:img.size.width H:img.size.height];
        
        self.needUpdate = NO;
        CFRelease(data1);
        CFRelease(data2);
        
        // 後処理
        
        free(buff);
    }
}



-(void)composit
{
#if 1
    [self performSelectorInBackground:@selector(compositByAnotherThread) withObject:self];
#else
    [self compositByAnotherThread];
#endif
}

-(BOOL)isNeedRatio
{
    BOOL ret = NO;
    switch (self.compositMode) {
        case IMAGE_COMPOSIT_GENSAN:
        case IMAGE_COMPOSIT_KAJU_HEIKIN:
            ret = YES;
            break;
        default:
            break;
    }
    return ret;
}

@end

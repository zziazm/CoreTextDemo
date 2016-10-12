//
//  CTDisplayView.m
//  CoreTextDemo
//
//  Created by 赵铭 on 16/8/12.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "CTDisplayView.h"
#import <CoreText/CoreText.h>
@implementation CTDisplayView

void RunDelegateDeallocCallback( void* refCon ){
    
}

CGFloat RunDelegateGetAscentCallback( void *refCon ){
    NSString *imageName = (__bridge NSString *)refCon;
    CGFloat height = [UIImage imageNamed:imageName].size.height;
    return height;
}

CGFloat RunDelegateGetDescentCallback(void *refCon){
    return 0;
}

CGFloat RunDelegateGetWidthCallback(void *refCon){
    NSString *imageName = (__bridge NSString *)refCon;
    CGFloat width = [UIImage imageNamed:imageName].size.width;
    return width;
}



- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    //得到当前绘制画布的上下文，用于将后续内容绘制在画布上
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //将坐标系上下翻转。对于底层的绘制引擎来说，屏幕的左下角是坐标原点（0，0），而对于上层的UIKit来说，屏幕的左上角是坐标原点，为了之后的坐标系按UIKit来做，在这里做了坐标系的上下翻转，这样底层和上层的（0，0）坐标就是重合的了
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0,-1.0);
   
    //创建绘制的区域,这里将UIView的bounds作为绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:@"海洋生物学家在太平洋里发现了一条与众不同的鲸。一般蓝鲸的“歌唱”频率在十五到二十五赫兹，长须鲸子啊二十赫兹左右，而它的频率在五十二赫兹左右。"];
    //设置字体
    [attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:24] range:NSMakeRange(0, 5)];
    [attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(6, 2)];
    [attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:38] range:NSMakeRange(8, attString.length - 8)];
    
    
    //设置文字颜色
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 11)];
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(11, attString.length - 11)];

    
    NSString * imageName = @"jingyu";
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = RunDelegateDeallocCallback;
    callbacks.getAscent = RunDelegateGetAscentCallback;
    callbacks.getDescent = RunDelegateGetDescentCallback;
    callbacks.getWidth = RunDelegateGetWidthCallback;
    
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)(imageName));
    //空格用于给图片留位置
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
     CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imageAttributedString, CFRangeMake(0, 1), kCTRunDelegateAttributeName, runDelegate);
    CFRelease(runDelegate);
    [imageAttributedString addAttribute:@"imageName" value:imageName range:NSMakeRange(0, 1)];
    [attString insertAttributedString:imageAttributedString atIndex:1];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attString.length), path, NULL);
    //把frame绘制到context里
    CTFrameDraw(frame, context);

    NSArray * lines = (NSArray *)CTFrameGetLines(frame);
    NSInteger lineCount = lines.count;
    CGPoint lineOrigins[lineCount];
    //拷贝frame的line的原点到数组lineOrigins里，如果第二个参数里的length是0，将会从开始的下标拷贝到最后一个line的原点
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < lineCount; i++) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        NSArray * runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < runs.count; j++) {
            CTRunRef run =  (__bridge CTRunRef)runs[j];
            NSDictionary * dic = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[dic objectForKey:(NSString *)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            NSString * imageName = [dic objectForKey:@"imageName"];
            UIImage * image = [UIImage imageNamed:imageName];
            CGRect runBounds;
            CGFloat ascent;
            CGFloat descent;
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            CFIndex index = CTRunGetStringRange(run).location;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, index, NULL);
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y;
            runBounds.size =image.size;
            CGContextDrawImage(context, runBounds, image.CGImage);
        }
    }
    //底层的Core Foundation对象由于不在ARC的管理下，需要自己维护这些对象的引用计数，最后要释放掉。
    CFRelease(frame);
    CFRelease(path);
    CFRelease(context);
}


@end

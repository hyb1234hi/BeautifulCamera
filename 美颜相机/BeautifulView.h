//
//  BeautifulView.h
//  美颜相机
//
//  Created by ireliad on 2018/4/1.
//  Copyright © 2018年 正辰科技. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BeautifulView, GPUImageOutput;
@protocol GPUImageInput;
@protocol BeautifulViewDelegate<NSObject>
-(void)beautifulViewSelectedBtn:(BeautifulView*)view filter:(GPUImageOutput<GPUImageInput>*)filter;
-(void)beautifulViewCancelBtn:(BeautifulView*)view filter:(GPUImageOutput<GPUImageInput>*)filter;
@end

@interface BeautifulView : UIView
@property(nonatomic,weak)id<BeautifulViewDelegate> delegate;
@end

//
//  BeautifulView.m
//  美颜相机
//
//  Created by ireliad on 2018/4/1.
//  Copyright © 2018年 正辰科技. All rights reserved.
//

#import "BeautifulView.h"
#import <GPUImage/GPUImage.h>
#import <Masonry/Masonry.h>
#import "GPUImageBeautifyFilter.h"

@interface BeautifulView()

@property(nonatomic,strong)UIScrollView *scrollView;
@property(nonatomic,strong)NSDictionary<NSString*, GPUImageOutput<GPUImageInput>*> *data;
@property(nonatomic,strong)NSMutableArray<UIButton*> *btns;

@end

@implementation BeautifulView

#pragma mark - 📓public method

#pragma mark - 📒life cycle
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
        [self scrollView];
        [self initUI];
    }
    return self;
}

#pragma mark - 📕delegate

#pragma mark - 📗event response
-(void)btnClick:(UIButton*)btn
{
    NSString *key = [btn titleForState:UIControlStateNormal];
    GPUImageOutput<GPUImageInput> *filter = self.data[key];
    if (btn.selected) {
        if ([self.delegate respondsToSelector:@selector(beautifulViewCancelBtn:filter:)]) {
            [self.delegate beautifulViewCancelBtn:self filter:filter];
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(beautifulViewSelectedBtn:filter:)]) {
            [self.delegate beautifulViewSelectedBtn:self filter:filter];
        }
    }
    
    btn.selected = !btn.selected;
    [self.btns enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != btn) {
            obj.selected = NO;
        }
    }];
    
    
}

#pragma mark - 📘private method
-(void)initUI
{
    NSArray<NSString*> *keys = self.data.allKeys;
    
    for (int i=0; i<keys.count; i++) {
        NSString *key = keys[i];
        UIButton *btn = [UIButton new];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn setTitle:key forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [self.scrollView addSubview:btn];
        [self.btns addObject:btn];
        
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.btns mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.scrollView);
        make.height.equalTo(self.scrollView);
    }];
    [self.btns mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:20 leadSpacing:30 tailSpacing:30];
}

#pragma mark - 📙getter and setter
-(UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scrollView];
        [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.height.mas_equalTo(80);
            make.bottom.equalTo(self).offset(-100);
        }];
    }
    return _scrollView;
}

-(NSDictionary<NSString *,GPUImageOutput<GPUImageInput> *> *)data
{
    if (!_data) {
        _data = @{
                  @"素描": [GPUImageSketchFilter new],
                  @"卡通效果": [GPUImageToonFilter new],
                  @"水晶球效果": [GPUImageGlassSphereFilter new],
                  @"浮雕效果": [GPUImageEmbossFilter new],
                  @"磨皮": [GPUImageBeautifyFilter new],
                  };
    }
    return _data;
}

-(NSMutableArray<UIButton *> *)btns
{
    if (!_btns) {
        _btns = [[NSMutableArray alloc] init];
    }
    return _btns;
}
@end

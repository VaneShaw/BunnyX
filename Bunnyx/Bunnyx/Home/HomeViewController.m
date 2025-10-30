//
//  HomeViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HomeViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "MaterialTypeModel.h"
#import "MaterialListViewController.h"
#import "BunnyxMacros.h"

@interface HomeViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIScrollView *pagesScrollView;
@property (nonatomic, strong) NSArray<MaterialTypeModel *> *types;
@property (nonatomic, strong) NSMutableArray<MaterialListViewController *> *pages;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation HomeViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // 背景图
    [self setupBackgroundImage];
    self.pages = [NSMutableArray array];
    [self setupTopBar];
    [self setupPagesScrollView];
    [self setupEmptyLabel];
    [self fetchCategories];
}

- (void)setupBackgroundImage {
    if (!self.backgroundImageView) {
        self.backgroundImageView = [[UIImageView alloc] init];
        self.backgroundImageView.image = [UIImage imageNamed:@"bg_login_account"];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.backgroundImageView.clipsToBounds = YES;
        [self.view addSubview:self.backgroundImageView];
        [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
}


// 顶部分段
- (void)setupTopBar {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[]];
    seg.selectedSegmentIndex = 0;
    seg.backgroundColor = [UIColor clearColor];
    [seg addTarget:self action:@selector(onSegmentChanged:) forControlEvents:UIControlEventValueChanged];

    // 背景透明与分隔线透明
    UIImage *clearImg = [self bx_imageWithColor:[UIColor clearColor]];
    [seg setBackgroundImage:clearImg forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [seg setBackgroundImage:clearImg forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [seg setDividerImage:clearImg forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    // 文本颜色与选中样式
    if (@available(iOS 13.0, *)) {
        seg.selectedSegmentTintColor = HEX_COLOR(0x999999); // 选中背景 #999999
        NSDictionary *normalAttrs = @{ NSForegroundColorAttributeName: BUNNYX_LIGHT_TEXT_COLOR, NSFontAttributeName: FONT(17) };
        NSDictionary *selectedAttrs = @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: BOLD_FONT(20) };
        [seg setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [seg setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    } else {
        seg.tintColor = HEX_COLOR(0x999999); // 老系统用tint
        NSDictionary *normalAttrs = @{ NSForegroundColorAttributeName: BUNNYX_LIGHT_TEXT_COLOR, NSFontAttributeName: FONT(17) };
        NSDictionary *selectedAttrs = @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: BOLD_FONT(20) };
        [seg setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [seg setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    }

    self.segmentedControl = seg;
    [self.view addSubview:seg];
    [seg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.mas_equalTo(32);
    }];
}

// 生成纯色图片用于Segment控制透明背景/分隔线
- (UIImage *)bx_imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 横向分页容器
- (void)setupPagesScrollView {
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scroll.pagingEnabled = YES;
    scroll.showsHorizontalScrollIndicator = NO;
    scroll.delegate = self;
    scroll.backgroundColor = [UIColor clearColor];
    self.pagesScrollView = scroll;
    [self.view addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.view);
    }];
}

#pragma mark - Empty View

- (void)setupEmptyLabel {
    UILabel *label = [[UILabel alloc] init];
    label.text = LocalString(@"暂无数据");
    label.textColor = BUNNYX_LIGHT_TEXT_COLOR;
    label.font = FONT(14);
    label.textAlignment = NSTextAlignmentCenter;
    label.hidden = YES;
    self.emptyLabel = label;
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
}

#pragma mark - Networking

- (void)fetchCategories {
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_TYPE_LIST parameters:nil success:^(id  _Nonnull responseObject) {
        NSArray *data = responseObject[@"data"];
        self.types = [MaterialTypeModel modelsFromResponse:data];
        [self reloadSegmentsAndPages];
    } failure:^(NSError * _Nonnull error) {
        self.types = @[];
        [self reloadSegmentsAndPages];
    }];
}

- (void)reloadSegmentsAndPages {
    [self.segmentedControl removeAllSegments];
    [self.pages makeObjectsPerformSelector:@selector(removeFromParentViewController)];
    [self.pages removeAllObjects];
    NSInteger idx = 0;
    for (MaterialTypeModel *t in self.types) {
        [self.segmentedControl insertSegmentWithTitle:[t displayName] atIndex:idx animated:NO];
        MaterialListViewController *vc = [[MaterialListViewController alloc] initWithMaterialType:t.typeId];
        [self addChildViewController:vc];
        [self.pages addObject:vc];
        idx++;
    }
    if (self.types.count > 0) {
        self.segmentedControl.selectedSegmentIndex = 0;
    }
    self.emptyLabel.hidden = (self.types.count > 0);
    [self layoutPages];
}

- (void)layoutPages {
    CGFloat width = self.pagesScrollView.bounds.size.width;
    CGFloat height = self.pagesScrollView.bounds.size.height;
    if (width <= 0 || height <= 0) { [self.view layoutIfNeeded]; width = self.pagesScrollView.bounds.size.width; height = self.pagesScrollView.bounds.size.height; }
    self.pagesScrollView.contentSize = CGSizeMake(width * self.pages.count, height);
    [self.pages enumerateObjectsUsingBlock:^(MaterialListViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *v = obj.view;
        v.frame = CGRectMake(width * idx, 0, width, height);
        if (!v.superview) {
            [self.pagesScrollView addSubview:v];
        }
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPages];
}

#pragma mark - Actions

- (void)onSegmentChanged:(UISegmentedControl *)seg {
    CGFloat width = self.pagesScrollView.bounds.size.width;
    CGPoint offset = CGPointMake(width * seg.selectedSegmentIndex, 0);
    [self.pagesScrollView setContentOffset:offset animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.pagesScrollView) { return; }
    CGFloat width = MAX(scrollView.bounds.size.width, 1);
    NSInteger page = lround(scrollView.contentOffset.x / width);
    if (page >= 0 && page < self.segmentedControl.numberOfSegments && self.segmentedControl.selectedSegmentIndex != page) {
        self.segmentedControl.selectedSegmentIndex = page;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.pagesScrollView) { return; }
    CGFloat width = MAX(scrollView.bounds.size.width, 1);
    NSInteger page = lround(scrollView.contentOffset.x / width);
    if (page >= 0 && page < self.segmentedControl.numberOfSegments) {
        self.segmentedControl.selectedSegmentIndex = page;
    }
}

@end

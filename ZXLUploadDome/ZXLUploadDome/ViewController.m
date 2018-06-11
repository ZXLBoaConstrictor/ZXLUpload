//
//  ViewController.m
//  ZXLUploadDome
//
//  Created by 张小龙 on 2018/5/4.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ViewController.h"
#import "UploadViewController.h"
#import "CompressViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UITableView * tableView;
@property(nonatomic,strong)NSArray *domes;
@end

@implementation ViewController

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        _tableView.dataSource = self;
        _tableView.scrollsToTop = YES;
        _tableView.delegate = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    
    self.domes = @[@"上传测试",@"压缩测试"];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.domes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [self.domes objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
        case 0:
        {
            UploadViewController * pVC = [[UploadViewController alloc] init];
            [self.navigationController pushViewController:pVC animated:YES];
        }
            break;
        case 1:
        {
            CompressViewController * pVC = [[CompressViewController alloc] init];
            [self.navigationController pushViewController:pVC animated:YES];
            
        }
            break;
        default:
            break;
    }
    
    
}

@end

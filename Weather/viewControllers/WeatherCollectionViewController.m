/*
 * <b>Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
 *  and/or licensors. </b>
 *
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification, are permitted
 *  provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *      and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *      conditions and the following disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 *  3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *      endorse or promote products derived from this software without specific prior written
 *      permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 *  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 *  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "WeatherCollectionViewController.h"
#import <CreatorKit/CreatorKit.h>
#import "AppData.h"
#import "AppDataProtocol.h"
#import "AppDelegate.h"
#import "DataApi.h"
#import "SensorsDataSource.h"
#import "WeatherEditGroupsTableViewController.h"



@interface TimerTarget : NSObject
@property(weak, nonatomic) id realTarget;
@end

@implementation TimerTarget
- (void)pollingTimerFired:(NSTimer*)timer {
    [self.realTarget performSelector:@selector(pollingTimerFired:) withObject:timer];
}
@end


@interface WeatherCollectionViewController ()
@property(nonatomic, strong, nonnull) SensorsDataSource *dataSource;
@property(nonatomic, strong, nullable) DataApi *dataApi;
@property(strong, nonatomic, nonnull) AppData *appData;
@property (nonatomic, strong, nonnull) NSOperationQueue *pollingQueue;
@property (nonatomic, weak, nullable) NSTimer *pollingTimer;
@property(nonatomic, strong, nonnull) UIRefreshControl *refreshControl;
@property(atomic, assign) BOOL freezeRefreshing;
@property(nonatomic, strong, nonnull) UILongPressGestureRecognizer *longPressGesture;
@end

@implementation WeatherCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongGesture:)];
    self.longPressGesture.minimumPressDuration = 1.0;
    [self.collectionView addGestureRecognizer:self.longPressGesture];
    
    self.installsStandardGestureForInteractiveMovement = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDataChangeNotificationHandler:) name:AppDataChangeNotification object:self.appData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDataReloadNotificationHandler:) name:AppDataReloadNotification object:self.appData];
    
    self.collectionView.dataSource = self.dataSource;
    self.collectionView.delegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionViewLayout;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    layout.headerReferenceSize = CGSizeMake(0.0, 30.0);
    layout.sectionHeadersPinToVisibleBounds = YES;

    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refershControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    
    [self requestSensors];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
    [self startPollingTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self killPollingTimer];
}

- (void)dealloc {
    [self killPollingTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editGroupsSegue"]) {
        UINavigationController *navVc = (UINavigationController *)segue.destinationViewController;
        id<AppDataProtocol> appDataReceiver = (id<AppDataProtocol>)navVc.topViewController;
        [appDataReceiver setAppData:self.appData];
    }
}

#pragma mark - IBAction

- (IBAction)refershControlAction:(id)sender {
    [self requestSensors];
}

- (IBAction)logoutAction:(UIBarButtonItem *)sender {
    [[LoginApi class] logout];
    [self presentLoginViewController];
}

#pragma mark - Private

- (AppData *)appData {
    if (_appData == nil) {
        _appData = [AppData new];
    }
    return _appData;
}

- (SensorsDataSource *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [[SensorsDataSource alloc] initWithAppData:self.appData];
        _dataSource.collectionView = self.collectionView;
    }
    return _dataSource;
}

- (void)requestSensors {
    [self.dataApi requestSensorsWithSuccess:^(NSArray<Sensor *> * _Nonnull sensors) {
        [self.appData setNewSensors:sensors];
        [self.refreshControl endRefreshing];
    } failure:^(NSError * _Nullable error) {
        [self.refreshControl endRefreshing];
    }];
}

- (NSOperationQueue *)pollingQueue {
    if (_pollingQueue == nil) {
        _pollingQueue = [NSOperationQueue new];
        _pollingQueue.maxConcurrentOperationCount = 1;
        _pollingQueue.name = @"Sensors polling queue";
    }
    return _pollingQueue;
}

- (void)pollingTimerFired:(NSTimer *)timer {
    [self requestSensors];
}

- (void)startPollingTimer {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.pollingTimer == nil) {
            TimerTarget *timerTarget = [TimerTarget new];
            timerTarget.realTarget = self;
            self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:timerTarget selector:@selector(pollingTimerFired:) userInfo:nil repeats:YES];
        }
    }];
}

- (void)killPollingTimer {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
    }];
}

- (void)presentLoginViewController {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = [[LoginApi class] loginViewControllerWithLoginDelegate:appDelegate];
}

- (void)handleLongGesture:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.freezeRefreshing = YES;
            self.appData.stopRefreshing = YES;
            [self killPollingTimer];
            
            NSIndexPath *selectedIndexPath = [self.collectionView indexPathForItemAtPoint:[gesture locationInView:self.collectionView]];
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:selectedIndexPath];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
            [self.collectionView updateInteractiveMovementTargetPosition:[gesture locationInView:gesture.view]];
            break;
            
        case UIGestureRecognizerStateEnded:
            self.freezeRefreshing = NO;
            self.appData.stopRefreshing = NO;
            [self startPollingTimer];
            [self.collectionView endInteractiveMovement];
            break;
            
        default:
            break;
    }
}

#pragma mark - Private (notification handlers)

- (void)appDataChangeNotificationHandler:(NSNotification *)notification {
    NSArray<NSIndexPath *> *updated = notification.userInfo[AppDataUpdatedObjectsKey];
    NSArray<NSIndexPath *> *deleted = notification.userInfo[AppDataDeletedObjectsKey];
    NSArray<NSIndexPath *> *inserted = notification.userInfo[AppDataInsertedObjectsKey];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadItemsAtIndexPaths:updated];
        [self.collectionView deleteItemsAtIndexPaths:deleted];
        [self.collectionView insertItemsAtIndexPaths:inserted];
    } completion:nil];
}

- (void)appDataReloadNotificationHandler:(NSNotification *)notification {
    if (NO == self.freezeRefreshing) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.collectionView reloadData];
        }];
    }
}

@end

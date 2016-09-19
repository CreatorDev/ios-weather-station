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

#import "LoginViewController.h"
#import "LoginApi.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *keepMeSignedInSwitch;
@property (weak, nonatomic) IBOutlet UILabel *keepMeSignedInLabel;
@property (weak, nonatomic) IBOutlet UIButton *learnMoreButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong, nonnull) LoginApi *loginApi;
@property (nonatomic, readonly) NSURL *learnMoreUrl;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    id<LoginDelegate> loginDelegate = (id<LoginDelegate>)[UIApplication sharedApplication].delegate;
    if (loginDelegate.authenticateToken) {
        [self loginWithAuthenticateToken:loginDelegate.authenticateToken];
    } else {
        [self silentLogin];
    }
    self.versionLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - IBAction

- (IBAction)loginAction {
    [self showLoginActivityIndicator:YES];
    
    __weak typeof(self) weakSelf = self;
    id<LoginDelegate> loginDelegate = (id<LoginDelegate>)[UIApplication sharedApplication].delegate;
    
    [self.loginApi loginWithKeepMeSignedIn:self.keepMeSignedInSwitch.on loginDelegate:loginDelegate success:^(DeviceServerApi * _Nonnull deviceServerApi) {
        [weakSelf.loginDelegate presentMainViewControllerWithDeviceServerApi:deviceServerApi];
        [weakSelf showLoginActivityIndicator:NO];
    } failure:^(NSError * _Nullable error) {
        NSLog(@"ERROR login: %@", error);
        [weakSelf showLoginActivityIndicator:NO];
    }];
}

- (IBAction)linkAction {
    if (self.learnMoreUrl) {
        [[UIApplication sharedApplication] openURL:self.learnMoreUrl];
    }
}

#pragma mark - Private

- (void)loginWithAuthenticateToken:(NSString *)authenticateToken {
    id<LoginDelegate> loginDelegate = (id<LoginDelegate>)[UIApplication sharedApplication].delegate;
    __weak typeof(self) weakSelf = self;
    
    [self showLoginActivityIndicator:YES];
    [self.loginApi continueLoginWithToken:loginDelegate.authenticateToken success:^(DeviceServerApi * _Nonnull deviceServerApi) {
        [weakSelf.loginDelegate presentMainViewControllerWithDeviceServerApi:deviceServerApi];
        [weakSelf showLoginActivityIndicator:NO];
    } failure:^(NSError * _Nullable error) {
        NSLog(@"ERROR login with open URL on app launch: %@", error);
        [weakSelf showLoginActivityIndicator:NO];
    }];
}

- (void)silentLogin {
    if ([self.loginApi isSilentLoginStartPossible]) {
        [self showSilentLoginActivityIndicator:YES];
        
        __weak typeof(self) weakSelf = self;
        [self.loginApi silentLoginWithSuccess:^(DeviceServerApi * _Nonnull deviceServerApi) {
            [weakSelf.loginDelegate presentMainViewControllerWithDeviceServerApi:deviceServerApi];
        } failure:^(NSError * _Nullable error) {
            NSLog(@"ERROR silent login: %@", error);
            [weakSelf showSilentLoginActivityIndicator:NO];
        }];
    }
}

- (void)showSilentLoginActivityIndicator:(BOOL)on {
    self.loginButton.hidden = on;
    self.keepMeSignedInSwitch.hidden = on;
    self.keepMeSignedInLabel.hidden = on;
    self.learnMoreButton.hidden = on;
    self.activityIndicator.hidden = !on;
}

- (void)showLoginActivityIndicator:(BOOL)on {
    self.loginButton.enabled = !on;
}

#pragma mark - Private (setters/getters)

- (LoginApi *)loginApi {
    if (_loginApi == nil) {
        _loginApi = [LoginApi new];
    }
    return _loginApi;
}

- (NSURL *)learnMoreUrl {
    return [NSURL URLWithString:@"http://creatordev.io"];
}

@end

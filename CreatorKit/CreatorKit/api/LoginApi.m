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

#import "LoginApi.h"
#import "AuthenticateApi.h"
#import "DataStore.h"
#import "DeviceServerApi_PRIV.h"
#import "LoginDelegate.h"
#import "LoginViewController.h"
#import "SecureDataStore.h"


@interface LoginApi ()
@property(nonatomic, strong, nonnull) AuthenticateApi *authenticateApi;
@property(nonatomic, strong, nonnull) NSOperationQueue *networkQueue;
@property(nonatomic, strong, nonnull) NSNumber *keepMeSignedIn;
@end


@implementation LoginApi

- (AuthenticateApi *)authenticateApi {
    if (_authenticateApi == nil) {
        _authenticateApi = [AuthenticateApi new];
    }
    return _authenticateApi;
}

- (NSOperationQueue *)networkQueue {
    if (_networkQueue == nil) {
        _networkQueue = [NSOperationQueue new];
        _networkQueue.name = @"LoginApi network queue";
        _networkQueue.maxConcurrentOperationCount = 3;
    }
    return _networkQueue;
}

- (BOOL)processOpenUrl:(nonnull NSURL *)url source:(nonnull id<LoginDelegate>)loginDelegate {
    return [self.authenticateApi processOpenUrl:url source:loginDelegate];
}

- (void)loginWithKeepMeSignedIn:(BOOL)keepMeSignedIn
                         loginDelegate:(nonnull id<LoginDelegate>)loginDelegate
                        success:(nullable LoginSuccessBlock)success
                        failure:(nullable CreatorFailureBlock)failure
{
    self.keepMeSignedIn = @(keepMeSignedIn);
    [[DataStore class] storeKeepMeSignedIn:keepMeSignedIn];
    LoginSuccessBlock extSuccessBlock = ^(DeviceServerApi * _Nonnull deviceServerApi) {
        if (success) {
            success(deviceServerApi);
        }
    };
    CreatorFailureBlock extFailureBlock = ^(NSError * _Nullable error) {
        [[DataStore class] cleanKeepMeSignedIn];
        if (failure) {
            failure(error);
        }
    };
    
    __weak typeof(self) weakSelf = self;
    [self.networkQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [weakSelf.authenticateApi loginWithDelegate:loginDelegate completionHandler:^(AccessKey * _Nullable accessKey, NSError * _Nullable error)
        {
            [weakSelf authenticateApiLoginCompletionHandlerWithAccessKey:accessKey
                                                                   error:error
                                                                 success:extSuccessBlock
                                                                 failure:extFailureBlock];
        }];
    }]];
}

- (void)continueLoginWithToken:(nonnull NSString *)token
                       success:(nullable LoginSuccessBlock)success
                       failure:(nullable CreatorFailureBlock)failure
{
    NSError *error = nil;
    AccessKey *accessKey = [self.authenticateApi continueLoginWithToken:token error:&error];
    [self authenticateApiLoginCompletionHandlerWithAccessKey:accessKey
                                                       error:error
                                                     success:success
                                                     failure:failure];
}

- (void)authenticateApiLoginCompletionHandlerWithAccessKey:(AccessKey *)accessKey
                                                     error:(nullable NSError *)error
                                                   success:(nullable LoginSuccessBlock)success
                                                   failure:(nullable CreatorFailureBlock)failure
{
    if (accessKey) {
        [self.networkQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            NSError *err = nil;
            DeviceServerApi *deviceServerApi = [DeviceServerApi new];
            [deviceServerApi loginWithKey:accessKey.key secret:accessKey.secret keepMeSignedIn:self.keepMeSignedIn.boolValue error:&err];
            if (err) {
                if (failure) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failure(err);
                    }];
                }
                return;
            }
            
            if (success) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    success(deviceServerApi);
                }];
            }
        }]];
    } else {
        if (failure) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failure(error);
            }];
        }
    }
}

- (BOOL)isSilentLoginStartPossible {
    return [[DataStore class] readKeepMeSignedIn] && [[SecureDataStore class] readRefreshToken] != nil;
}

- (void)silentLoginWithSuccess:(nullable LoginSuccessBlock)success
                       failure:(nullable CreatorFailureBlock)failure
{
    [self.networkQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        NSString *refreshToken = [[SecureDataStore class] readRefreshToken];
        
        if (refreshToken) {
            NSError *error = nil;
            DeviceServerApi *deviceServerApi = [DeviceServerApi new];
            [deviceServerApi loginWithRefreshToken:refreshToken keepMeSignedIn:self.keepMeSignedIn.boolValue error:&error];
            if (error) {
                if (failure) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        failure(error);
                    }];
                }
                return;
            }
            
            if (success) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    success(deviceServerApi);
                }];
                return;
            }
        }
        
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"Refresh token not present. Slient login not performed."}];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                failure(error);
            }];
        }
    }]];
}

+ (nullable NSString *)tokenFromURL:(nonnull NSURL *)url redirectUrlScheme:(nonnull NSString *)scheme {
    return [[AuthenticateApi class] tokenFromURL:url redirectUrlScheme:scheme];
}

+ (nonnull UIViewController *)loginViewControllerWithLoginDelegate:(nonnull id<LoginDelegate>)loginDelegate {
    UIStoryboard *loginStoryboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle bundleForClass:[AuthenticateApi class]]];
    LoginViewController *loginViewController = (LoginViewController *) [loginStoryboard instantiateInitialViewController];
    loginViewController.loginDelegate = loginDelegate;
    return loginViewController;
}

+ (void)logout {
    [[SecureDataStore class] cleanRefreshToken];
    [[DataStore class] cleanKeepMeSignedIn];
}

- (NSNumber *)keepMeSignedIn {
    if (_keepMeSignedIn == nil) {
        return @([DataStore readKeepMeSignedIn]);
    }
    return _keepMeSignedIn;
}

@end

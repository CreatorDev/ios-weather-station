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

@import UIKit;
@import SafariServices;
#import "AuthenticateApi.h"
#import "POSTRequest.h"
#import "LoginDelegate.h"


static NSString *DeveloperIdServerUrl = @"https://developer-id.flowcloud.systems";
static NSString *CreatorClientId = @"1c6c7bee-b5d0-440c-9b5a-61f54a62c18d";
static NSString *CreatorRedirectUrlPath = @"/callback";
static NSString *IdTokenTag = @"id_token";


@interface AuthenticateApi () <SFSafariViewControllerDelegate>
@property(nonatomic, weak, nullable) SFSafariViewController *safariVc;
@property(nonatomic, strong, nullable) LoginCompletionBlock loginCompletionBlock;
@end


@implementation AuthenticateApi

#pragma mark - Public methods

- (void)loginWithDelegate:(nonnull id<LoginDelegate>)loginDelegate
         completionHandler:(LoginCompletionBlock)completion
{
    NSString *redirectUrl = [NSString stringWithFormat:@"%@:%@", loginDelegate.creatorRedirectUrlScheme, CreatorRedirectUrlPath];
    NSString *authenticateUrlStr = [NSString stringWithFormat:@"https://id.creatordev.io/oauth2/auth?client_id=%@&scope=core+openid+offline&redirect_uri=%@&state=dummy_state&nonce=%@&response_type=%@", CreatorClientId, redirectUrl, [NSUUID UUID].UUIDString, IdTokenTag];
    NSURL *authenticateUrl = [NSURL URLWithString:authenticateUrlStr];
    
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:authenticateUrl];
        safariVC.modalPresentationStyle = UIModalPresentationFormSheet;
        safariVC.delegate = weakSelf;
        
        [loginDelegate.safariRootViewController presentViewController:safariVC animated:YES completion:nil];
        weakSelf.safariVc = safariVC;
        weakSelf.loginCompletionBlock = completion;
        loginDelegate.openUrlDelegate = weakSelf;
        // There are two ways LoginCompletionBlock will be called:
        // 1) processOpenUrl: is called from loginDelegate
        // 2) or from SFSafariViewControllerDelegate safariViewControllerDidFinish:
    }];
}

- (BOOL)processOpenUrl:(nonnull NSURL *)url source:(nonnull id<LoginDelegate>)loginDelegate {
    loginDelegate.openUrlDelegate = nil;
    
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf.safariVc dismissViewControllerAnimated:YES completion:nil];
    }];
    NSString *token = [[self class] tokenFromURL:url redirectUrlScheme:loginDelegate.creatorRedirectUrlScheme];
    if (token) {
        NSError *error = nil;
        AccessKey *accessKey = [self accessKeyWithToken:token error:&error];
        [self callLoginCompletionBlockWithAccessKey:accessKey error:error];
        return YES;
    }
    return NO;
}

- (nullable AccessKey *)continueLoginWithToken:(nonnull NSString *)token
                                         error:(NSError * _Nullable * _Nullable)error
{
    return [self accessKeyWithToken:token error:error];
}

+ (nullable NSString *)tokenFromURL:(nonnull NSURL *)url redirectUrlScheme:(nonnull NSString *)scheme {
    if ([url.scheme isEqualToString:scheme] &&
        [url.path isEqualToString:CreatorRedirectUrlPath])
    {
        NSArray<NSString *> *tokenKeyValue = [url.fragment componentsSeparatedByString:@"="];
        if (tokenKeyValue.count == 2 &&
            [tokenKeyValue[0] isEqualToString:IdTokenTag])
        {
            return tokenKeyValue[1];
        }
    }
    return nil;
}

#pragma mark - Authentication Server methods

- (nullable AccessKey *)accessKeyWithToken:(nonnull NSString *)token
                                     error:(NSError * _Nullable * _Nullable)error
{
    NSString *bodyStr = [NSString stringWithFormat:@"%@=%@", IdTokenTag, token];
    NSData *body = [bodyStr dataUsingEncoding:NSASCIIStringEncoding];
    POSTRequest *request = [POSTRequest POSTRequestWithUrl:[self developerIdServerUrl]
                                                    accept:@"application/vnd.imgtec.com.accesskey+json"
                                               contentType:@"application/x-www-form-urlencoded"
                                                      body:body
                                                      auth:nil];
    return [request executeWithSharedUrlSessionAndReturnClass:[AccessKey class] error:error];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    self.loginDelegate.openUrlDelegate = nil;

    NSError *error = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"Safari View Controller Done button pressed."}];
    [self callLoginCompletionBlockWithAccessKey:nil error:error];
}

#pragma mark - Private

- (void)callLoginCompletionBlockWithAccessKey:(AccessKey *)ak
                                        error:(NSError *)error
{
    if (self.loginCompletionBlock) {
        void(^loginCompletionBlock)(AccessKey *, NSError *) = self.loginCompletionBlock;
        self.loginCompletionBlock = nil;
        loginCompletionBlock(ak, error);
    }
}

- (nonnull NSURL *)developerIdServerUrl {
    return [NSURL URLWithString:DeveloperIdServerUrl];
}

@end

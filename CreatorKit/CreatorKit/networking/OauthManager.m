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

#import "OauthManager.h"
#import "OauthRequest.h"
#import "OauthToken.h"
#import "SecureDataStore.h"

@interface OauthManager ()
@property(nonatomic, strong, nonnull) NSURL *authenticateUrl;
@property(atomic, strong, nullable) OauthToken *oauthToken;
@end

@implementation OauthManager
@synthesize oauthToken = _oauthToken;

- (nonnull instancetype)initWithAuthenticateUrl:(nonnull NSURL *)url {
    self = [super init];
    if (self) {
        if (url == nil) {
            return nil;
        }
        _authenticateUrl = url;
    }
    return self;
}

- (void)authorizeWithAccessKey:(nonnull NSString *)key
                        secret:(nonnull NSString *)secret
                         error:(NSError * _Nullable * _Nullable)error
{
    self.oauthToken = [self oauthTokenWithUrl:self.authenticateUrl username:key password:secret error:error];
    if (self.storeRefreshToken && self.oauthToken.refreshToken) {
        [[SecureDataStore class] storeRefreshToken:self.oauthToken.refreshToken];
    }
}

- (void)authorizeWithRefreshToken:(nonnull NSString *)token
                            error:(NSError * _Nullable * _Nullable)error
{
    self.oauthToken = [self oauthTokenWithUrl:self.authenticateUrl refreshToken:token error:error];
    if (self.storeRefreshToken && self.oauthToken.refreshToken) {
        [[SecureDataStore class] storeRefreshToken:self.oauthToken.refreshToken];
    }
}

- (OauthToken *)oauthToken {
    @synchronized (self) {
        if (_oauthToken == nil || [_oauthToken.expireTime timeIntervalSinceDate:[NSDate date]] < 30.0) {
            [self authorize];
        }
        return _oauthToken;
    }
}

#pragma mark - Private

- (void)authorize {
    NSString *refreshToken = _oauthToken.refreshToken;
    if (refreshToken) {
        NSError *error = nil;
        _oauthToken = [self oauthTokenWithUrl:self.authenticateUrl refreshToken:refreshToken error:&error];
        if (self.storeRefreshToken && _oauthToken.refreshToken) {
            [[SecureDataStore class] storeRefreshToken:_oauthToken.refreshToken];
        }
        if (error) {
            NSLog(@"ERROR refresh token: %@", error);
        }
    }
}

- (nullable OauthToken *)oauthTokenWithUrl:(nonnull NSURL *)url
                                  username:(nonnull NSString *)username
                                  password:(nonnull NSString *)password
                                     error:(NSError * _Nullable * _Nullable)error
{
    OauthRequest *request = [OauthRequest oauthRequestWithUrl:url
                                                     username:username
                                                     password:password];
    return [request executeWithSharedUrlSessionAndReturnClass:[OauthToken class] error:error];
}

- (nullable OauthToken *)oauthTokenWithUrl:(nonnull NSURL *)url
                              refreshToken:(nonnull NSString *)token
                                     error:(NSError * _Nullable * _Nullable)error
{
    OauthRequest *request = [OauthRequest oauthRequestWithUrl:url refreshToken:token];
    return [request executeWithSharedUrlSessionAndReturnClass:[OauthToken class] error:error];
}

- (void)setOauthToken:(OauthToken *)oauthToken {
    @synchronized (self) {
        if (_oauthToken != oauthToken) {
            _oauthToken = oauthToken;
        }
    }
}

@end

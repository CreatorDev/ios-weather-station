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

#import "BaseRequest.h"
#import "JsonInit.h"

@interface BaseRequest ()
@property(nonatomic, strong, nonnull) NSURL *url;
@property(nonatomic, strong, nullable) NSMutableURLRequest *request;
@end

@implementation BaseRequest

- (nonnull instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        _request = [NSMutableURLRequest requestWithURL:url];
    }
    return self;
}

- (void)setOauthToken:(OauthToken *)oauthToken {
    if (_oauthToken != oauthToken) {
        _oauthToken = oauthToken;
        
        NSString *authValue = nil;
        if (oauthToken) {
            authValue = [NSString stringWithFormat:@"%@ %@", oauthToken.tokenType, oauthToken.accessToken];
        }
        [self.request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
}

- (nullable id)executeWithUrlSession:(nonnull NSURLSession *)session completionHandler:(id(^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    __block id result = nil;
    if (self.request == nil) {
        NSError *error = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"URL request is nil."}];
        completionHandler(nil, nil, error);
        return nil;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[session dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
      {
          result = completionHandler(data, response, error);
          dispatch_semaphore_signal(semaphore);
      }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (nullable id)executeWithUrlSession:(nonnull NSURLSession *)session
                         returnClass:(nullable Class)class
                               error:(NSError * _Nullable * _Nullable)error
{
    __block NSError *bErr = nil;
    __weak typeof(self) weakSelf = self;
    id result = [self executeWithUrlSession:session completionHandler:^id(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err)
                 {
                     if (err) {
                         bErr = err;
                         return nil;
                     }
                     
                     if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                         if (!(httpResponse.statusCode >=200 && httpResponse.statusCode < 300)) {
                             bErr = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": [NSString stringWithFormat:@"HTTP response code: %@", @(httpResponse.statusCode)]}];
                             return nil;
                         }
                     }
                     
                     if (response.MIMEType && weakSelf.request.allHTTPHeaderFields[@"Accept"] &&
                         NO == [response.MIMEType isEqualToString:weakSelf.request.allHTTPHeaderFields[@"Accept"]])
                     {
                         bErr = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"response MIMEType is not equal to Accept HTTP header field", @"responseMIMEType": response.MIMEType, @"Accept": weakSelf.request.allHTTPHeaderFields[@"Accept"]}];
                         return nil;
                     }
                     
                     if (class) {
                         if ([class conformsToProtocol:@protocol(JsonInit)]) {
                             id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&bErr];
                             if (bErr) {
                                 return nil;
                             }
                             
                             return [[class alloc] initWithJson:json];
                         } else {
                             bErr = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"Class should conform to JsonInit protocol.", @"class": NSStringFromClass(class)}];
                             return nil;
                         }
                     }
                     return nil;
                 }];
    if (error) {
        *error = bErr;
    }
    return result;
}

- (nullable id)executeWithSharedUrlSessionAndReturnClass:(nullable Class)class
                                                   error:(NSError * _Nullable * _Nullable)error
{
    return [self executeWithUrlSession:[NSURLSession sharedSession] returnClass:class error:error];
}

@end

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

#import "OauthRequest.h"

@interface BaseRequest ()
@property(nonatomic, strong, nullable) NSMutableURLRequest *request;
@end

@implementation OauthRequest

+ (nullable OauthRequest *)oauthRequestWithUrl:(nonnull NSURL *)url
                                      username:(nonnull NSString *)username
                                      password:(nonnull NSString *)password
{
    NSData *httpBody = [[self class] HTTPBodyWithUsername:username password:password];
    return [[self class] oauthRequestWithUrl:url httpBody:httpBody];
}

+ (nullable OauthRequest *)oauthRequestWithUrl:(nonnull NSURL *)url
                                  refreshToken:(nonnull NSString *)refreshToken
{
    NSData *httpBody = [[self class] HTTPBodyWithRefreshToken:refreshToken];
    return [[self class] oauthRequestWithUrl:url httpBody:httpBody];
}

#pragma mark - Private

+ (nullable NSData *)HTTPBodyWithUsername:(nonnull NSString *)username
                                 password:(nonnull NSString *)password
{
    NSString *post = [NSString stringWithFormat:@"grant_type=password&username=%@&password=%@", username, password];
    return [post dataUsingEncoding:NSASCIIStringEncoding];
}

+ (nullable NSData *)HTTPBodyWithRefreshToken:(nonnull NSString *)refreshToken
{
    NSString *post = [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@", refreshToken];
    return [post dataUsingEncoding:NSASCIIStringEncoding];
}

+ (nullable OauthRequest *)oauthRequestWithUrl:(nonnull NSURL *)url
                                      httpBody:(nonnull NSData *)httpBody
{
    OauthRequest *oauthRequest = [[OauthRequest alloc] initWithUrl:url];
    oauthRequest.request.HTTPMethod = @"POST";
    oauthRequest.request.HTTPBody = httpBody;
    [oauthRequest.request setValue:@"application/vnd.imgtec.oauthtoken+json" forHTTPHeaderField:@"Accept"];
    [oauthRequest.request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    return oauthRequest;
}

@end

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

#import "OauthToken.h"

@implementation OauthToken

- (NSString *)description {
    NSString *mainStr = [NSString stringWithFormat:@"OauthToken: (type: %@, token: \"%@\", expire time: %@)", self.tokenType, self.accessToken, self.expireTime];
    if (self.links.count > 0) {
        return [NSString stringWithFormat:@"{%@\n%@}", mainStr, super.description];
    }
    
    return mainStr;
}

#pragma mark - JsonInit protocol

- (nullable instancetype)initWithJson:(nonnull id)json {
    self = [super initWithJson:json];
    if (self) {
        if (NO == [self parseOauthTokenJson:json]) {
            self = nil;
        }
    }
    return self;
}

#pragma mark - Private

- (BOOL)parseOauthTokenJson:(nonnull id)json {
    if ([json isKindOfClass:[NSDictionary class]]) {
        if ([json[@"access_token"] isKindOfClass:[NSString class]] &&
            (json[@"refresh_token"] == nil || [json[@"refresh_token"] isKindOfClass:[NSString class]]) &&
            [json[@"token_type"] isKindOfClass:[NSString class]] &&
            [json[@"expires_in"] isKindOfClass:[NSNumber class]])
        {
            self.accessToken = json[@"access_token"];
            self.refreshToken = json[@"refresh_token"];
            self.tokenType = json[@"token_type"];
            NSNumber *expiresIn = json[@"expires_in"];
            self.expireTime = [NSDate dateWithTimeIntervalSinceNow:expiresIn.doubleValue];
        } else {
            NSLog(@"%@ In OauthToken, wrong type for one of access_token/refresh_token/token_type/expires_in.", NSStringFromSelector(_cmd));
            return NO;
        }
    }
    return YES;
}

@end

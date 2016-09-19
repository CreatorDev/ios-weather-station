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

#import "SecureDataStore.h"


static NSString *DeviceServerRefreshTokenId = @"DeviceServerRefreshToken";


@implementation SecureDataStore

+ (void)storeRefreshToken:(nonnull NSString *)refreshToken {
    [self cleanRefreshToken];
    [[self class] createKeychainValue:refreshToken forIdentifier:DeviceServerRefreshTokenId];
}

+ (void)cleanRefreshToken {
    if ([[self class] searchKeychainCopyMatching:DeviceServerRefreshTokenId] != nil) {
        [[self class] deleteKeychainValueWithIdentifier:DeviceServerRefreshTokenId];
    }
}

+ (nullable NSString *)readRefreshToken {
    return [[self class] searchKeychainCopyMatching:DeviceServerRefreshTokenId];
}

#pragma mark - Private (Keychain)

+ (nonnull NSDictionary *)newSearchDictionaryWithIdentifier:(nonnull NSString *)identifier {
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    return @{(id)kSecClass: (id)kSecClassGenericPassword,
             (id)kSecAttrGeneric: encodedIdentifier,
             (id)kSecAttrAccount: encodedIdentifier,
             (id)kSecAttrService: @"deviceserver",
             (id)kSecAttrAccessible: (id)kSecAttrAccessibleWhenUnlocked};
}

+ (nullable NSString *)searchKeychainCopyMatching:(nonnull NSString *)identifier {
    NSMutableDictionary *searchDict = [[[self class] newSearchDictionaryWithIdentifier:identifier] mutableCopy];
    searchDict[(id)kSecMatchLimit] = (id)kSecMatchLimitOne;
    searchDict[(id)kSecReturnData] = (id)kCFBooleanTrue;
    
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)searchDict, (CFTypeRef *)&result);
    if (status != errSecSuccess) {
        return nil;
    }
    
    NSData *resultData = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

+ (BOOL)createKeychainValue:(nonnull NSString *)value forIdentifier:(nonnull NSString *)identifier {
    NSMutableDictionary *createDict = [[[self class] newSearchDictionaryWithIdentifier:identifier] mutableCopy];
    createDict[(id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    
    OSStatus status = SecItemAdd((CFDictionaryRef)createDict, NULL);
    if (status != errSecSuccess) {
        NSLog(@"create keychain error: %@", @(status));
    }
    return status == errSecSuccess;
}

+ (BOOL)deleteKeychainValueWithIdentifier:(nonnull NSString *)identifier {
    NSDictionary *deleteDictionary = [[self class] newSearchDictionaryWithIdentifier:identifier];
    OSStatus status = SecItemDelete((CFDictionaryRef)deleteDictionary);
    if (status != errSecSuccess) {
        NSLog(@"delete keychain error: %@", @(status));
    }
    return status == errSecSuccess;
}

@end

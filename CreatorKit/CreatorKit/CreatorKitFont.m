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

#import "CreatorKitFont.h"
@import CoreText;

@implementation CreatorKitFont

+ (nonnull NSArray<NSString *> *)fontNames {
    return @[@"Roboto-Black",
             @"Roboto-Italic",
             @"Roboto-MediumItalic",
             @"RobotoCondensed-Bold",
             @"RobotoCondensed-LightItalic",
             @"Roboto-BlackItalic",
             @"Roboto-Light",
             @"Roboto-Regular",
             @"RobotoCondensed-BoldItalic",
             @"RobotoCondensed-Regular",
             @"Roboto-Bold",
             @"Roboto-LightItalic",
             @"Roboto-Thin",
             @"RobotoCondensed-Italic",
             @"Roboto-BoldItalic",
             @"Roboto-Medium",
             @"Roboto-ThinItalic",
             @"RobotoCondensed-Light"];
}

+ (nullable UIFont *)creatorKitFontWithName:(nonnull NSString *)name size:(CGFloat)size {
    [[self class] registerFonts];
    return [UIFont fontWithName:name size:size];
}

+ (void)registerFonts {
    static BOOL fontsRegistered = NO;
    
    if (NO == fontsRegistered) {
        for (NSString *font in [[self class] fontNames]) {
            NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:font withExtension:@"ttf"];
            if (url != nil) {
                CFErrorRef error = nil;
                CTFontManagerRegisterFontsForURL((CFURLRef)url, kCTFontManagerScopeNone, &error);
                if (error != nil) {
                    NSLog(@"ERROR: registering font: %@.", error);
                }
            }
        }
        fontsRegistered = YES;
    }
}

@end

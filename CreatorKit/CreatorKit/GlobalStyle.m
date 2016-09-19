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

#import "GlobalStyle.h"

@implementation GlobalStyle

+ (void)setupAppearance {
    [UINavigationBar appearance].barTintColor = [[GlobalStyle class] primaryColor];
    [UINavigationBar appearance].tintColor = [[GlobalStyle class] primaryColor2];
    [UINavigationBar appearance].translucent = NO;
}

+ (UIColor *)primaryColor {
    return [UIColor colorWithRed:114.0/255.0 green:22.0/255.0 blue:107.0/255.0 alpha:1.0];
}

+ (UIColor *)primaryColor2 {
    return [UIColor whiteColor];
}

+ (UIColor *)supportingColorDark {
    return [UIColor colorWithRed:60.0/255.0 green:5.0/255.0 blue:85.0/255.0 alpha:1.0];
}

+ (UIColor *)supportingColorLight {
    return [UIColor colorWithRed:170.0/255.0 green:115.0/255.0 blue:166.0/255.0 alpha:1.0];
}

+ (UIColor *)secondaryColorDarkGrey {
    return [UIColor colorWithRed:41.0/255.0 green:44.0/255.0 blue:56.0/255.0 alpha:1.0];
}

+ (UIColor *)secondaryColorGrey {
    return [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
}

+ (UIColor *)secondaryColorLightGrey {
    return [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0];
}

+ (UIColor *)textPrimaryColor {
    return [UIColor colorWithRed:41.0/255.0 green:44.0/255.0 blue:56.0/255.0 alpha:1.0];
}

+ (UIColor *)textSecondaryColor {
    return [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
}

+ (UIColor *)textDisabledColor {
    return [UIColor colorWithRed:158.0/255.0 green:158.0/255.0 blue:158.0/255.0 alpha:1.0];
}

+ (UIColor *)textFieldSelectedUnderlineColor {
    return [UIColor colorWithRed:170.0/255.0 green:115.0/255.0 blue:166.0/255.0 alpha:1.0];
}

+ (UIColor *)textFieldDefaultUnderlineColor {
    return [[self class] textDisabledColor];
}

+ (UIColor *)textFieldErrorUnderlineColor {
    return [UIColor colorWithRed:213.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
}

@end

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

#import "CreatorButton.h"
#import "CreatorKitFont.h"
#import "GlobalStyle.h"

@interface CreatorButton ()
@property(nonatomic, assign) BOOL creatorHighlighted;
@property(nonatomic, assign) BOOL creatorEnabled;
@end

@implementation CreatorButton

- (void)prepareForInterfaceBuilder {
    [self setupBorder];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.titleLabel.font = [CreatorKitFont creatorKitFontWithName:@"Roboto-Regular" size:self.titleLabel.font.pointSize];
        [self setupBorder];
        _creatorEnabled = YES;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.borderColor = self.tintColor.CGColor;
    _creatorEnabled = self.enabled;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.layer.borderColor = tintColor.CGColor;
}

- (void)setupBorder {
    self.layer.borderWidth = 1.0;
    self.layer.cornerRadius = 3.0;
    self.layer.borderColor = self.tintColor.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    _creatorHighlighted = highlighted;
    if (_creatorEnabled) {
        if (highlighted) {
            self.backgroundColor = [[GlobalStyle class] primaryColor];
            self.titleLabel.textColor = [[GlobalStyle class] primaryColor2];
        } else {
            self.backgroundColor = [[GlobalStyle class] primaryColor2];
            self.titleLabel.textColor = [[GlobalStyle class] primaryColor];
        }
    }
}

-(BOOL)isHighlighted {
    return _creatorHighlighted;
}

- (void)setEnabled:(BOOL)enabled {
    _creatorEnabled = enabled;
    if (enabled) {
        [self setHighlighted:_creatorHighlighted];
        self.layer.borderColor = self.tintColor.CGColor;
    } else {
        self.backgroundColor = [[GlobalStyle class] secondaryColorLightGrey];
        self.titleLabel.textColor = [[GlobalStyle class] secondaryColorGrey];
        self.layer.borderColor = [[GlobalStyle class] secondaryColorLightGrey].CGColor;
    }
}

- (BOOL)isEnabled {
    return _creatorEnabled;
}

@end

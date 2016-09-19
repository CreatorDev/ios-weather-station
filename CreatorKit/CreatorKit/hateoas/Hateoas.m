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

#import "Hateoas.h"
#import "Link.h"

@implementation Hateoas

- (NSString *)description {
    NSMutableString *desc = [NSMutableString new];
    [desc appendString:@"Links:[\n"];
    for (Link *link in self.links) {
        [desc appendString:[NSString stringWithFormat:@"%@\n", link]];
    }
    [desc appendString:@"]"];
    return [desc copy];
}

#pragma mark - Public

- (NSArray<Link *> *)links {
    if (_links == nil) {
        _links = @[];
    }
    return _links;
}

- (nullable Link *)linkByRel:(nonnull NSString *)rel {
    __block Link *link = nil;
    [self.links enumerateObjectsUsingBlock:^(Link * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.rel isEqualToString:rel]) {
            link = obj;
            return;
        }
    }];
    return link;
}

#pragma mark - JsonInit protocol

- (nullable instancetype)initWithJson:(nonnull id)json {
    self = [super init];
    if (self) {
        if (NO == [self parseLinksJson:json]) {
            self = nil;
        }
    }
    return self;
}

#pragma mark - Private

- (BOOL)parseLinksJson:(nonnull id)json {
    NSMutableArray<Link *> *linksArray = [NSMutableArray new];
    if ([json isKindOfClass:[NSDictionary class]] &&
        [json[@"Links"] isKindOfClass:[NSArray class]])
    {
        for (id l in json[@"Links"]) {
            if ([l isKindOfClass:[NSDictionary class]])
            {
                Link *link = [[Link alloc] initWithJson:l];
                if (link) {
                    [linksArray addObject:link];
                } else {
                    NSLog(@"%@ Link is not valid (%@).", NSStringFromSelector(_cmd), l);
                    return NO;
                }
            } else {
                NSLog(@"%@ Link is not dictionary (%@).", NSStringFromSelector(_cmd), l);
                return NO;
            }
        }
    }
    self.links = [linksArray copy];
    return YES;
}

@end

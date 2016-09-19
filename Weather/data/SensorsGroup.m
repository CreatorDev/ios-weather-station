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

#import "SensorsGroup.h"

@implementation SensorsGroup

- (nonnull instancetype)initWithGroupId:(nonnull NSString *)groupId name:(nonnull NSString *)name {
    self = [super init];
    if (self) {
        _groupId = groupId;
        _name = name;
    }
    return self;
}

- (nonnull instancetype)initWithGroupName:(nonnull NSString *)name {
    NSString *groupId = [NSUUID UUID].UUIDString;
    return [self initWithGroupId:groupId name:name];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SensorsGroup: (groupId: %@, groupName: %@)", self.groupId, self.name];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SensorsGroup class]]) {
        SensorsGroup *obj = (SensorsGroup *)object;
        return [self.groupId isEqual:obj.groupId];
        
    }
    return NO;
}

#pragma mark - NSCopying protocol
- (id)copyWithZone:(NSZone *)zone {
    return [[SensorsGroup alloc] initWithGroupId:self.groupId name:self.name];
}

#pragma mark - NSCoding protocol

-(void)encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.groupId forKey:@"groupId"];
    [encoder encodeObject:self.name forKey:@"groupName"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.groupId = [decoder decodeObjectForKey:@"groupId"];
        self.name = [decoder decodeObjectForKey:@"groupName"];
    }
    return self;
}

@end

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

#import "SensorsDataStore.h"
#import "Sensor+Empty.h"

@implementation SensorsDataStore 

+ (void)storeGroups:(nonnull NSArray<SensorsGroup *> *)groups {
    NSData *encodedGroups = [NSKeyedArchiver archivedDataWithRootObject:groups];
    [[NSUserDefaults standardUserDefaults] setObject:encodedGroups forKey:@"Groups"];
}

+ (nullable NSArray<SensorsGroup *> *)loadGroups {
    NSData *groupsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"Groups"];
    if (groupsData != nil) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:groupsData];
    }
    return nil;
}

+ (void)storeSensors:(nonnull NSDictionary<NSString *, NSArray<Sensor *> *> *)sensors {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *storeSensors = [[self class] convertSensors:sensors];
    NSData *sensorsData = [NSKeyedArchiver archivedDataWithRootObject:storeSensors];
    [[NSUserDefaults standardUserDefaults] setObject:sensorsData forKey:@"Sensors"];
}

+ (nullable NSDictionary<NSString *, NSArray<NSString *> *> *)loadSensors {
    NSData *sensorsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"Sensors"];
    if (sensorsData != nil) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:sensorsData];
    }
    return nil;
}

#pragma mark - Private

+ (nonnull NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *)convertSensors:(nonnull NSDictionary<NSString *, NSArray<Sensor *> *> *)sensors {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *storeSensors = [NSMutableDictionary new];
    for (NSString *groupId in sensors.allKeys) {
        storeSensors[groupId] = [NSMutableArray new];
        for (Sensor *sensor in sensors[groupId]) {
            if (NO == [sensor isEmpty]) {
                [storeSensors[groupId] addObject:sensor.identifier];
            }
        }
        if (storeSensors[groupId].count == 0) {
            storeSensors[groupId] = nil;
        }
    }
    return storeSensors;
}

@end

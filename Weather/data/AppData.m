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

@import UIKit;
#import "AppData.h"
#import "Sensor+Empty.h"
#import "SensorsDataStore.h"


NSString * _Nonnull AppDataReloadNotification = @"io.CreatorDev.Weather.AppDataReloadNotification";
NSString * _Nonnull AppDataChangeNotification = @"io.CreatorDev.Weather.AppDataChangeNotification";
NSString * _Nonnull AppDataInsertedObjectsKey = @"io.CreatorDev.Weather.AppDataInsertedObjectsKey";
NSString * _Nonnull AppDataUpdatedObjectsKey = @"io.CreatorDev.Weather.AppDataUpdatedObjectsKey";
NSString * _Nonnull AppDataDeletedObjectsKey = @"io.CreatorDev.Weather.AppDataDeletedObjectsKey";

static NSString * _Nonnull UnassignedSensorGroupId = @"Unassigned";

typedef NSDictionary<NSString *, NSString *> SensorsGroupStorage;


@interface AppData ()
@property(nonatomic, strong, nonnull) NSMutableArray<SensorsGroup *> *mutableGroups;
@property(nonatomic, strong, nonnull) NSMutableDictionary<NSString *, NSMutableArray<Sensor *> *> *mutableSensors;
@property(nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *sensorIdentifiers;
@end

@implementation AppData

- (NSArray<SensorsGroup *> *)groups {
    return [self.mutableGroups copy];
}

- (NSDictionary<NSString *,NSMutableArray<Sensor *> *> *)sensors {
    return [self.mutableSensors copy];
}

- (nonnull NSArray<SensorsGroup *> *)groupsForEdit {
    NSArray<SensorsGroup *> *groups = [[NSArray alloc] initWithArray:self.mutableGroups copyItems:YES];
    return [groups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K != %@", @"groupId", UnassignedSensorGroupId]];
}

- (void)moveSensorAtIndexPath:(nonnull NSIndexPath *)sourceIndexPath toIndexPath:(nonnull NSIndexPath *)destinationIndexPath {
    NSUInteger srcGroupIdx = sourceIndexPath.section;
    NSUInteger srcSensorIdx = sourceIndexPath.item;
    NSUInteger dstGroupIdx = destinationIndexPath.section;
    NSUInteger dstSensorIdx = destinationIndexPath.item;
    
    if (srcGroupIdx == dstGroupIdx && srcSensorIdx == dstSensorIdx) {
        return;
    }
    
    SensorsGroup *srcGroup = self.mutableGroups[srcGroupIdx];
    SensorsGroup *dstGroup = self.mutableGroups[dstGroupIdx];
    NSMutableArray<Sensor *> *srcGroupSensors = self.mutableSensors[srcGroup.groupId];
    NSMutableArray<Sensor *> *dstGroupSensors = self.mutableSensors[dstGroup.groupId];
    
    Sensor *movedSensor = srcGroupSensors[srcSensorIdx];
    [srcGroupSensors removeObjectAtIndex:srcSensorIdx];
    [dstGroupSensors insertObject:movedSensor atIndex:dstSensorIdx];
    
    [[SensorsDataStore class] storeSensors:self.sensors];
    self.sensorIdentifiers = nil;
    [self manageEmptySensorsAndNotify:YES];
}

- (void)setNewGroups:(nonnull NSArray<SensorsGroup *> *)groups {
    if (self.stopRefreshing) {
        return;
    }
    
    SensorsGroup *unassignedGroup = [self.mutableGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", @"groupId", UnassignedSensorGroupId]].firstObject;
    NSMutableArray<SensorsGroup *> *newGroups = [groups mutableCopy];
    
    for (SensorsGroup *group in self.mutableGroups) {
        if (NO == [newGroups containsObject:group] &&
            NO == [group isEqual:unassignedGroup]) {
            NSMutableArray<Sensor *> *sensors = self.mutableSensors[group.groupId];
            NSMutableArray<Sensor *> *unassignedSensors = self.mutableSensors[unassignedGroup.groupId];
            [unassignedSensors addObjectsFromArray:sensors];
            [sensors removeAllObjects];
        }
    }
    for (SensorsGroup *group in newGroups) {
        if (NO == [self.mutableGroups containsObject:group]) {
            self.mutableSensors[group.groupId] = [NSMutableArray new];
        }
    }
    
    [[SensorsDataStore class] storeGroups:newGroups]; // store without "Unassigned" group
    [newGroups addObject:unassignedGroup];
    self.mutableGroups = newGroups;
    [self manageEmptySensorsAndNotify:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:AppDataReloadNotification object:self];
}

- (void)setNewSensors:(nonnull NSArray<Sensor *> *)newSensors {
    if (self.stopRefreshing) {
        return;
    }
    
    SensorsGroup *unassignedGroup = [self.mutableGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", @"groupId", UnassignedSensorGroupId]].firstObject;
    
    for (SensorsGroup *group in self.groups) {
        self.mutableSensors[group.groupId] = [NSMutableArray new];
    }
    
    //FIXME: Join Power and Distance sensors into Lightning sensor
    for (Sensor *sensor in newSensors) {
        // find sensor identifier in self.sensorIdentifiers and assign sensor to correct group
        // if not found, assign sensor to "Unassigned" group
        
        BOOL added = NO;
        for (NSString *groupId in self.sensorIdentifiers.allKeys) {
            NSMutableArray<NSString *> *sensorIds = self.sensorIdentifiers[groupId];
            if ([sensorIds containsObject:sensor.identifier]) {
                NSArray<SensorsGroup *> *sensorGroup = [self.groups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", @"groupId", groupId]];
                if (sensorGroup.count == 1) {
                    [self.mutableSensors[groupId] addObject:sensor];
                    added = YES;
                } else {
                    self.sensorIdentifiers[groupId] = nil;
                }
                break;
            }
        }
        if (NO == added) {
            [self.mutableSensors[unassignedGroup.groupId] addObject:sensor];
        }
    }
    
    [self manageEmptySensorsAndNotify:NO];
    [[SensorsDataStore class] storeSensors:self.mutableSensors];
    [[NSNotificationCenter defaultCenter] postNotificationName:AppDataReloadNotification object:self];
}

#pragma mark - Private

- (NSMutableArray<SensorsGroup *> *)mutableGroups {
    if (_mutableGroups == nil) {
        _mutableGroups = [[[SensorsDataStore class] loadGroups] mutableCopy];
        if (_mutableGroups == nil) {
            _mutableGroups = [NSMutableArray new];
        }
        
        SensorsGroup *unassignedSensorsGroup = [[SensorsGroup alloc] initWithGroupId:UnassignedSensorGroupId name:@"Unassigned"];
        [_mutableGroups addObject:unassignedSensorsGroup];
        if (_mutableSensors != nil) {
            for (SensorsGroup *group in _mutableGroups) {
                if (_mutableSensors[group.groupId] == nil) {
                    _mutableSensors[group.groupId] = [NSMutableArray new];
                }
            }
            [self manageEmptySensorsForGroups:_mutableGroups sensors:_mutableSensors notify:NO];
        }
    }
    return _mutableGroups;
}

- (NSMutableDictionary<NSString *, NSMutableArray<Sensor *> *> *)mutableSensors {
    if (_mutableSensors == nil) {
        _mutableSensors = [NSMutableDictionary new];
        if (_mutableGroups != nil) {
            for (SensorsGroup *group in _mutableGroups) {
                if (_mutableSensors[group.groupId] == nil) {
                    _mutableSensors[group.groupId] = [NSMutableArray new];
                }
            }
            [self manageEmptySensorsForGroups:_mutableGroups sensors:_mutableSensors notify:NO];
        }
    }
    return _mutableSensors;
}

- (NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *)sensorIdentifiers {
    if (_sensorIdentifiers == nil) {
        NSDictionary<NSString *, NSArray<NSString *> *> *sensorIds = [[SensorsDataStore class] loadSensors];
        NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *mutableSensorIds = [sensorIds mutableCopy];
        for (NSString *key in sensorIds.allKeys) {
            mutableSensorIds[key] = [sensorIds[key] mutableCopy];
        }
        
        _sensorIdentifiers = mutableSensorIds;
    }
    return _sensorIdentifiers;
}

- (nonnull NSArray<NSIndexPath *> *)indexPathsOfSensors:(nonnull NSArray<Sensor *> *)sensors {
    NSMutableArray<NSIndexPath *> *result = [NSMutableArray new];
    
    for (Sensor *sensor in sensors) {
        for (NSUInteger groupIdx=0; groupIdx<self.mutableGroups.count; groupIdx++) {
            NSString *groupId = self.mutableGroups[groupIdx].groupId;
            NSArray<Sensor *> *sensorsInGroup = self.mutableSensors[groupId];

            NSUInteger sensorIdx = [sensorsInGroup indexOfObject:sensor];
            if (sensorIdx != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sensorIdx inSection:groupIdx];
                [result addObject:indexPath];
            }
        }
    }

    return result;
}

- (void)manageEmptySensorsAndNotify:(BOOL)notify {
    [self manageEmptySensorsForGroups:self.mutableGroups sensors:self.mutableSensors notify:notify];
}

- (void)manageEmptySensorsForGroups:(NSMutableArray<SensorsGroup *> *)groups
                            sensors:(NSMutableDictionary<NSString *, NSMutableArray<Sensor *> *> *)sensors
{
    [self manageEmptySensorsForGroups:groups sensors:sensors notify:YES];
}

- (void)manageEmptySensorsForGroups:(NSMutableArray<SensorsGroup *> *)groups
                            sensors:(NSMutableDictionary<NSString *, NSMutableArray<Sensor *> *> *)sensors
                             notify:(BOOL)notify
{
    for (SensorsGroup *group in groups) {
        NSUInteger nonEmptySensors = 0;
        NSMutableArray<Sensor *> *emptySensors = [NSMutableArray new];
        for (Sensor *sensor in sensors[group.groupId]) {
            if ([sensor isEmpty]) {
                [emptySensors addObject:sensor];
            } else {
                nonEmptySensors++;
            }
        }
        
        if (nonEmptySensors > 0) {
            if (emptySensors.count > 0) {
                // remove all empty sensors
                NSArray<NSIndexPath *> *removedSensorsIndexPaths = [self indexPathsOfSensors:emptySensors];
                [sensors[group.groupId] removeObjectsInArray:emptySensors];
                if (notify && NO == self.stopRefreshing) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDataChangeNotification object:self userInfo:@{AppDataDeletedObjectsKey: removedSensorsIndexPaths}];
                }
            }
        } else {
            if (emptySensors.count > 0) {
                // leave only one empty sensor, remove all the rest of the empty sensors
                [emptySensors removeObject:emptySensors.firstObject];
                NSArray<NSIndexPath *> *removedSensorsIndexPaths = [self indexPathsOfSensors:emptySensors];
                if (notify && NO == self.stopRefreshing) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDataChangeNotification object:self userInfo:@{AppDataDeletedObjectsKey: removedSensorsIndexPaths}];
                }
                [sensors[group.groupId] removeObjectsInArray:emptySensors];
            } else {
                // add one empty sensor
                emptySensors = [@[[[Sensor class] emptySensor]] mutableCopy];
                [sensors[group.groupId] addObjectsFromArray:emptySensors];
                if (notify && NO == self.stopRefreshing) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDataChangeNotification object:self userInfo:@{AppDataInsertedObjectsKey: [self indexPathsOfSensors:emptySensors]}];
                }
            }
        }
    }
}

@end

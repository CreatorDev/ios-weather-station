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

#import "SensorsDataSource.h"
#import "WeatherCollectionCell.h"
#import "WeatherSectionHeaderView.h"
#import "Sensor+Empty.h"
#import <CreatorKit/CreatorKit.h>


@interface SensorsDataSource ()
@property(nonatomic, strong, nonnull) AppData *appData;
@end

@implementation SensorsDataSource

- (nonnull instancetype)initWithAppData:(nonnull AppData *)appData {
    self = [super init];
    if (self) {
        _appData = appData;
    }
    return self;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.appData.groups.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSString *groupId = self.appData.groups[section].groupId;
    return self.appData.sensors[groupId].count;
}

- (nullable NSString *)imageNameForSensor:(nonnull Sensor *)sensor {
    if ([sensor.resources isKindOfClass:[IPSOBarometerInstance class]]) {
        return @"PressureSensor";
    } else if ([sensor.resources isKindOfClass:[IPSOConcentrationInstance class]]) {
        if ([sensor.resources.applicationType isEqualToString:@"CO-Concentration"]) {
            return @"COSensor";
//        } else if ([sensor.resources.applicationType isEqualToString:@"Air-Quality"]) {//FIXME:missing image for Air Quality
        }
    } else if ([sensor.resources isKindOfClass:[IPSOHumidityInstance class]]) {
        return @"HumiditySensor";
    } else if ([sensor.resources isKindOfClass:[IPSOPowerInstance class]] ||
               [sensor.resources isKindOfClass:[IPSODistanceInstance class]]) {
        return @"LightningSensor";
    } else if ([sensor.resources isKindOfClass:[IPSOTemperatureInstance class]]) {
        return @"TemperatureSensor";
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WeatherCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SensorCell" forIndexPath:indexPath];
    
    Sensor *sensor = [self sensorForIndexPath:indexPath];
    cell.empty = [sensor isEmpty];
    if (![sensor isEmpty]) {
        cell.valueLabel.text = [NSString stringWithFormat:@"%@%@", sensor.resources.value, sensor.resources.unit];
        cell.minValueLabel.text = [NSString stringWithFormat:@"%@", sensor.resources.minMeasuredValue];
        cell.maxValueLabel.text = [NSString stringWithFormat:@"%@", sensor.resources.maxMeasuredValue];
        cell.sensorImageView.image = [UIImage imageNamed:[self imageNameForSensor:sensor]];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self.appData moveSensorAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        WeatherSectionHeaderView *sectionHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WeatherSectionHeader" forIndexPath:indexPath];
        sectionHeader.sectionNameLabel.text = self.appData.groups[indexPath.section].name;
        return sectionHeader;
    } else {
        return nil;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    WeatherCollectionCell *cell = (WeatherCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    return !cell.empty;
}

#pragma mark - Private

- (Sensor *)sensorForIndexPath:(NSIndexPath *)indexPath {
    return self.appData.sensors[self.appData.groups[indexPath.section].groupId][indexPath.item];
}

@end

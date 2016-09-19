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

#import "DataApi.h"
#import <CreatorKit/CreatorKit.h>

@interface DataApi ()
@property(nonatomic, strong, nonnull) DeviceServerApi *deviceServerApi;
@property(nonatomic, strong, nonnull) NSOperationQueue *networkQueue;
@property(nonatomic, readonly, nonnull) NSArray<Class> *knownObjects;
@property(nonatomic, strong, nonnull) NSArray<NSString *> *knownObjectIds;
@end

@implementation DataApi

- (nullable instancetype) initWithDeviceServerApi:(nonnull DeviceServerApi *)deviceServerApi {
    self = [super init];
    if (self) {
        _deviceServerApi = deviceServerApi;
    }
    return self;
}

- (NSOperationQueue *)networkQueue {
    if (_networkQueue == nil) {
        _networkQueue = [NSOperationQueue new];
        _networkQueue.name = @"DatApi network queue";
        _networkQueue.maxConcurrentOperationCount = 3;
    }
    return _networkQueue;
}

- (void)requestSensorsWithSuccess:(nullable RequestSensorsSuccessBlock)success
                          failure:(nullable CreatorFailureBlock)failure
{
    __weak typeof(self) weakSelf = self;
    [self.networkQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        void (^failureBlock)(NSError *error) = ^(NSError *error) {
            if (failure) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failure(error);
                }];
            }
        };
        
        // Get clients
        Clients *clients = [weakSelf.deviceServerApi clientsWithError:&error];
        if (error || clients == nil) {
            failureBlock(error);
            return;
        }
        
        // Filter clients by name
        NSMutableArray<Client *> *newItems = [NSMutableArray new];
        for (Client *client in clients.items) {
            if ([client.name.lowercaseString hasPrefix:@"weatherstation"]) {
                [newItems addObject:client];
            }
        }
        
        if (clients.items.count != newItems.count) {
            clients.items = [newItems copy];
            clients.pageInfo = nil;
        }
        
        NSMutableArray *results = [NSMutableArray new];
        
        for (Client *client in clients.items) {
            error = nil;
            ObjectTypes *objectTypes = [weakSelf.deviceServerApi objectTypesForClient:client error:&error];
            if (error || objectTypes == nil) {
                failureBlock(error);
                return;
            }
            
            IPSODevice *device = nil;
            NSPredicate *deviceObjectTypePredicate = [NSPredicate predicateWithFormat:@"%K = %@", @"objectTypeID", [[IPSODevice class] IPSOObjectID]];
            ObjectType *deviceObjectType = [objectTypes.items filteredArrayUsingPredicate:deviceObjectTypePredicate].firstObject;
            if (deviceObjectType != nil) {
                Instances *instances = [weakSelf.deviceServerApi objectInstancesForObjectType:deviceObjectType error:&error];
                if (error || instances == nil) {
                    failureBlock(error);
                    return;
                }
                if (instances.items.firstObject.json != nil) {
                    device = [[IPSODevice alloc] initWithJson:instances.items.firstObject.json];
                }
            }
            
            for (ObjectType *objectType in objectTypes.items) {
                if (NSNotFound != [weakSelf.knownObjectIds indexOfObject:objectType.objectTypeID]) {
                    error = nil;
                    Instances *instances = [weakSelf.deviceServerApi objectInstancesForObjectType:objectType error:&error];
                    if (error || instances == nil) {
                        failureBlock(error);
                        return;
                    }
                    
                    for (IPSOInstance *instance in instances.items) {
                        id sensor = [weakSelf sensorFromIPSOInstanceJson:instance.json objectType:objectType clientSerialNumber:device.serialNumber error:&error];
                        if (sensor) {
                            [results addObject:sensor];
                        } else {
                            failureBlock(error);
                            return;
                        }
                    }
                }
            }
        }
        
        if (success) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                success(results);
            }];
        }
    }]];
}

#pragma mark - Private

- (NSArray<Class> *)knownObjects {
    return @[[IPSOBarometerInstance class], [IPSOConcentrationInstance class], [IPSODistanceInstance class], [IPSOHumidityInstance class], [IPSOPowerInstance class], [IPSOTemperatureInstance class]];
}

- (NSArray<NSString *> *)knownObjectIds {
    if (_knownObjectIds == nil) {
        NSMutableArray<NSString *> *knownObjectIds = [[NSMutableArray alloc] initWithCapacity:self.knownObjects.count];
        for (Class knownObject in self.knownObjects) {
            if ([knownObject conformsToProtocol:@protocol(IPSOObjectIdProtocol)]) {
                [knownObjectIds addObject:[knownObject IPSOObjectID]];
            } else {
                NSLog(@"WARNING: Object in knownObjectIds should conform to IPSOObjectIdProtocol.");
            }
        }
        _knownObjectIds = [knownObjectIds copy];
    }
    return _knownObjectIds;
}

- (nullable Sensor *)sensorFromIPSOInstanceJson:(id)json
                                     objectType:(ObjectType *)objectType
                             clientSerialNumber:(NSString *)clientSerialNumber
                                          error:(NSError **)error
{
    __block Class InstanceType = nil;
    [self.knownObjects enumerateObjectsUsingBlock:^(Class  _Nonnull class, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([objectType.objectTypeID isEqualToString:[class IPSOObjectID]]) {
            InstanceType = class;
            *stop = YES;
        }
    }];
    
    if (NO == [InstanceType conformsToProtocol:@protocol(JsonInit)]) {
        *error = [NSError errorWithDomain:@"io.creatordev.Weather.app" code:0 userInfo:@{@"description": @"Object in knownObjectIds should conform to IPSOObjectIdProtocol."}];
        return nil;
    }
    
    id typedInstance = [[InstanceType alloc] initWithJson:json];
    
    NSNumber *instanceId = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDict = (NSDictionary *)json;
        instanceId = jsonDict[@"InstanceID"];
    }
    if (instanceId == nil) {
        *error = [NSError errorWithDomain:@"io.creatordev.Weather.app" code:0 userInfo:@{@"description": @"InstanceID not present in IPSO object."}];
        return nil;
    }
    
    return [[Sensor alloc] initWithClientSerialNumber:clientSerialNumber objectType:objectType instanceId:instanceId resources:typedInstance dependentSensors:nil];
}

@end

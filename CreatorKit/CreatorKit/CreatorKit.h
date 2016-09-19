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

//! Project version number for CreatorKit.
FOUNDATION_EXPORT double CreatorKitVersionNumber;

//! Project version string for CreatorKit.
FOUNDATION_EXPORT const unsigned char CreatorKitVersionString[];

#import <CreatorKit/LoginDelegate.h>
#import <CreatorKit/OpenUrlProtocol.h>
#import <CreatorKit/Typedefs.h>
#import <CreatorKit/GlobalStyle.h>

#import <CreatorKit/ResourceSerializationData.h>
#import <CreatorKit/Api.h>
#import <CreatorKit/AccessKey.h>
#import <CreatorKit/Client.h>
#import <CreatorKit/Clients.h>
#import <CreatorKit/Hateoas.h>
#import <CreatorKit/Instances.h>
#import <CreatorKit/IPSOBaseSensorInstance.h>
#import <CreatorKit/IPSOBarometerInstance.h>
#import <CreatorKit/IPSOConcentrationInstance.h>
#import <CreatorKit/IPSODevice.h>
#import <CreatorKit/IPSODigitalOutputInstance.h>
#import <CreatorKit/IPSODistanceInstance.h>
#import <CreatorKit/IPSOHumidityInstance.h>
#import <CreatorKit/IPSOInstance.h>
#import <CreatorKit/IPSOObjectIdProtocol.h>
#import <CreatorKit/IPSOPowerInstance.h>
#import <CreatorKit/IPSOTemperatureInstance.h>
#import <CreatorKit/JsonInit.h>
#import <CreatorKit/Link.h>
#import <CreatorKit/OauthToken.h>
#import <CreatorKit/ObjectType.h>
#import <CreatorKit/ObjectTypes.h>
#import <CreatorKit/PageInfo.h>

#import <CreatorKit/BaseRequest.h>
#import <CreatorKit/GETRequest.h>
#import <CreatorKit/POSTRequest.h>
#import <CreatorKit/PUTRequest.h>

#import <CreatorKit/DeviceServerApi.h>
#import <CreatorKit/LoginApi.h>

#import <CreatorKit/CreatorButton.h>
#import <CreatorKit/CreatorLinkButton.h>
#import <CreatorKit/CreatorSwitch.h>

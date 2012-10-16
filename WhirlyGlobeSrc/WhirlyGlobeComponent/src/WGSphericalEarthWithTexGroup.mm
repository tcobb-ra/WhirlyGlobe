/*
 *  WGSphericalEarthWithTexGroup.mm
 *  WhirlyGlobeComponent
 *
 *  Created by Steve Gifford on 7/21/12.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "WGSphericalEarthWithTexGroup.h"
#import <WhirlyGlobe.h>

using namespace Eigen;
using namespace WhirlyKit;
using namespace WhirlyGlobe;

@interface WGSphericalEarthWithTexGroup ()
@property WhirlyKitTextureGroup *textureGroup;
@end

@implementation WGSphericalEarthWithTexGroup

- (id)initWithTextureGroupName:(NSString *)textureGroupName
{
    if(self = [super init])
    {
        NSString *infoPath = [[NSBundle mainBundle] pathForResource:textureGroupName ofType:@"plist"];
        self.textureGroup = [[WhirlyKitTextureGroup alloc] initWithInfo:infoPath];
        if(!self.textureGroup)
            return nil;
        self.mainLayer = [[WhirlyGlobeSphericalEarthLayer alloc] initWithTexGroup:self.textureGroup];
    }
    return self;
}

- (WhirlyGlobeSphericalEarthLayer *)earthLayer
{
    return (WhirlyGlobeSphericalEarthLayer *)self.mainLayer;
}

@end
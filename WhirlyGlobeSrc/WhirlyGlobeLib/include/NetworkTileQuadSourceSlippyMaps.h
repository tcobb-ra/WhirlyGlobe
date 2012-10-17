/*
 *  NetworkTileQuadSourceSlippyMaps.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/11/12.
 *  Copyright 2011-2012 mousebird consulting
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

#import "NetworkTileQuadSource.h"

// This implements a tile source for the SlippyMaps image hiearachy.
@interface WhirlyGlobeNetworkTileQuadSourceSlippyMaps : WhirlyGlobeNetworkTileQuadSource
{
    /// Where we're fetching from
    NSString *baseURL;
}

/// Initialize with the base URL and image extension (e.g. png, jpg)
- (id)initWithBaseURL:(NSString *)base ext:(NSString *)imageExt;

@end

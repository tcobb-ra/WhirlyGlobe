/*
 *  NetworkTileQuadSource.h
 *  WhirlyGlobeLib
 *
 *  Created by Ty Cobb on 5/11/12.
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

@interface WhirlyGlobeNetworkTileQuadSourceMetadata : WhirlyGlobeNetworkTileQuadSource <WhirlyGlobeDelegatedNetworkTileQuadSource>

@property (weak, nonatomic) id<WGNetworkTileMetadataDelegate> delegate;

- (id)initWithMetadataURL:(NSString *)metadataURL andImageExtension:(NSString *)imageExtension;

@end

/*
 *  WGViewControllerLayer_private.h
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

#import <Foundation/Foundation.h>
//#import <WhirlyGlobe.h>

/// Used to keep track of resources for a layer the user has asked to be created.
/// Don't mess with these directly.

@protocol WhirlyKitLayer;
@class WhirlyKitLayerThread;
@class WhirlyKitSceneRendererES1;

@interface WGViewControllerLayer : NSObject

@property (strong, nonatomic) NSObject<WhirlyKitLayer> *mainLayer;

- (void)startOnLayerThread:(WhirlyKitLayerThread *)layerThread withRenderer:(WhirlyKitSceneRendererES1 *)renderer;
    // withScene:(WhirlyGlobe::GlobeScene *)globeScene
               
- (void)removeLayerFromThread:(WhirlyKitLayerThread *)layerThread;
    // andScene:(WhirlyGlobe::GlobeScene *)globeScene;

@end

@protocol WGCacheableLayer <NSObject>
- (NSString *)cacheDirectory;
- (void)setCacheDirectory:(NSString *)cacheDirectory;
@end


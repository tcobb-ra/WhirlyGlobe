/*
 *  NetworkTileQuadSourceSlippyMaps.mm
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

#import "NetworkTileQuadSourceSlippyMaps.h"

using namespace WhirlyKit;
using namespace WhirlyGlobe;

@implementation WhirlyGlobeNetworkTileQuadSourceSlippyMaps

- (id)initWithBaseURL:(NSString *)base ext:(NSString *)imageExt
{
    if(self = [super initWithImageExtension:imageExt])
        baseURL = base;
    return self;
}

// Start loading a given tile
- (void)quadTileLoader:(WhirlyGlobeQuadTileLoader *)quadLoader startFetchForLevel:(int)level col:(int)col row:(int)row
{
    int y = ((int)(1<<level)-row)-1;
    
    // Let's just do this in a block
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
                   ^{
                       NSData *imgData;
                       
                       // Look for it in the local cache first
                       NSString *localName = nil;
                       if (cacheDir)
                       {
                           localName = [NSString stringWithFormat:@"%@/%d_%d_%d.%@",cacheDir,level,col,y,ext];
                           
                           if ([[NSFileManager defaultManager] fileExistsAtPath:localName])
                           {
                               imgData = [NSData dataWithContentsOfFile:localName];
                           }
                       }

                       if (!imgData)
                       {
                           NSString *fullURLStr = [NSString stringWithFormat:@"%@%d/%d/%d.%@",baseURL,level,col,y,ext];
                           NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURLStr]];
                                            
                           // Fetch the image synchronously
                           NSURLResponse *resp = nil;
                           NSError *error = nil;
                           imgData = [NSURLConnection sendSynchronousRequest:urlReq returningResponse:&resp error:&error];
                           
                           if (error || !imgData)
                               imgData = nil;

                           // Save to the cache
                           if (imgData && localName)
                               [imgData writeToFile:localName atomically:YES];
                       }
                       
                       // Let the loader know what's up
                       NSArray *args = [NSArray arrayWithObjects:quadLoader, (imgData ? imgData : [NSNull null]), 
                                        [NSNumber numberWithInt:level], [NSNumber numberWithInt:col], [NSNumber numberWithInt:row], nil];
                       [self performSelector:@selector(tileUpdate:) onThread:quadLoader.quadLayer.layerThread withObject:args waitUntilDone:NO];
                       imgData = nil;
                   });
}

@end

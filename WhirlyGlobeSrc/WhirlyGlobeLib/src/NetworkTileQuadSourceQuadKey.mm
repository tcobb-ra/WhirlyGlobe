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

#import "NetworkTileQuadSourceQuadKey.h"

@implementation WhirlyGlobeNetworkTileQuadSourceQuadKey

- (id)initWithMetadataURL:(NSString *)metadataURL andImageExtension:(NSString *)imageExtension andImageURLBuilder:(WGImageURLBuilder)imageURLBuilder
{
    if(self = [super initWithImageExtenstion:imageExtension])
    {
        self.metadataURL = metadataURL;
        self.imageURLBuilder = imageURLBuilder;
    }
    return self;
}

- (void)quadTileLoader:(WhirlyGlobeQuadTileLoader *)quadLoader startFetchForLevel:(int)level col:(int)col row:(int)row withQuadKey:(NSString *)quadKey
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *metadataData, *imageData;
        
        NSString *localName = nil;
        if (cacheDir)
        {
            localName = [NSString stringWithFormat:@"%@/%@.%@",cacheDir,quadKey,ext];
            if([[NSFileManager defaultManager] fileExistsAtPath:localName])
                imageData = [NSData dataWithContentsOfFile:localName];
        }

        if (!imageData)
        {
            NSURLRequest *metadataRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.metadataURL]];

            NSURLResponse *response = nil;
            NSError *error = nil;
            metadataData = [NSURLConnection sendSynchronousRequest:metadataRequest
                                                  returningResponse:&response
                                                              error:&error];
            
            if(error || !metadataData) // not sure if that last condition does anything
                metadataData = nil;

            if(metadataData)
            {
                NSURLRequest *imageRequest = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:self.imageURLBuilder(metadataData, quadKey)]];
                imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];
                
                if(error || !imageData)
                    imageData = nil;
                
                if(!imageData)
                    [imageData writeToFile:localName atomically:YES];
            }
        }

        // Let the loader know what's up
        NSArray *args = @[ quadLoader, imageData ?: [NSNull null], @(level), @(col), @(row) ];
        [self performSelector:@selector(tileUpdate:) onThread:quadLoader.quadLayer.layerThread withObject:args waitUntilDone:NO];
        imageData = nil;
    });
}

@end

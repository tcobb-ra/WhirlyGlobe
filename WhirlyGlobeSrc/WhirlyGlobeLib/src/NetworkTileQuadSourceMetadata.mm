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

#import "NetworkTileQuadSourceMetadata.h"

@interface WhirlyGlobeNetworkTileQuadSourceMetadata ()

@property (strong, nonatomic) NSString *metadataURL;
@property (strong, nonatomic) NSDictionary *metadataDictionary;
@property (assign, nonatomic) WGNetworkTileQuadSourceParameter delegateParameters;

@end


@implementation WhirlyGlobeNetworkTileQuadSourceMetadata

- (id)initWithMetadataURL:(NSString *)metadataURL andImageExtension:(NSString *)imageExtension
{
    if(self = [super initWithImageExtension:imageExtension])
        self.metadataURL = metadataURL;
    return self;
}

- (void)quadTileLoader:(WhirlyGlobeQuadTileLoader *)quadLoader startFetchForLevel:(int)level col:(int)col row:(int)row withQuadKey:(NSString *)quadKey
{
//    int y = ((int)(1<<level)-row)-1; // might need this?
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData;
        
        NSString *localName = nil;
        if (cacheDir)
        {
            localName = [NSString stringWithFormat:@"%@/%@.%@",cacheDir,quadKey,ext];
            if([[NSFileManager defaultManager] fileExistsAtPath:localName])
                imageData = [NSData dataWithContentsOfFile:localName];
        }

        if (!imageData)
        {
            NSDictionary *localMetadataDictionary = [self fetchMetadataDictionary];
            if(localMetadataDictionary)
            {
                NSString *imageURLString;
                switch(self.delegateParameters)
                {
                    case WGNetworkTileQuadSourceParameterQuadKey:
                        imageURLString = [self.delegate imageURLForMetadata:localMetadataDictionary quadKey:quadKey]; break;
                    case WGNetworkTileQuadSourceParameterSlippyMaps:
                        imageURLString = [self.delegate imageURLForMetadata:localMetadataDictionary slippyMapsTileInfo:WGSlippyMapsTileInfoMake(level, col, row)]; break;
                    case WGNetworkTileQuadSourceParameterQuadKey | WGNetworkTileQuadSourceParameterSlippyMaps:
                        imageURLString = [self.delegate imageURLForMetadata:localMetadataDictionary slippyMapsTileInfo:WGSlippyMapsTileInfoMake(level, col, row) quadKey:quadKey]; break;
                }
                
                NSURLResponse *response = nil; NSError *error = nil;
                NSURLRequest *imageRequest = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:imageURLString]];
                imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];
                
                if(error || !imageData)
                    imageData = nil;
                
                if(imageData)
                    [imageData writeToFile:localName atomically:YES];
            }
        }

        // Let the loader know what's up
        NSArray *args = @[ quadLoader, imageData ?: [NSNull null], @(level), @(col), @(row) ];
        [self performSelector:@selector(tileUpdate:) onThread:quadLoader.quadLayer.layerThread withObject:args waitUntilDone:NO];
        imageData = nil;
    });
}

- (NSDictionary *)fetchMetadataDictionary
{
    NSDictionary *localMetadataDictionary;
    if(!self.metadataDictionary)
    {
        NSData *metadataData = [self fetchMetadataData];
        if(metadataData)
        {
            localMetadataDictionary = [self.delegate parsedMetadataForData:metadataData];
            if([self.delegate shouldCacheParsedMetadata])
                self.metadataDictionary = localMetadataDictionary;
        }
    }
    else
    {
        localMetadataDictionary = self.metadataDictionary;
    }
    
    return localMetadataDictionary;
}

- (NSData *)fetchMetadataData
{
    NSURLRequest *metadataRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.metadataURL]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *metadataData = [NSURLConnection sendSynchronousRequest:metadataRequest
                                         returningResponse:&response
                                                     error:&error];
    return (error) ? nil : metadataData;
}
            
- (void)setDelegate:(id<WGNetworkTileMetadataDelegate>)delegate
{
    _delegate = delegate;
    self.delegateParameters = [delegate networkTileURLParametersRequired];
}

@end

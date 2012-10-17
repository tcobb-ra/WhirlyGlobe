//
//  NetworkTileQuadSourceExternal.m
//  WhirlyGlobeLib
//
//  Created by tcobb on 10/17/12.
//
//

#import "NetworkTileQuadSourceExternal.h"

@interface WhirlyGlobeNetworkTileQuadSourceExternal ()
@property (assign, nonatomic) WGNetworkTileQuadSourceParameter delegateParameters;
@end

@implementation WhirlyGlobeNetworkTileQuadSourceExternal

- (void)quadTileLoader:(WhirlyGlobeQuadTileLoader *)quadLoader startFetchForLevel:(int)level col:(int)col row:(int)row quadKey:(NSString *)quadKey
{
    NSData *imageData;
    switch(self.delegateParameters)
    {
        case WGNetworkTileQuadSourceParameterQuadKey:
            imageData = [self.delegate tileImageDataForQuadKey:quadKey]; break;
        case WGNetworkTileQuadSourceParameterSlippyMaps:
            imageData = [self.delegate tileImageDataForSlippyMapsTileInfo:WGSlippyMapsTileInfoMake(level, col, row)]; break;
        case WGNetworkTileQuadSourceParameterQuadKey | WGNetworkTileQuadSourceParameterSlippyMaps:
            imageData = [self.delegate tileImageDataForSlippyMapsTileInfo:WGSlippyMapsTileInfoMake(level, col, row) quadKey:quadKey]; break;
    }
    
    NSArray *args = @[ quadLoader, imageData ?: [NSNull null], @(level), @(col), @(row) ];
    [self performSelector:@selector(tileUpdate:) onThread:quadLoader.quadLayer.layerThread withObject:args waitUntilDone:NO];
    imageData = nil;
}

- (void)setDelegate:(id<WGNetworkTileExternalDelegate>)delegate
{
    _delegate = delegate;
    self.delegateParameters = [delegate networkTileURLParametersRequired];
}

@end

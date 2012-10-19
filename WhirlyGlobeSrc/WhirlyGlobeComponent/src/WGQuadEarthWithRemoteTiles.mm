//
//  WGQuadEarthWithRemoteTiles.mm
//  WhirlyGlobeComponent
//
//  Created by Steve Gifford on 7/24/12.
//  Copyright (c) 2012 mousebird consulting. All rights reserved.
//


#import "WGQuadEarthWithRemoteTiles.h"
#import <WhirlyGlobe.h>

@interface WGQuadEarthWithRemoteTiles ()

@property (strong, nonatomic) WhirlyGlobeQuadTileLoader *tileLoader;
@property (strong, nonatomic) WhirlyGlobeNetworkTileQuadSource *dataSource;

@end

@implementation WGQuadEarthWithRemoteTiles

- (id)initWithBaseURL:(NSString *)baseURL imageExtension:(NSString *)ext zoomRange:(NSRange)zoomRange
{
    if(self = [super initWithZoomRange:zoomRange])
    {
        self.dataSource = [[WhirlyGlobeNetworkTileQuadSourceSlippyMaps alloc] initWithBaseURL:baseURL ext:ext];
        [self configureDataSource:self.dataSource withZoomRange:zoomRange];
    }
    return self;
}

- (id)initWithMetadataURL:(NSString *)metadataURL imageExtension:(NSString *)imageExtension zoomRange:(NSRange)zoomRange
{
    if(self = [super initWithZoomRange:zoomRange])
    {
        self.dataSource = [[WhirlyGlobeNetworkTileQuadSourceMetadata alloc] initWithMetadataURL:metadataURL andImageExtension:imageExtension];
        [self configureDataSource:self.dataSource withZoomRange:zoomRange];
        self.tileLoader = [[WhirlyGlobeQuadTileLoader alloc] initWithDataSource:self.dataSource];
        self.tileLoader.coverPoles = true;
    }
    return self;
}

- (void)configureDataSource:(WhirlyGlobeNetworkTileQuadSource *)dataSource withZoomRange:(NSRange)zoomRange
{
    dataSource.minZoom = zoomRange.location;
    dataSource.maxZoom = zoomRange.location + zoomRange.length;
    dataSource.numSimultaneous = 8;
}

- (void)startOnLayerThread:(WhirlyKitLayerThread *)layerThread withRenderer:(WhirlyKitSceneRendererES1 *)renderer
{
    self.tileLoader.ignoreEdgeMatching = !renderer.zBuffer;
    self.mainLayer = [[WhirlyGlobeQuadDisplayLayer alloc] initWithDataSource:self.dataSource loader:self.tileLoader renderer:renderer];
    [super startOnLayerThread:layerThread withRenderer:renderer];
}

- (NSString *)cacheDirectory
{
    return self.dataSource.cacheDir;
}

- (void)setCacheDirectory:(NSString *)cacheDirectory
{
    self.dataSource.cacheDir = cacheDirectory;
}

- (void)setNetworkDelegate:(id<WGNetworkTileDelegate>)delegate
{
    if([self.dataSource conformsToProtocol:@protocol(WhirlyGlobeDelegatedNetworkTileQuadSource)])
        [(id<WhirlyGlobeDelegatedNetworkTileQuadSource>)self.dataSource setDelegate:delegate];
}

@end


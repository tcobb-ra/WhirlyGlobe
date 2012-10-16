//
//  WGQuadEarthWithMBTiles.m
//  WhirlyGlobeComponent
//
//  Created by Steve Gifford on 7/24/12.
//  Copyright (c) 2012 mousebird consulting. All rights reserved.
//

#import "WGQuadEarthWithMBTiles.h"
#import <WhirlyGlobe.h>

@interface WGQuadEarthWithMBTiles ()

@property (strong, nonatomic) WhirlyGlobeQuadTileLoader *tileLoader;
@property (strong, nonatomic) WhirlyMBTileQuadSource *dataSource;

@end

@implementation WGQuadEarthWithMBTiles

- (id)initWithMBTilesArchiveName:(NSString *)archiveName
{
    if(self = [super init])
    {
        NSString *infoPath = [[NSBundle mainBundle] pathForResource:archiveName ofType:@"mbtiles"];
        if (!infoPath)
            return nil;
        self.dataSource = [[WhirlyMBTileQuadSource alloc] initWithPath:infoPath];
        self.tileLoader = [[WhirlyGlobeQuadTileLoader alloc] initWithDataSource:self.dataSource];
        self.tileLoader.coverPoles = true;
    }
    return self;
}

- (void)startOnLayerThread:(WhirlyKitLayerThread *)layerThread withRenderer:(WhirlyKitSceneRendererES1 *)renderer
{
    self.mainLayer = [[WhirlyGlobeQuadDisplayLayer alloc] initWithDataSource:self.dataSource loader:self.tileLoader renderer:renderer];
    self.tileLoader.ignoreEdgeMatching = !renderer.zBuffer;
    [super startOnLayerThread:layerThread withRenderer:renderer];
}

@end


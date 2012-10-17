//
//  NetworkTileQuadSource.mm
//  WhirlyGlobeLib
//
//  Created by tcobb on 10/15/12.
//
//

#import "NetworkTileQuadSource.h"
#import "GlobeLayerViewWatcher.h"

using namespace WhirlyKit;
using namespace WhirlyGlobe;

@implementation WhirlyGlobeNetworkTileQuadSource

@synthesize numSimultaneous;
@synthesize cacheDir;

- (id)initWithImageExtension:(NSString *)imageExtension
{
    if(self = [super init])
    {
        ext = imageExtension;

        coordSys = new SphericalMercatorCoordSystem();
        
        GeoCoord ll = GeoCoord::CoordFromDegrees(-180,-85);
        GeoCoord ur = GeoCoord::CoordFromDegrees( 180, 85);
        Point3f ll3d = coordSys->geographicToLocal(ll);
        Point3f ur3d = coordSys->geographicToLocal(ur);
        mbr.ll() = Point2f(ll3d.x(),ll3d.y());
        mbr.ur() = Point2f(ur3d.x(),ur3d.y());
        
        numSimultaneous = 1;
        
        pixelsPerTile = 256;
    }
    
    return self;
}

- (void)dealloc
{
    if (coordSys)
        delete coordSys;
    coordSys = nil;
}

- (void)shutdown
{
    // Nothing much to do here
}

- (CoordSystem *)coordSystem
{
    return coordSys;
}

- (Mbr)totalExtents
{
    return mbr;
}

- (Mbr)validExtents
{
    return mbr;
}

- (int)minZoom
{
    return minZoom;
}

- (void)setMinZoom:(int)zoom
{
    minZoom = zoom;
}

- (int)maxZoom
{
    return maxZoom;
}

- (void)setMaxZoom:(int)zoom
{
    maxZoom = zoom;
}

- (float)importanceForTile:(WhirlyKit::Quadtree::Identifier)ident mbr:(WhirlyKit::Mbr)tileMbr viewInfo:(WhirlyGlobeViewState *)viewState frameSize:(WhirlyKit::Point2f)frameSize
{
    // Everything at the top is loaded in, so be careful
    if (ident.level == minZoom)
        return MAXFLOAT;
    
    // For the rest,
    return ScreenImportance(viewState, frameSize, viewState->eyeVec, pixelsPerTile, coordSys, tileMbr);
}

- (int)maxSimultaneousFetches
{
    return numSimultaneous;
}

// Merge the tile into the quad layer
// We're in the layer thread here
- (void)tileUpdate:(NSArray *)args
{
    WhirlyGlobeQuadTileLoader *loader = [args objectAtIndex:0];
    NSData *imgData = [args objectAtIndex:1];
    int level = [[args objectAtIndex:2] intValue];
    int x = [[args objectAtIndex:3] intValue];
    int y = [[args objectAtIndex:4] intValue];
    
    if (imgData && [imgData isKindOfClass:[NSData class]])
        [loader dataSource:self loadedImage:imgData pvrtcSize:0 forLevel:level col:x row:y];
    else {
        [loader dataSource:self loadedImage:nil pvrtcSize:0 forLevel:level col:x row:y];
    }
}

@end

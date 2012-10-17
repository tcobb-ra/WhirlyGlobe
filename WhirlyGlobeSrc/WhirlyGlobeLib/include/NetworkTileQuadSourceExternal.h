//
//  NetworkTileQuadSourceExternal.h
//  WhirlyGlobeLib
//
//  Created by tcobb on 10/17/12.
//
//

#import "NetworkTileQuadSource.h"

// designated initializer: -initWithImageExtenstion:
@interface WhirlyGlobeNetworkTileQuadSourceExternal : WhirlyGlobeNetworkTileQuadSource <WhirlyGlobeDelegatedNetworkTileQuadSource>

@property (weak, nonatomic) id<WGNetworkTileExternalDelegate> delegate;

@end

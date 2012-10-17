//
//  NetworkTileQuadSourceDelegate.h
//  WhirlyGlobeLib
//
//  Created by tcobb on 10/17/12.
//
//

#import <Foundation/Foundation.h>

typedef struct {
    NSUInteger level;
    NSUInteger column;
    NSUInteger row;
} WGSlippyMapsTileInfo;

NS_INLINE WGSlippyMapsTileInfo WGSlippyMapsTileInfoMake(NSUInteger level, NSUInteger column, NSUInteger row)
{
    WGSlippyMapsTileInfo tileInfo;
    tileInfo.level = level;
    tileInfo.column = column;
    tileInfo.row = row;
    return tileInfo;
}

typedef NS_ENUM(NSUInteger, WGNetworkTileQuadSourceParameter) {
    WGNetworkTileQuadSourceParameterSlippyMaps = 1 << 0,
    WGNetworkTileQuadSourceParameterQuadKey = 1 << 1
};

// Base delegate
@protocol WGNetworkTileDelegate <NSObject>

- (WGNetworkTileQuadSourceParameter)networkTileURLParametersRequired;

@end

// WhirlyGlobeNetworkTileQuadSourceMetadata delegate
@protocol WGNetworkTileMetadataDelegate <WGNetworkTileDelegate>

- (BOOL)shouldCacheParsedMetadata;
- (NSDictionary *)parsedMetadataForData:(NSData *)data;

@optional
- (NSString *)imageURLForMetadata:(NSDictionary *)metadata quadKey:(NSString *)quadKey;
- (NSString *)imageURLForMetadata:(NSDictionary *)metadata slippyMapsTileInfo:(WGSlippyMapsTileInfo)tileInfo;
- (NSString *)imageURLForMetadata:(NSDictionary *)metadata slippyMapsTileInfo:(WGSlippyMapsTileInfo)tileInfo quadKey:(NSString *)quadKey;

@end

// WhirlyGlobeNetworkTileQuadSourceExternal delegate
@protocol WGNetworkTileExternalDelegate <WGNetworkTileDelegate>

@optional
- (NSData *)tileImageDataForQuadKey:(NSString *)quadKey;
- (NSData *)tileImageDataForSlippyMapsTileInfo:(WGSlippyMapsTileInfo)tileInfo;
- (NSData *)tileImageDataForSlippyMapsTileInfo:(WGSlippyMapsTileInfo)tileInfo quadKey:(NSString *)quadKey;

@end

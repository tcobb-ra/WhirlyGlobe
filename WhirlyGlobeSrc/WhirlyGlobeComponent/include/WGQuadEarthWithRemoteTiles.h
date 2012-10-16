//
//  WGQuadEarthWithRemoteTiles.h
//  WhirlyGlobeComponent
//
//  Created by Steve Gifford on 7/24/12.
//  Copyright (c) 2012 mousebird consulting. All rights reserved.
//

#import "WGViewControllerLayer.h"

@interface WGQuadEarthWithRemoteTiles : WGViewControllerLayer <WGCacheableLayer>

- (id)initWithBaseURL:(NSString *)baseURL imageExtension:(NSString *)ext zoomRange:(NSRange)zoomRange;

- (id)initWithMetadataURL:(NSString *)metadataURL imageExtension:(NSString *)imageExtension zoomRange:(NSRange)zoomRange imageURLBuilder:(NSString *(^)(NSData *metadataData, NSString *quadKey))imageURLBuilder;

@end

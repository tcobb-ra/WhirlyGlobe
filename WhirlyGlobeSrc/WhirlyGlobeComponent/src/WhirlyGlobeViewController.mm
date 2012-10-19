/*
 *  WhirlyGlobeViewController.mm
 *  WhirlyGlobeComponent
 *
 *  Created by Steve Gifford on 7/21/12.
 *  Copyright 2011 mousebird consulting
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

#import <WhirlyGlobe.h>
#import "WhirlyGlobeViewController.h"
#import "WGViewControllerLayer.h"
#import "WGComponentObject_private.h"
#import "WGInteractionLayer_private.h"
#import "PanDelegateFixed.h"
#import "PinchDelegateFixed.h"
#import "WhirlyGlobeViewControllerLayer.h"

using namespace Eigen;
using namespace WhirlyKit;
using namespace WhirlyGlobe;

@interface WhirlyGlobeViewController() <WGInteractionLayerDelegate>
@end

@implementation WhirlyGlobeViewController
{    
    WhirlyKitEAGLView *glView;
    WhirlyKitSceneRendererES1 *sceneRenderer;
    
    WhirlyGlobe::GlobeScene *globeScene;
    WhirlyGlobeView *globeView;
    
    WhirlyKitLayerThread *layerThread;
    
    // The standard set of layers we create
    WhirlyKitMarkerLayer *markerLayer;
    WhirlyKitLabelLayer *labelLayer;
    WhirlyKitVectorLayer *vectorLayer;
    WhirlyKitSelectionLayer *selectLayer;
    
    // Our own interaction layer does most of the work
    WGInteractionLayer *interactLayer;
    
    // Layers (and associated data) created for the user
    NSMutableArray *userLayers;

    // Gesture recognizers
    WGPinchDelegateFixed *pinchDelegate;
    PanDelegateFixed *panDelegate;
    WhirlyGlobeTapDelegate *tapDelegate;
    WhirlyGlobeRotateDelegate *rotateDelegate;    
    AnimateViewRotation *animateRotation;
    
    // List of views we're tracking for location
    NSMutableArray *viewTrackers;
    
    // If set we'll look for selectables
    bool selection;
    
    // General rendering and other display hints
    NSDictionary *hints;
    
    // Default description dictionaries for the various data types
    NSDictionary *screenMarkerDesc,*markerDesc,*screenLabelDesc,*labelDesc,*vectorDesc;
    
    // Clear color we're using
    UIColor *theClearColor;
}

@synthesize delegate;
@synthesize selection;

// Tear down layers and layer thread
- (void) clear
{
    [glView stopAnimation];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (layerThread)
    {
        [layerThread addThingToDelete:globeScene];
        [layerThread addThingToRelease:layerThread];
        [layerThread cancel];
    }
    globeScene = NULL;
    
    glView = nil;
    sceneRenderer = nil;

    globeView = nil;
    layerThread = nil;
    
    markerLayer = nil;
    labelLayer = nil;
    vectorLayer = nil;
    selectLayer = nil;

    while ([userLayers count] > 0)
    {
        WGViewControllerLayer *layer = [userLayers objectAtIndex:0];
        [userLayers removeObject:layer];
    }
    userLayers = nil;
    
    pinchDelegate = nil;
    panDelegate = nil;
    tapDelegate = nil;
    rotateDelegate = nil;
    animateRotation = nil;
    
    viewTrackers = nil;
    
    theClearColor = nil;
}

- (void) dealloc
{
    [self clear];
}

// Put together all the random junk we need to draw
- (void) loadSetup
{
    userLayers = [NSMutableArray array];
    
	// Set up an OpenGL ES view and renderer
	glView = [[WhirlyKitEAGLView alloc] init];
	sceneRenderer = [[WhirlyKitSceneRendererES1 alloc] init];
    theClearColor = [UIColor blackColor];
    [sceneRenderer setClearColor:theClearColor];
	glView.renderer = sceneRenderer;
	glView.frameInterval = 2;  // 60 fps
    [self.view insertSubview:glView atIndex:0];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.opaque = YES;
	self.view.autoresizesSubviews = YES;
	glView.frame = self.view.bounds;
    glView.backgroundColor = [UIColor blackColor];

	// Create the textures and geometry, but in the right GL context
	[sceneRenderer useContext];
    
    // Turn on the model matrix optimization for drawing
    sceneRenderer.useViewChanged = true;
    
	// Need an empty scene and view    
	globeView = [[WhirlyGlobeView alloc] init];
    globeScene = new WhirlyGlobe::GlobeScene(globeView.coordSystem,4);
    sceneRenderer.theView = globeView;
    
    // Need a layer thread to manage the layers
	layerThread = [[WhirlyKitLayerThread alloc] initWithScene:globeScene view:globeView renderer:sceneRenderer];

    // Selection feedback
    selectLayer = [[WhirlyKitSelectionLayer alloc] initWithView:globeView renderer:sceneRenderer];
    [layerThread addLayer:selectLayer];
    
	// Set up the vector layer where all our outlines will go
	vectorLayer = [[WhirlyKitVectorLayer alloc] init];
	[layerThread addLayer:vectorLayer];
    
	// General purpose label layer.
	labelLayer = [[WhirlyKitLabelLayer alloc] init];
    labelLayer.selectLayer = selectLayer;
	[layerThread addLayer:labelLayer];

    // Marker layer
    markerLayer = [[WhirlyKitMarkerLayer alloc] init];
    markerLayer.selectLayer = selectLayer;
    [layerThread addLayer:markerLayer];
    
    // Lastly, an interaction layer of our own
    interactLayer = [[WGInteractionLayer alloc] init];
    interactLayer.vectorLayer = vectorLayer;
    interactLayer.labelLayer = labelLayer;
    interactLayer.markerLayer = markerLayer;
    interactLayer.selectLayer = selectLayer;
    interactLayer.viewController = self;
    interactLayer.glView = glView;
    [layerThread addLayer:interactLayer];

	// Give the renderer what it needs
	sceneRenderer.scene = globeScene;
	sceneRenderer.theView = globeView;
	
	// Wire up the gesture recognizers
	panDelegate = [PanDelegateFixed panDelegateForView:glView globeView:globeView];
	tapDelegate = [WhirlyGlobeTapDelegate tapDelegateForView:glView globeView:globeView];
    // These will activate the appropriate gesture
    self.pinchGesture = true;
    self.rotateGesture = true;
    
    viewTrackers = [NSMutableArray array];
	
	// Kick off the layer thread
	// This will start loading things
	[layerThread start];
    
    // Set up defaults for the hints
    NSDictionary *newHints = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kWGRenderHintZBuffer,
                              nil];
    [self setHints:newHints];
    
    // Set up default descriptions for the various data types
    NSDictionary *newScreenLabelDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithFloat:1.0], kWGFade,
                                        nil];
    [self setScreenLabelDesc:newScreenLabelDesc];

    NSDictionary *newLabelDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInteger:kWGLabelDrawOffsetDefault], kWGDrawOffset,
                                  [NSNumber numberWithInteger:kWGLabelDrawPriorityDefault], kWGDrawPriority,
                                  [NSNumber numberWithFloat:1.0], kWGFade,
                                  nil];
    [self setLabelDesc:newLabelDesc];
    
    NSDictionary *newScreenMarkerDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithFloat:1.0], kWGFade,
                                         nil];
    [self setScreenMarkerDesc:newScreenMarkerDesc];
    
    NSDictionary *newMarkerDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInteger:kWGMarkerDrawOffsetDefault], kWGDrawOffset,                                   
                                   [NSNumber numberWithInteger:kWGMarkerDrawPriorityDefault], kWGDrawPriority,                                   
                                   [NSNumber numberWithFloat:1.0], kWGFade,
                                   nil];
    [self setMarkerDesc:newMarkerDesc];
    
    NSDictionary *newVectorDesc = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInteger:kWGVectorDrawOffsetDefault], kWGDrawOffset,                                   
                                   [NSNumber numberWithInteger:kWGVectorDrawPriorityDefault], kWGDrawPriority,                                   
                                   [NSNumber numberWithFloat:1.0], kWGFade, 
                                   nil];
    [self setVectorDesc:newVectorDesc];
    
    selection = true;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadSetup];
}

- (void)viewDidUnload
{	
	[self clear];
	
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[glView startAnimation];
	
    [self registerForEvents];
    
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[glView stopAnimation];

	// Stop tracking notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
	[super viewWillDisappear:animated];
}

// Register for interesting tap events and others
- (void)registerForEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapOnGlobe:) name:WhirlyGlobeTapMsg object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapOutsideGlobe:) name:WhirlyGlobeTapOutsideMsg object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sphericalEarthLayerLoaded:) name:kWhirlyGlobeSphericalEarthLoaded object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// Called when the earth layer finishes loading
- (void)sphericalEarthLayerLoaded:(NSNotification *)note
{
    WhirlyGlobeSphericalEarthLayer *layer = note.object;
    
    // Look for the matching layer
    if ([delegate respondsToSelector:@selector(globeViewController:layerDidLoad:)])
        for (WGViewControllerLayer *userLayer in userLayers)
        {
            if ([userLayer isKindOfClass:[WGSphericalEarthWithTexGroup class]])
            {
                WGSphericalEarthWithTexGroup *userSphLayer = (WGSphericalEarthWithTexGroup *)userLayer;
                if (userSphLayer.earthLayer == layer)
                {
                    [delegate globeViewController:self layerDidLoad:userLayer];
                    break;
                }
            }
        }
}

- (void)startRenderingLayer:(WGViewControllerLayer *)layer
{
    [userLayers addObject:layer];
    [layer startOnLayerThread:layerThread withRenderer:sceneRenderer];
    // TODO: configure zoom depths based on layer -- layer.zoomRange :: globeView.nearPlane, globeView.farPlane
}

- (void)startRenderingLayer:(WGViewControllerLayer<WGCacheableLayer> *)layer withCacheDirectory:(NSString *)cacheDirectory
{
    layer.cacheDirectory = cacheDirectory;
    [userLayers addObject:layer];
    [layer startOnLayerThread:layerThread withRenderer:sceneRenderer];
    // TODO: configure zoom depths based on layer -- layer.zoomRange :: globeView.nearPlane, globeView.farPlane
}

- (void)stopRenderingLayer:(WGViewControllerLayer *)layer
{
    [layer removeLayerFromThread:layerThread];
    [userLayers removeObject:layer];
}

- (void)stopRenderingLayers
{
    for(WGViewControllerLayer *layer in userLayers)
        [layer removeLayerFromThread:layerThread];
    [userLayers removeAllObjects];
}

#pragma mark - Defaults and descriptions

// Merge the two dictionaries, add taking precidence, and then look for NSNulls
- (NSDictionary *)mergeAndCheck:(NSDictionary *)baseDict changeDict:(NSDictionary *)addDict
{
    if (!addDict)
        return baseDict;

    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:baseDict];
    [newDict addEntriesFromDictionary:addDict];
    
    // Now look for NSNulls, which we use to remove things
    NSArray *keys = [newDict allKeys];
    for (NSString *key in keys)
    {
        NSObject *obj = [newDict objectForKey:key];
        if (obj && [obj isKindOfClass:[NSNull class]])
            [newDict removeObjectForKey:key];
    }
    
    return newDict;
}

// Set new hints and update any related settings
- (void)setHints:(NSDictionary *)changeDict
{
    hints = [self mergeAndCheck:hints changeDict:changeDict];

    // Settings we store in the hints
    BOOL zBuffer = [hints boolForKey:kWGRenderHintZBuffer default:true];
    sceneRenderer.zBuffer = zBuffer;
    BOOL culling = [hints boolForKey:kWGRenderHintCulling default:true];
    sceneRenderer.doCulling = culling;
}

// Set the default description for screen markers
- (void)setScreenMarkerDesc:(NSDictionary *)desc
{
    screenMarkerDesc = [self mergeAndCheck:screenMarkerDesc changeDict:desc];
}

// Set the default description for markers
- (void)setMarkerDesc:(NSDictionary *)desc
{
    markerDesc = [self mergeAndCheck:markerDesc changeDict:desc];    
}

// Set the default description for screen labels
- (void)setScreenLabelDesc:(NSDictionary *)desc
{
    screenLabelDesc = [self mergeAndCheck:screenLabelDesc changeDict:desc];    
}

// Set the default description for labels
- (void)setLabelDesc:(NSDictionary *)desc
{
    labelDesc = [self mergeAndCheck:labelDesc changeDict:desc];    
}

- (void)setVectorDesc:(NSDictionary *)desc
{
    vectorDesc = [self mergeAndCheck:vectorDesc changeDict:desc];
}

#pragma mark - Geometry related methods

/// Add a group of screen (2D) markers
- (WGComponentObject *)addScreenMarkers:(NSArray *)markers
{
    return [interactLayer addScreenMarkers:markers desc:screenMarkerDesc];
}

/// Add a group of 3D markers
- (WGComponentObject *)addMarkers:(NSArray *)markers
{
    return [interactLayer addMarkers:markers desc:markerDesc];
}

/// Add a group of screen (2D) labels
- (WGComponentObject *)addScreenLabels:(NSArray *)labels
{
    return [interactLayer addScreenLabels:labels desc:screenLabelDesc];
}

/// Add a group of 3D labels
- (WGComponentObject *)addLabels:(NSArray *)labels
{
    return [interactLayer addLabels:labels desc:labelDesc];
}

/// Add one or more vectors
- (WGComponentObject *)addVectors:(NSArray *)vectors
{
    return [interactLayer addVectors:vectors desc:vectorDesc];
}

/// Add a view to track to a particular location
- (void)addViewTracker:(WGViewTracker *)viewTrack
{
    // Make sure we're not duplicating and add the object
    [self removeViewTrackForView:viewTrack.view];
    [viewTrackers addObject:viewTrack];
    
    // Hook it into the renderer
    ViewPlacementGenerator *vpGen = globeScene->getViewPlacementGenerator();
    vpGen->addView(GeoCoord(viewTrack.loc.lon,viewTrack.loc.lat),viewTrack.view,DrawVisibleInvalid,DrawVisibleInvalid);
    
    // And add it to the view hierarchy
    if ([viewTrack.view superview] == nil)
        [glView addSubview:viewTrack.view];
}

/// Remove the view tracker associated with the given UIView
- (void)removeViewTrackForView:(UIView *)view
{
    // Look for the entry
    WGViewTracker *theTracker = nil;
    for (WGViewTracker *viewTrack in viewTrackers)
        if (viewTrack.view == view)
        {
            theTracker = viewTrack;
            break;
        }
    
    if (theTracker)
    {
        [viewTrackers removeObject:theTracker];
        ViewPlacementGenerator *vpGen = globeScene->getViewPlacementGenerator();
        vpGen->removeView(theTracker.view);
        if ([theTracker.view superview] == glView)
            [theTracker.view removeFromSuperview];
    }
}


/// Remove the data associated with an object the user added earlier
- (void)removeObject:(WGComponentObject *)theObj
{
    [interactLayer removeObject:theObj];
}

- (void)removeObjects:(NSArray *)theObjs
{
    [interactLayer removeObjects:theObjs];
}

#pragma mark - Properties

- (void)setKeepNorthUp:(bool)keepNorthUp
{
    panDelegate.northUp = keepNorthUp;
}

- (bool)keepNorthUp
{
    return panDelegate.northUp;
}

- (void)setPinchGesture:(bool)pinchGesture
{
    if (pinchGesture)
    {
        if (!pinchDelegate)
            pinchDelegate = [WGPinchDelegateFixed pinchDelegateForView:glView globeView:globeView];
    } else {
        if (pinchDelegate)
        {
            UIPinchGestureRecognizer *pinchRecog = nil;
            for (UIGestureRecognizer *recog in glView.gestureRecognizers)
                if ([recog isKindOfClass:[UIPinchGestureRecognizer class]])
                    pinchRecog = (UIPinchGestureRecognizer *)recog;
            [glView removeGestureRecognizer:pinchRecog];
            pinchDelegate = nil;
        }
    }
}

- (bool)pinchGesture
{
    return pinchDelegate != nil;
}

- (void)setRotateGesture:(bool)rotateGesture
{
    if (rotateGesture)
    {
        if (!rotateDelegate)
            rotateDelegate = [WhirlyGlobeRotateDelegate rotateDelegateForView:glView globeView:globeView];
    } else {        
        if (rotateDelegate)
        {
            UIRotationGestureRecognizer *rotRecog = nil;
            for (UIGestureRecognizer *recog in glView.gestureRecognizers)
                if ([recog isKindOfClass:[UIRotationGestureRecognizer class]])
                    rotRecog = (UIRotationGestureRecognizer *)recog;
            [glView removeGestureRecognizer:rotRecog];
            rotateDelegate = nil;
        }
    }
}

- (bool)rotateGesture
{
    return rotateDelegate != nil;
}

- (UIColor *)clearColor
{
    return theClearColor;
}

- (void)setClearColor:(UIColor *)clearColor
{
    theClearColor = clearColor;
    [sceneRenderer setClearColor:clearColor];
}

- (float)height
{
    return globeView.heightAboveGlobe;
}

- (void)setHeight:(float)height
{
    globeView.heightAboveGlobe = height;
}

- (void)getZoomLimitsMin:(float *)minHeight max:(float *)maxHeight
{
    if (pinchDelegate)
    {
        *minHeight = pinchDelegate.minHeight;
        *maxHeight = pinchDelegate.maxHeight;
    }
}

/// Set the min and max heights above the globe for zooming
- (void)setZoomLimitsMin:(float)minHeight max:(float)maxHeight
{
    if (pinchDelegate)
    {
        pinchDelegate.minHeight = minHeight;
        pinchDelegate.maxHeight = maxHeight;
        if (globeView.heightAboveGlobe < minHeight)
            globeView.heightAboveGlobe = minHeight;
        if (globeView.heightAboveGlobe > maxHeight)
            globeView.heightAboveGlobe = maxHeight;
    }
}

#pragma mark - Interaction

// Rotate to the given location over time
- (void)rotateToPoint:(GeoCoord)whereGeo time:(NSTimeInterval)howLong
{
    // If we were rotating from one point to another, stop
    [globeView cancelAnimation];
    
    // Construct a quaternion to rotate from where we are to where
    //  the user tapped
    Eigen::Quaternionf newRotQuat = [globeView makeRotationToGeoCoord:whereGeo keepNorthUp:YES];
    
    // Rotate to the given position over 1s
    animateRotation = [[AnimateViewRotation alloc] initWithView:globeView rot:newRotQuat howLong:howLong];
    globeView.delegate = animateRotation;        
}

// External facing version of rotateToPoint
- (void)animateToPosition:(WGCoordinate)newPos time:(NSTimeInterval)howLong
{
    [self rotateToPoint:GeoCoord(newPos.lon,newPos.lat) time:howLong];
}

// External facing set position
- (void)setPosition:(WGCoordinate)newPos
{
    // Note: This might conceivably be a problem, though I'm not sure how.
    [self rotateToPoint:GeoCoord(newPos.lon,newPos.lat) time:0.0];
}

- (void)setPosition:(WGCoordinate)newPos height:(float)height
{
    [self setPosition:newPos];
    globeView.heightAboveGlobe = height;
}

// Called back on the main thread after the interaction thread does the selection
- (void)handleSelection:(WhirlyGlobeTapMessage *)msg didSelect:(NSObject *)selectedObj
{
    if (selectedObj && selection)
    {
        // The user selected something, so let the delegate know
        if (delegate && [delegate respondsToSelector:@selector(globeViewController:didSelect:)])
            [delegate globeViewController:self didSelect:selectedObj];
    } else {
        // The user didn't select anything, let the delegate know.
        if (delegate && [delegate respondsToSelector:@selector(globeViewController:didTapAt:)])
        {
            WGCoordinate coord;
            coord.lon = msg.whereGeo.lon();
            coord.lat = msg.whereGeo.lat();
            [delegate globeViewController:self didTapAt:coord];
        }
        // Didn't select anything, so rotate
        [self rotateToPoint:msg.whereGeo time:1.0];
    }
}

// Called when the user taps on the globe.  We'll rotate to that position
- (void) tapOnGlobe:(NSNotification *)note
{
    WhirlyGlobeTapMessage *msg = note.object;
    
    // Hand this over to the interaction layer to look for a selection
    // If there is no selection, it will call us back in the main thread
    [interactLayer userDidTap:msg];
}

// Called when the user taps outside the globe.
- (void) tapOutsideGlobe:(NSNotification *)note
{
    if (selection && delegate && [delegate respondsToSelector:@selector(globeViewControllerDidTapOutside:)])
        [delegate globeViewControllerDidTapOutside:self];
}

@end

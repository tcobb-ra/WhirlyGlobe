//
//  TestViewController.h
//  WhirlyGlobeComponentTester
//
//  Created by Steve Gifford on 7/23/12.
//  Copyright (c) 2012 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobeComponent.h"
#import "ConfigViewController.h"

// The various base layers we know about
typedef NS_ENUM(NSUInteger, BaseLayer) {
    BlueMarbleSingleResLocal,
    GeographyClassMBTilesLocal,
    StamenWatercolorRemote,
    OpenStreetmapRemote,
    BingMapsRemote,
    MaxBaseLayers
};

/** The Test View Controller brings up the WhirlyGlobe Component
    and allows the user to test various functionality.
 */
@interface TestViewController : UIViewController <WhirlyGlobeViewControllerDelegate,UIPopoverControllerDelegate>
{
    WhirlyGlobeViewController *globeViewC;
    UIPopoverController *popControl;
}

// Fire it up with a particular base layer
- (id)initWithBaseLayer:(BaseLayer)baseLayer;

@end

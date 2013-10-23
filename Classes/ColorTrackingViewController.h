//
//  ColorTrackingViewController.h
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import <UIKit/UIKit.h>
#import "ColorTrackingCamera.h"
#import "ColorTrackingGLView.h"

typedef enum { PASSTHROUGH_VIDEO, SIMPLE_THRESHOLDING, POSITION_THRESHOLDING} ColorTrackingDisplayMode;


@interface ColorTrackingViewController : UIViewController <ColorTrackingCameraDelegate>
{
	ColorTrackingCamera *camera;
	UIScreen *screenForDisplay;
	ColorTrackingGLView *glView;
	
	ColorTrackingDisplayMode displayMode;
	
	BOOL shouldReplaceThresholdColor;
	CGPoint currentTouchPoint;
	GLfloat thresholdSensitivity;
	GLfloat thresholdColor[3];
	
	GLuint directDisplayProgram, thresholdProgram, positionProgram;
	GLuint videoFrameTexture;
	bool takePic;
	GLubyte *rawPositionPixels;
    
    CGRect drawRect;
}

@property(readonly) ColorTrackingGLView *glView;

// Initialization and teardown
- (id)initWithScreen:(UIScreen *)newScreenForDisplay;

// OpenGL ES 2.0 setup methods
- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// Image processing
- (CGPoint)centroidFromTexture:(GLubyte *)pixels;

@end


//#if defined(__IPHONE_2_0) || defined(__IPHONE_2_1)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <stdio.h>
#import <unistd.h>
#import "../geWizES.h"

@interface egwUnitTestA : NSThread <UIApplicationDelegate, egwDGfxContextEvent, egwDDecodedStrokeEvent, egwDButtonEvent, egwDSliderEvent, egwDSoundEvent> {
    EGWsingle _yaw;
    EGWsingle _pitch;
    EGWsingle _dist;
    
    egwVector3f _lTest[2];
    
    id<egwPHook> _hookedObject;
}
- (void)main;
- (void)applicationDidFinishLaunching:(UIApplication*)application;
- (void)applicationDidBecomeActive:(UIApplication*)application;
- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application;
- (void)applicationWillTerminate:(UIApplication*)application;
- (BOOL)willFinishInitializingGfxContext:(egwGfxContextEAGLES*)context;
- (void)didFinishInitializingGfxContext:(egwGfxContextEAGLES*)context;
- (BOOL)willShutDownGfxContext:(egwGfxContextEAGLES*)context;
- (void)didShutDownGfxContext:(egwGfxContextEAGLES*)context;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration;
@end

void egwAVLTreePrint(egwAVLTree* tree_in) {
    if(tree_in->eCount) {
        egwCyclicArray queue; egwCycArrayInit(&queue, NULL, sizeof(egwAVLTreeNode*), 2, EGW_ARRAY_FLG_DFLT);
        
        egwCycArrayAddTail(&queue, (const EGWbyte*)&tree_in->tRoot);
        
        int left = 1;
        int factor = 1;
        egwAVLTreeNode* nilNode = (egwAVLTreeNode*)(void*)1;
        
        while(queue.eCount) {
            egwAVLTreeNode* node = *(egwAVLTreeNode**)egwCycArrayElementPtrHead(&queue);
            
            if(node > (egwAVLTreeNode*)(void*)1) {
                if(node->left)
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&node->left);
                else
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                if(node->right)
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&node->right);
                else
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                
                printf(" %03d/%01d.%01d ", *(int*)egwAVLTreeElementPtr(node), node->nBalance, node->stHeight);
            } else {
                egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                
                printf(" nil/0.0 ");
            }
            
            egwCycArrayRemoveHead(&queue);
            
            if(--left == 0) {
                factor *= 2;
                left = factor;
                printf("\r\n");
            }
            
            if(factor >= 32)
                break;
        }
        
        egwCycArrayFree(&queue);
        
        egwAVLTreeIter iter;
        
        if(egwAVLTreeEnumerateStart(tree_in, EGW_ITERATE_MODE_BSTLSR, &iter)) {
            int* val;
            
            printf("In-order: ");
            while((val = (int*)egwAVLTreeEnumerateNextPtr(&iter))) {
                printf("%d ", *val);
            }
            printf("\r\n");
        }
        
        if(egwAVLTreeEnumerateStart(tree_in, EGW_ITERATE_MODE_BSTLO, &iter)) {
            int* val;
            
            printf("Level-order: ");
            while((val = (int*)egwAVLTreeEnumerateNextPtr(&iter))) {
                printf("%d ", *val);
            }
            printf("\r\n");
        }
    } else
        printf("Empty tree.\r\n");
    
    printf("\r\n");
}

void egwRBTreePrint(egwRedBlackTree* tree_in) {
    if(tree_in->eCount) {
        egwCyclicArray queue; egwCycArrayInit(&queue, NULL, sizeof(egwRedBlackTreeNode*), 2, EGW_ARRAY_FLG_DFLT);
        
        egwCycArrayAddTail(&queue, (const EGWbyte*)&tree_in->tRoot);
        
        int left = 1;
        int factor = 1;
        egwRedBlackTreeNode* nilNode = (egwRedBlackTreeNode*)(void*)1;
        
        while(queue.eCount) {
            egwRedBlackTreeNode* node = *(egwRedBlackTreeNode**)egwCycArrayElementPtrHead(&queue);
            
            if(node > (egwRedBlackTreeNode*)(void*)1) {
                if(node->left)
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&node->left);
                else
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                if(node->right)
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&node->right);
                else
                    egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                
                printf(" %03d/%01d ", *(int*)egwRBTreeElementPtr(node), node->nFlags);
            } else {
                egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                egwCycArrayAddTail(&queue, (const EGWbyte*)&nilNode);
                
                printf(" nil/0 ");
            }
            
            egwCycArrayRemoveHead(&queue);
            
            if(--left == 0) {
                factor *= 2;
                left = factor;
                printf("\r\n");
            }
            
            if(factor >= 32)
                break;
        }
        
        egwCycArrayFree(&queue);
        
        egwRedBlackTreeIter iter;
        
        if(egwRBTreeEnumerateStart(tree_in, EGW_ITERATE_MODE_BSTLSR, &iter)) {
            int* val;
            
            printf("In-order: ");
            while((val = (int*)egwRBTreeEnumerateNextPtr(&iter))) {
                printf("%d ", *val);
            }
            printf("\r\n");
        }
        
        if(egwRBTreeEnumerateStart(tree_in, EGW_ITERATE_MODE_BSTLO, &iter)) {
            int* val;
            
            printf("Level-order: ");
            while((val = (int*)egwRBTreeEnumerateNextPtr(&iter))) {
                printf("%d ", *val);
            }
            printf("\r\n");
        }
    } else
        printf("Empty tree.\r\n");
    
    printf("\r\n");
}

@implementation egwUnitTestA

- (void)applicationDidFinishLaunching:(UIApplication*)application { // on main thread
    printf("applicationDidFinishLaunching\r\n");
    
    [[egwEngine alloc] init];
    
    // Testing array sort routine
    /*{   egwArray array; egwArrayInit(&array, NULL, sizeof(int), 10, EGW_ARRAY_FLG_DFLT);
        
        for(int i = 0; i < 10; ++i)
            ((int*)array.rData)[i] = rand() % 25;
        array.eCount = 10;
        
        egwArraySort(&array);
        
        for(int i = 0; i < 10; ++i)
            printf("%d ", ((int*)array.rData)[i]);
        printf("\n");
    }*/
    
    // Testing linked list sort routine
    /*{   egwSinglyLinkedList list; egwSLListInit(&list, NULL, sizeof(int), EGW_LIST_FLG_DFLT);
        int val;
        
        for(int i = 0; i < 10; ++i) {
            val = rand() % 25;
            egwSLListAddTail(&list, (const EGWbyte*)&val);
        }
        
        egwSLListSort(&list);
        
        egwSinglyLinkedListIter iter;
        egwSLListEnumerateStart(&list, EGW_ITERATE_MODE_DFLT, &iter);
        while(egwSLListEnumerateGetNext(&iter, (EGWbyte*)&val)) {
            printf("%d ", val);
        }
        printf("\n");
    }*/
    
    // Testing array find routine
    /*{   egwArray array; egwArrayInit(&array, NULL, sizeof(int), 10, EGW_ARRAY_FLG_DFLT);
        
        ((int*)array.rData)[0] = 2;
        ((int*)array.rData)[1] = 3;
        ((int*)array.rData)[2] = 3;
        ((int*)array.rData)[3] = 3;
        ((int*)array.rData)[4] = 3;
        ((int*)array.rData)[5] = 3;
        ((int*)array.rData)[6] = 3;
        ((int*)array.rData)[7] = 3;
        ((int*)array.rData)[8] = 3;
        ((int*)array.rData)[9] = 5;
        array.eCount = 10;
        
        int val = 3;
        
        printf("Find %d: is at %d\n", val, egwArrayFind(&array, (const EGWbyte*)&val, EGW_FIND_MODE_BINARY));
        printf("Occr %d: is at %d\n", val, egwArrayOccurances(&array, (const EGWbyte*)&val, EGW_FIND_MODE_BINARY));
    }*/
    
    // Testing cyclic array sort & find routines
    /*{   egwCyclicArray array; egwCycArrayInit(&array, NULL, sizeof(int), 10, EGW_ARRAY_FLG_DFLT);
        
        ((int*)array.rData)[0] = 2;
        ((int*)array.rData)[1] = 1;
        ((int*)array.rData)[2] = 5;
        ((int*)array.rData)[3] = 5;
        ((int*)array.rData)[4] = 5;
        ((int*)array.rData)[5] = 0;
        ((int*)array.rData)[6] = 1;
        ((int*)array.rData)[7] = 1;
        ((int*)array.rData)[8] = 1;
        ((int*)array.rData)[9] = 1;
        array.eCount = 9;
        array.pOffset = 6;
        
        int val = 2;
        
        egwCycArraySort(&array);
        printf("Find %d: is at %d\n", val, egwCycArrayFind(&array, (const EGWbyte*)&val, EGW_FIND_MODE_BINARY));
        printf("Occr %d: is at %d\n", val, egwCycArrayOccurances(&array, (const EGWbyte*)&val, EGW_FIND_MODE_BINARY));
    }*/
    
    // Testing AVL tree
    {   egwAVLTree tree; egwAVLTreeInit(&tree, NULL, sizeof(int), EGW_TREE_FLG_DFLT);
        int val;
        
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        
        egwAVLTreePrint(&tree);
        
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwAVLTreeAdd(&tree, (const EGWbyte*)&val);
        
        egwAVLTreePrint(&tree);
        
        while(tree.tRoot) {
            int random = rand() % 3;
            
            if(random == 1 && tree.tRoot->left)
                egwAVLTreeRemove(&tree, tree.tRoot->left);
            else if(random == 2 && tree.tRoot->right)
                egwAVLTreeRemove(&tree, tree.tRoot->right);
            else
                egwAVLTreeRemove(&tree, tree.tRoot);
            
            egwAVLTreePrint(&tree);
        }
        
        egwAVLTreeFree(&tree);
    }
    
    // Testing RB tree
    {   egwRedBlackTree tree; egwRBTreeInit(&tree, NULL, sizeof(int), EGW_TREE_FLG_DFLT);
        int val;
        
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        
        egwRBTreePrint(&tree);
        
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        val = rand()%10; egwRBTreeAdd(&tree, (const EGWbyte*)&val);
        
        egwRBTreePrint(&tree);
        
        while(tree.tRoot) {
            int random = rand() % 3;
            
            if(random == 1 && tree.tRoot->left)
                egwRBTreeRemove(&tree, tree.tRoot->left);
            else if(random == 2 && tree.tRoot->right)
                egwRBTreeRemove(&tree, tree.tRoot->right);
            else
                egwRBTreeRemove(&tree, tree.tRoot);
            
            egwRBTreePrint(&tree);
        }
        
        egwRBTreeFree(&tree);
    }
    
    _yaw = egwDegToRad(60); _pitch = egwDegToRad(55); _dist = 3.5f; memset((void*)&_lTest, 0, 2 * sizeof(egwVector3f));
    
    {   [application setIdleTimerDisabled:YES];
        [application setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        //[application setStatusBarHidden:NO animated:YES];
        
        egwGfxCntxParams gfxCntxParams; memset((void*)&gfxCntxParams, 0, sizeof(egwGfxCntxParams));
        gfxCntxParams.delegate = self;
        gfxCntxParams.fbClear = 1;
        gfxCntxParams.fbClearColor.channel.r = gfxCntxParams.fbClearColor.channel.g = gfxCntxParams.fbClearColor.channel.b = 0.5f;
        
        // Creating the primary window and view (egwUIViewSurface will create a primary graphics context)
        UIWindow* window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [window setBackgroundColor:[UIColor blackColor]];
        egwUIViewSurface* view = [[egwUIViewSurface alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]
                                                           contextParams:(void*)&gfxCntxParams];
        view.multipleTouchEnabled = YES;
        //[view setTouchDelegate:self];
        //[view setAccelerometerDelegate:self];
        [window addSubview:view];
        [window makeKeyAndVisible];
        
        // Creating the automated touch decoder
        egwTouchDecoder* decoder = [[egwTouchDecoder alloc] init];
        [view setTouchDelegate:decoder];
        [decoder setDelegate:self];
        
        // Creating the primary graphics renderer
        [[egwGfxRenderer alloc] init];
        
        // Creating the primary sound context
        egwSndCntxParams sndCntxParams; memset((void*)&sndCntxParams, 0, sizeof(egwSndCntxParams));
        sndCntxParams.mixerFreq = 44100;
        sndCntxParams.refreshIntvl = 10;
        [egwSIEngine createSndContext:&sndCntxParams];
        [egwAISndCntx setSystemVolume:90];
        
        // Creating the primary sound mixer
        [[egwSndMixer alloc] init];
        
        // Creating the primary physics context
        egwPhyCntxParams phyCntxParams; memset((void*)&phyCntxParams, 0, sizeof(egwPhyCntxParams));
        [egwSIEngine createPhyContext:&phyCntxParams];
        
        // Creating the primary physical actuator
        [[egwPhyActuator alloc] init];
        
        // Creating the primary task manager task graph
        {   EGWint gTask1 = [egwSITaskMngr registerTaskUsing:egwSIGfxRdr];
            EGWint gTask2 = [egwSITaskMngr registerTaskUsing:egwSIGfxRdr];
            EGWint pTask1 = [egwSITaskMngr registerStarterTaskUsing:egwSIPhyAct];
            EGWint pTask2 = [egwSITaskMngr registerTaskUsing:egwSIPhyAct];
            EGWint sTask1 = [egwSITaskMngr registerTaskUsing:egwSISndMxr];
            
            //    /-G1-\    /-G2-\    /-G1-\
            // P1-|    |-P2-/    \-P1-|    |-(etc.)
            //    \-S1-/              \-S1-/
            [egwSITaskMngr registerDependencyForTask:gTask1 withTask:pTask1];
            [egwSITaskMngr registerDependencyForTask:sTask1 withTask:pTask1];
            [egwSITaskMngr registerDependencyForTask:pTask2 withTask:gTask1];
            [egwSITaskMngr registerDependencyForTask:pTask2 withTask:sTask1];
            [egwSITaskMngr registerDependencyForTask:gTask2 withTask:pTask2];
            [egwSITaskMngr registerDependencyForTask:pTask1 withTask:gTask2];
            
            // enable given in another thread
        }
    }
    
    /*
    // Testing bounding collision code
    {   egwBox4f box, box2;
        box.min.axis.x = -1.0f; box.min.axis.y = -1.0f; box.min.axis.z = -1.0f;
        box.max.axis.x =  1.0f; box.max.axis.y =  1.0f; box.max.axis.z =  1.0f;
        box.origin.axis.x = (box.min.axis.x + box.max.axis.x) * 0.5f;
        box.origin.axis.y = (box.min.axis.y + box.max.axis.y) * 0.5f;
        box.origin.axis.z = (box.min.axis.z + box.max.axis.z) * 0.5f;
        box.min.axis.w = box.max.axis.w = box.origin.axis.w = 1.0f;
        memcpy((void*)&box2, (const void*)&box, sizeof(egwBox4f));
        
        egwCylinder4f cyl, cyl2;
        cyl.origin.axis.x = cyl.origin.axis.y = cyl.origin.axis.z = 0.0;
        cyl.hHeight = 1.0f;
        cyl.radius = 1.0f;
        cyl.origin.axis.w = 1.0f;
        memcpy((void*)&cyl2, (const void*)&cyl, sizeof(egwCylinder4f));
        
        egwSphere4f sph, sph2;
        sph.origin.axis.x = sph.origin.axis.y = sph.origin.axis.z = 0.0;
        sph.radius = 1.0f;
        sph.origin.axis.w = 1.0f;
        memcpy((void*)&sph2, (const void*)&sph, sizeof(egwSphere4f));
        
        EGWint result = -1;
        result = egwTestCollisionSphereSpheref(&sph, &sph2);
        result = egwTestCollisionSphereBoxf(&sph, &box);
        result = egwTestCollisionSphereCylinderf(&sph, &cyl);
        result = egwTestCollisionBoxBoxf(&box, &box2);
        result = egwTestCollisionBoxCylinderf(&box, &cyl);
        result = egwTestCollisionCylinderCylinderf(&cyl, &cyl2);
        printf("res: %d", result);
    }*/
    
    // Creating the first pass/primary perspective camera object
    {   egwPerspectiveCamera* testPerspectiveCamera = nil;
        if(testPerspectiveCamera = [[egwPerspectiveCamera alloc] initWithIdentity:@"testPerspectiveCamera" graspAngle:0.0f fieldOfView:48.0f aspectRatio:((EGWsingle)[egwAIGfxCntx bufferWidth] / (EGWsingle)[egwAIGfxCntx bufferHeight]) frontPlane:0.5f backPlane:100.0f]) {
            egwVector3f camPos; egwVecInit3f(&camPos, egwCosf(_yaw) * egwSinf(_pitch) * _dist, egwCosf(_pitch) * _dist, egwSinf(_yaw) * egwSinf(_pitch) * _dist);
            [testPerspectiveCamera orientateByLookingAt:&egwSIVecZero3f withCameraAt:&camPos];
            [egwSIGfxRdr setRenderingCamera:testPerspectiveCamera forQueue:EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS | EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS];
            [egwSISndMxr setListenerCamera:testPerspectiveCamera];
        } [testPerspectiveCamera release]; testPerspectiveCamera = nil;
    }
    
    // Creating the third pass orthogonal camera object
    {   egwOrthogonalCamera* testOrthogonalCamera = nil;
        if(testOrthogonalCamera = [[egwOrthogonalCamera alloc] initWithIdentity:@"testOrthogonalCamera" graspAngle:0.0f surfaceWidth:[egwAIGfxCntxAGL bufferWidth] surfaceHeight:[egwAIGfxCntxAGL bufferHeight] zeroAlign:EGW_CAMERA_ORTHO_ZFALIGN_BTMLFT]) {
            [egwSIGfxRdr setRenderingCamera:testOrthogonalCamera forQueue:EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS];
        } [testOrthogonalCamera release]; testOrthogonalCamera = nil;
    }
    
    // Creating the primary light object
    {   egwPointLight* testLight = nil;
        if(testLight = [[egwPointLight alloc] initWithIdentity:@"testLight" lightRadius:EGW_SFLT_MAX lightMaterial:&egwSIMtrlWhite4f lightAttenuation:NULL]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, 25.0f, 25.0f, 25.0f, &orient);
            [testLight orientateByTransform:&orient];
            [egwSIAsstMngr loadAsset:nil fromExisting:testLight];
        } [testLight release]; testLight = nil;
    }
    
    // Create a test box texture object
    {   egwTexture* testTexture = nil;
        if(testTexture = [[egwTexture alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testBoxTexture.png" withIdentity:@"testBoxTexture" textureEnvironment:0 texturingTransforms:EGW_TEXTURE_TRFM_SHARPEN25 texturingFilter:EGW_TEXTURE_FLTR_TRILINEAR texturingSWrap:0 texturingTWrap:0]) {
            [egwSIAsstMngr loadAsset:nil fromExisting:testTexture];
        } [testTexture release]; testTexture = nil;
    }
    
    // Create a test box object
    {   egwMesh* testMesh = nil;
        if(testMesh = [[egwMesh alloc] initBoxWithIdentity:@"testBox" boxWidth:1.0f boxHeight:1.0f boxDepth:1.0f geometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC lightStack:nil materialStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:(id<egwPTexture>)[egwSIAsstMngr retrieveAsset:@"testBoxTexture"],0] autorelease]]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, -2.5f, 0.0f, 0.0f, &orient);
            [testMesh orientateByTransform:&orient];
            [testMesh illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testMesh setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
            [testMesh startRendering];
            [egwSIAsstMngr loadAsset:nil fromExisting:testMesh];
        } [testMesh release]; testMesh = nil;
    }
    
    // Create a test cone texture object
    {   egwTexture* testTexture = nil;
        if(testTexture = [[egwTexture alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testConeTexture.png" withIdentity:@"testConeTexture" textureEnvironment:0 texturingTransforms:EGW_TEXTURE_TRFM_SHARPEN25 texturingFilter:EGW_TEXTURE_FLTR_TRILINEAR texturingSWrap:0 texturingTWrap:0]) {
            [egwSIAsstMngr loadAsset:nil fromExisting:testTexture];
        } [testTexture release]; testTexture = nil;
    }
    
    // Create a test cone object
    {   egwMesh* testMesh = nil;
        if(testMesh = [[egwMesh alloc] initConeWithIdentity:@"testCone" coneRadius:0.5f coneHeight:1.0f coneLongitudes:12 geometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC lightStack:nil materialStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:(id<egwPTexture>)[egwSIAsstMngr retrieveAsset:@"testConeTexture"],0] autorelease]]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, 2.5f, 0.0f, 0.0f, &orient);
            [testMesh orientateByTransform:&orient];
            [testMesh illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testMesh setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
            [testMesh startRendering];
            [egwSIAsstMngr loadAsset:nil fromExisting:testMesh];
        } [testMesh release]; testMesh = nil;
    }
    
    // Create a test billboard texture object
    {   egwTexture* testTexture = nil;
        if(testTexture = [[egwTexture alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testTexture2.png" withIdentity:@"testTexture" textureEnvironment:0 texturingTransforms:(EGW_TEXTURE_TRFM_SHARPEN25 | EGW_SURFACE_TRFM_MGNTTRANS | EGW_SURFACE_TRFM_FORCEAC | EGW_SURFACE_TRFM_OPCTYDILT) texturingFilter:EGW_TEXTURE_FLTR_TRILINEAR texturingSWrap:0 texturingTWrap:0]) {
            [egwSIAsstMngr loadAsset:nil fromExisting:testTexture];
        } [testTexture release]; testTexture = nil;
    }
    
    // Create a test billboard object
    {   egwBillboard* testBillboard = nil;
        if(testBillboard = [[egwBillboard alloc] initQuadWithIdentity:@"testBillboard" quadWidth:2.0f quadHeight:2.0f billboardBounding:nil geometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC lightStack:nil materialStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:(id<egwPTexture>)[egwSIAsstMngr retrieveAsset:@"testTexture"],0] autorelease]]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, 2.5f, 0.0f, -2.5f, &orient);
            [testBillboard orientateByTransform:&orient];
            [testBillboard illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testBillboard setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
            [testBillboard startRendering];
            [egwSIAsstMngr loadAsset:nil fromExisting:testBillboard];
        } [testBillboard release]; testBillboard = nil;
    }
    
    // Create a test music object from class factory loader
    {   [egwSIAsstMngr loadAsset:@"testMusic" fromFile:@"/Users/johannes/Documents/Dev/egwAssets/testMusic.ogg"];
        id<egwPSound> testMusic = (id<egwPSound>)[egwSIAsstMngr retrieveAsset:@"testMusic"];
        [testMusic setPlaybackFlags:EGW_SNDOBJ_PLAYFLG_MUSIC]; // ensure it's a music based sound
        [testMusic startPlayback];
    }
    
    // Create a test sound object from class factor loader
    {   [egwSIAsstMngr loadAsset:@"testSound" fromFile:@"/Users/johannes/Documents/Dev/egwAssets/testSound.wav"];
        id<egwPSound> testSound = (id<egwPSound>)[egwSIAsstMngr retrieveAsset:@"testSound"];
        [testSound setPlaybackFlags:EGW_SNDOBJ_PLAYFLG_HIGHPRI];
    }
    
    // Create a test font object from class factory loader
    {   egwFntParams fntParams; memset((void*)&fntParams, 0, sizeof(egwFntParams));
        fntParams.pSize = 12.0f;
        fntParams.gColor.channel.r = fntParams.gColor.channel.g = fntParams.gColor.channel.b = 0.0f; fntParams.gColor.channel.a = 1.0f;
        fntParams.rEffects = EGW_FONT_EFCT_NORMAL;
        [egwSIAsstMngr loadAsset:@"testFont" fromFile:@"/Users/johannes/Documents/Dev/egwAssets/testFont.ttf" withParams:(void*)&fntParams];
        //id<egwPFont> testFont = (id<egwPFont>)[egwSIAsstMngr retrieveAsset:@"testFont"];
    }
    
    // Create a test label object
    {   egwLabel* testLabel = nil;
        if(testLabel = [[egwLabel alloc] initWithIdentity:@"testLabel" surfaceFormat:0 labelText:@"Thatch Tower\nIpo + system test" renderingFont:(id<egwPFont>)[egwSIAsstMngr retrieveAsset:@"testFont"] geometryStorage:EGW_GEOMETRY_STRG_VBODYNAMIC textureEnvironment:0 texturingTransforms:0 texturingFilter:0 lightStack:nil materialStack:[[egwMaterialStack alloc] initWithMaterials:[[[egwShade alloc] initWithIdentity:@"testShade" luminanceColor:1.0f alphaColor:1.0f] autorelease],0] shaderStack:nil]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, 160.0f, 25.0f, 0.95f, &orient);
            [testLabel orientateByTransform:&orient];
            [testLabel setRenderingFlags:EGW_GFXOBJ_RNDRFLG_THIRDPASS];
            [testLabel startRendering];
            [egwSIAsstMngr loadAsset:nil fromExisting:testLabel];
        } [testLabel release]; testLabel = nil;
    }
    
    // Create a test button object
    {   egwButton* testButton = nil;
        if(testButton = [[egwButton alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testButton.png" withIdentity:@"testButton" buttonWidth:64 buttonHeight:64 instanceGeometryStorage:EGW_GEOMETRY_STRG_VBODYNAMIC baseGeometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC textureEnvironment:0 texturingTransforms:0 texturingFilter:0 lightStack:nil materialStack:[[egwMaterialStack alloc] initWithMaterials:[[[egwShade alloc] initWithIdentity:@"testShade" luminanceColor:1.0f alphaColor:1.0f] autorelease],0] shaderStack:nil]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, 288.0f, 32.0f, 0.95f, &orient);
            [testButton orientateByTransform:&orient];
            [testButton setRenderingFlags:EGW_GFXOBJ_RNDRFLG_THIRDPASS];
            [testButton setDelegate:self];
            [testButton startRendering];
            [egwSIAsstMngr loadAsset:nil fromExisting:testButton];
        } [testButton release]; testButton = nil;
    }
    
    // Create a test sprited image object
    {   egwSpritedImage* testSprite = nil;
        if(testSprite = [[egwSpritedImage alloc] initLoadedFromResourceFiles:@"/Users/johannes/Documents/Dev/egwAssets/spritedImage.png" withIdentity:@"testSprite" spriteWidth:64 spriteHeight:64 spriteFPS:12.5f instanceGeometryStorage:EGW_GEOMETRY_STRG_VBODYNAMIC baseGeometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC textureEnvironment:0 texturingTransforms:0 texturingFilter:0 lightStack:nil materialStack:[[egwMaterialStack alloc] initWithMaterials:[[[egwShade alloc] initWithIdentity:@"testShade" luminanceColor:1.0f alphaColor:1.0f] autorelease],0] shaderStack:nil]) {
            egwMatrix44f offset; egwMatScale44fs(NULL, 0.0234f, 0.0234f, 0.0234f, &offset);
            [testSprite offsetByTransform:&offset];
            [testSprite setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
            [egwSIAsstMngr loadAsset:nil fromExisting:testSprite];
        } [testSprite release]; testSprite = nil;
    }
    
    // Create an actioned timer object
    {   egwActionedTimer* testTimer = nil;
        if(testTimer = [[egwActionedTimer alloc] initBlankWithIdentity:@"testTimer" actionCount:1 defaultAction:0]) {
            [(id<egwPTimed>)[egwSIAsstMngr retrieveAsset:@"testSprite"] setEvaluationTimer:testTimer];
            [testTimer setAction:0 timeBoundsBegin:0.0 andEnd:2.0];
            [egwSIAsstMngr loadAsset:nil fromExisting:testTimer];
            [testTimer setActuatorFlags:EGW_ACTOBJ_ACTRFLG_AUTOENQDS | EGW_ACTOBJ_ACTRFLG_LOOPING];
        } [testTimer release]; testTimer = nil;
    }
    
    // Create a sprited texture object
    {   egwSpritedTexture* testSpritedTexture = nil;
        if(testSpritedTexture = [[egwSpritedTexture alloc] initLoadedFromResourceFiles:@"/Users/johannes/Documents/Dev/egwAssets/spritedTexture.png" withIdentity:@"testSpritedTexture" horizontalSplits:5 verticalSplits:5 spriteFPS:5.0f textureEnvironment:0 texturingTransforms:0 texturingFilter:0]) {
            [egwSIAsstMngr loadAsset:nil fromExisting:testSpritedTexture];
        } [testSpritedTexture release]; testSpritedTexture = nil;
    }
    
    // Create a particle system object
    {   egwPSParticleDynamics pDyn; memset((void*)&pDyn, 0, sizeof(egwPSParticleDynamics));
        egwPSSystemDynamics sDyn; memset((void*)&sDyn, 0, sizeof(egwPSSystemDynamics));
        
        egwVecInit3f(&pDyn.pPosition.origin, 0.0f, 0.0f, 0.0f);
        egwVecInit3f(&pDyn.pPosition.variant, 0.0f, 0.0f, 0.0f);
        egwVecInit3f(&pDyn.pPosition.deltaT, 0.0f, 0.0f, 0.0f);
        
        egwVecInit3f(&pDyn.pVelocity.origin, 10.0f, 0.0f, 0.0f);
        egwVecInit3f(&pDyn.pVelocity.variant, 0.5f, 1.5f, 1.5f);
        egwVecInit3f(&pDyn.pVelocity.deltaT, -50.0f, 0.0f, 0.0f);
        
        pDyn.pWeight.origin = 1.0f;
        pDyn.pSize.origin = 20.0f;
        pDyn.pSize.deltaT = 30.0f;
        
        pDyn.pLife.origin = 0.20f;
        pDyn.pLife.variant = 0.10f;
        
        egwVecInit4f(&pDyn.pColor.origin, 1.0f, 1.0f, 1.0f, 1.00f);
        egwVecInit4f(&pDyn.pColor.variant, 0.0f, 0.0f, 0.0f, 0.0f);
        egwVecInit4f(&pDyn.pColor.deltaT, 0.0f, 0.0f, 0.0f, -1.0f / pDyn.pLife.origin);
        
        /*
        sDyn.pFrequency.origin = 0.20f;
        sDyn.pFrequency.variant = 0.05f;
        sDyn.pFrequency.deltaT = -0.25f;
        sDyn.eDuration.tParticles.origin = 10.0f;
        sDyn.mParticles = 150;*/
        sDyn.psFlags = EGW_PSYSFLAG_EMITLEFTVAR | EGW_PSYSFLAG_LOOPAFTRNP | EGW_PSYSFLAG_EMITTOWCS | EGW_PSYSFLAG_ALPHAOUTSHFT | EGW_PSYSFLAG_NOPOINTSPRT;
        
        sDyn.mParticles = 150;
        sDyn.eDuration.tParticles.origin = 30.0f;
        sDyn.pFrequency.origin =  0.00075;
        sDyn.pFrequency.variant = 0.00015f;
        sDyn.pFrequency.deltaT = 0.10f;
        
        egwTexture* tex = [[egwTexture alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testFire.png" withIdentity:@"testFireTex" textureEnvironment:0 texturingTransforms:0 texturingFilter:EGW_TEXTURE_FLTR_TRILINEAR texturingSWrap:0 texturingTWrap:0];
        
        egwParticleSystem* testSystem = nil;
        if(testSystem = [[egwParticleSystem alloc] initWithIdentity:@"testSystem" particleDynamics:&pDyn systemDynamics:&sDyn systemBounding:nil geometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC lightStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:tex,0] autorelease]]) {
            [testSystem setRenderingFlags:(EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT | EGW_GFXOBJ_RNDRFLG_FIRSTPASS | EGW_OBJEXTEND_FLG_ALWAYSOTGHMG | EGW_OBJEXTEND_FLG_LAZYBOUNDING)];
            [testSystem setActuatorFlags:(EGW_ACTOBJ_ACTRFLG_LOOPING | EGW_ACTOBJ_ACTRFLG_THROTTLE88)];
            //[testSystem setGroundLevel:-0.001f];
            //[testSystem illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testSystem startActuating];
        } [testSystem release]; testSystem = nil;
        [tex release]; tex = nil;
        
        
        memset((void*)&pDyn, 0, sizeof(egwPSParticleDynamics));
        memset((void*)&sDyn, 0, sizeof(egwPSSystemDynamics));
        
        egwVecInit3f(&pDyn.pPosition.origin, 0.0f, 0.0f, 0.0f);
        egwVecInit3f(&pDyn.pPosition.variant, 0.0f, 0.5f, 0.5f);
        egwVecInit3f(&pDyn.pPosition.deltaT, 0.0f, 0.0f, 0.0f);
        
        egwVecInit3f(&pDyn.pVelocity.origin, 1.50f, 0.0f, 0.0f);
        egwVecInit3f(&pDyn.pVelocity.variant, 1.45f, 1.5f, 1.5f);
        egwVecInit3f(&pDyn.pVelocity.deltaT, -0.25f, -0.2f, 0.0f);
        
        pDyn.pWeight.origin = 1.0f;
        pDyn.pSize.origin = 5.0f;
        pDyn.pSize.deltaT = 35.0f;
        
        pDyn.pLife.origin = 6.50f;
        pDyn.pLife.variant = 1.00f;
        
        egwVecInit4f(&pDyn.pColor.origin, 1.0f, 1.0f, 1.0f, 1.00f);
        egwVecInit4f(&pDyn.pColor.variant, 0.0f, 0.0f, 0.0f, 0.0f);
        egwVecInit4f(&pDyn.pColor.deltaT, 0.0f, 0.0f, 0.0f, -1.0f / pDyn.pLife.origin);
        
        sDyn.psFlags = EGW_PSYSFLAG_EMITLEFTVAR | EGW_PSYSFLAG_LOOPAFTRNP | EGW_PSYSFLAG_EMITTOWCS | EGW_PSYSFLAG_ALPHAOUTSHFT | EGW_PSYSFLAG_NOPOINTSPRT;
        sDyn.mParticles = 64;
        sDyn.eDuration.tParticles.origin = 25.0f;
        sDyn.pFrequency.origin =  0.00075;
        sDyn.pFrequency.variant = 0.00015f;
        sDyn.pFrequency.deltaT = 0.10f;
        
        tex = [[egwTexture alloc] initLoadedFromResourceFile:@"/Users/johannes/Documents/Dev/egwAssets/testSmoke.png" withIdentity:@"testSmokeTex" textureEnvironment:0 texturingTransforms:0 texturingFilter:EGW_TEXTURE_FLTR_TRILINEAR texturingSWrap:0 texturingTWrap:0];
        
        testSystem = nil;
        if(testSystem = [[egwParticleSystem alloc] initWithIdentity:@"testSystem" particleDynamics:&pDyn systemDynamics:&sDyn systemBounding:nil geometryStorage:EGW_GEOMETRY_STRG_VBOSTATIC lightStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:tex,0] autorelease]]) {
            [testSystem setRenderingFlags:(EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT | EGW_GFXOBJ_RNDRFLG_SECONDPASS | EGW_OBJEXTEND_FLG_ALWAYSOTGHMG | EGW_OBJEXTEND_FLG_LAZYBOUNDING)];
            [testSystem setActuatorFlags:(EGW_ACTOBJ_ACTRFLG_LOOPING | EGW_ACTOBJ_ACTRFLG_THROTTLE88)];
            //[testSystem setGroundLevel:-0.001f];
            //[testSystem illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testSystem startActuating];
        } [testSystem release]; testSystem = nil;
        [tex release]; tex = nil;
    }
    
    // Create a keyframed mesh object
    {   egwKeyFramedMesh* testMesh = nil;
        egwKFJITVAMeshf kfMesh; egwMeshAllocKFJITVAf(&kfMesh, 4, 4, 4, 2, 2, 2, 2);
        
        egwVecInit3f(&kfMesh.vkCoords[0], -0.5f, 0.0f, 0.5f);
        egwVecInit3f(&kfMesh.vkCoords[1], 0.5f, 0.0f, 0.5f);
        egwVecInit3f(&kfMesh.vkCoords[2], 0.5f, 0.0f, -0.5f);
        egwVecInit3f(&kfMesh.vkCoords[3], -0.5f, 0.0f, -0.5f);
        egwVecInit3f(&kfMesh.vkCoords[4], -0.5f, -0.25f, 0.5f);
        egwVecInit3f(&kfMesh.vkCoords[5], 0.5f, 0.25f, 0.5f);
        egwVecInit3f(&kfMesh.vkCoords[6], 0.5f, -0.25f, -0.5f);
        egwVecInit3f(&kfMesh.vkCoords[7], -0.5f, 0.25f, -0.5f);
        
        egwVecCopy3f(&egwSIVecUnitY3f, &kfMesh.nkCoords[0]);
        egwVecCopy3f(&egwSIVecUnitY3f, &kfMesh.nkCoords[1]);
        egwVecCopy3f(&egwSIVecUnitY3f, &kfMesh.nkCoords[2]);
        egwVecCopy3f(&egwSIVecUnitY3f, &kfMesh.nkCoords[3]);
        egwVecCopy3f(&egwSIVecNegUnitX3f, &kfMesh.nkCoords[4]);
        egwVecCopy3f(&egwSIVecUnitZ3f, &kfMesh.nkCoords[5]);
        egwVecCopy3f(&egwSIVecUnitX3f, &kfMesh.nkCoords[6]);
        egwVecCopy3f(&egwSIVecNegUnitZ3f, &kfMesh.nkCoords[7]);
        
        egwVecInit2f(&kfMesh.tkCoords[0], 0.0f, 1.0f);
        egwVecInit2f(&kfMesh.tkCoords[1], 1.0f / 6.0f, 1.0f);
        egwVecInit2f(&kfMesh.tkCoords[2], 1.0f / 6.0f, 0.0f);
        egwVecInit2f(&kfMesh.tkCoords[3], 0.0f, 0.0f);
        egwVecInit2f(&kfMesh.tkCoords[4], 5.0f / 6.0f, 1.0f);
        egwVecInit2f(&kfMesh.tkCoords[5], 1.0f, 1.0f);
        egwVecInit2f(&kfMesh.tkCoords[6], 1.0f, 0.0f);
        egwVecInit2f(&kfMesh.tkCoords[7], 5.0f / 6.0f, 0.0f);
        
        kfMesh.vtIndicies[0] = 0.0;
        kfMesh.vtIndicies[1] = 2.0;
        kfMesh.ntIndicies[0] = 0.0;
        kfMesh.ntIndicies[1] = 2.0;
        kfMesh.ttIndicies[0] = 0.0;
        kfMesh.ttIndicies[1] = 2.0;
        
        kfMesh.fIndicies[0].face.i1 = 0; kfMesh.fIndicies[0].face.i2 = 1; kfMesh.fIndicies[0].face.i3 = 2;
        kfMesh.fIndicies[1].face.i1 = 0; kfMesh.fIndicies[1].face.i2 = 2; kfMesh.fIndicies[1].face.i3 = 3;
        
        kfMesh.nkfExtraDat = (EGWbyte*)malloc((size_t)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, kfMesh.vCount, EGW_POLATION_IPO_SLERP) * (size_t)kfMesh.nfCount);
        egwIpoSlerpCreateExtFrmDatf((const EGWsingle*)kfMesh.nkCoords, (EGWsingle*)kfMesh.nkfExtraDat, sizeof(egwVector3f), sizeof(egwVector3f) * kfMesh.vCount, egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, EGW_POLATION_IPO_SLERP), egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, kfMesh.vCount, EGW_POLATION_IPO_SLERP), kfMesh.nfCount, kfMesh.vCount, 3);
        
        if(testMesh = [[egwKeyFramedMesh alloc] initWithIdentity:@"testKeyFramedMesh" keyFramedMesh:&kfMesh vertexPolationMode:(EGW_POLATION_IPO_LINEAR | EGW_POLATION_EPO_CONST) normalPolationMode:(EGW_POLATION_IPO_SLERP | EGW_POLATION_EPO_CONST) texturePolationMode:(EGW_POLATION_IPO_LINEAR | EGW_POLATION_EPO_CONST) meshBounding:nil geometryStorage:EGW_GEOMETRY_STRG_VBODYNAMIC lightStack:nil materialStack:nil shaderStack:nil textureStack:[[[egwTextureStack alloc] initWithTextures:(id<egwPTexture>)[egwSIAsstMngr retrieveAsset:@"testBoxTexture"],0] autorelease]]) {
            egwMatrix44f orient; egwMatTranslate44fs(NULL, -1.0f, 0.0f, -1.0f, &orient);
            egwTimer* timer = [[egwTimer alloc] initWithIdentity:@"testKeyFramedMeshTimer"];
            [testMesh setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
            [timer setActuatorFlags:(EGW_ACTOBJ_ACTRFLG_LOOPING | EGW_ACTOBJ_ACTRFLG_NRMLZVECS | EGW_ACTOBJ_ACTRFLG_THROTTLE66)];
            [testMesh setEvaluationTimer:timer];
            [testMesh illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
            [testMesh orientateByTransform:&orient];
            
            [testMesh startRendering];
            [[testMesh evaluationTimer] startActuating];
            
            [timer release]; timer = nil;
        } [testMesh release]; testMesh = nil;
    }
    
    [egwSIAsstMngr loadAssetsFromManifest:@"/Users/johannes/Documents/Dev/egwAssets/CannonTest.gamx"];
    
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Cannon"] setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Cannon"] illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Cannon"] startRendering];
    //[(egwTimer*)[egwSIAsstMngr retrieveAsset:@"tmr_obj_Centroid_SpaceStation"] setExplicitBoundsBegin:EGW_TIME_NAN andEnd:EGW_TIME_NAN];
    //[(egwTimer*)[egwSIAsstMngr retrieveAsset:@"tmr_obj_Centroid_SpaceStation"] startActuating];*/
    
    //[egwSIAsstMngr loadAssetsFromManifest:@"/Users/johannes/Desktop/Stone Tower 1f.gamx"];
    
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Scene"] setRenderingFlags:EGW_GFXOBJ_RNDRFLG_FIRSTPASS];
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Scene"] illuminateWithLight:(id<egwPLight>)[egwSIAsstMngr retrieveAsset:@"testLight"]];
    //[(egwObjectBranch*)[egwSIAsstMngr retrieveAsset:@"obj_Scene"] startRendering];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    printf("applicationDidBecomeActive\r\n");
    [self start];
}

- (void)main { // auto ran in its own thread
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    printf("main\r\n");
    
    [egwSITaskMngr enableAllTasks];
    
    while(![self isCancelled]);
    
    [pool release];
    
    if(![self isCancelled]) {
        if([[UIApplication sharedApplication] respondsToSelector:@selector(terminate)])
            [[UIApplication sharedApplication] performSelector:@selector(terminate)];
        else
            kill(getpid(), SIGINT);
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application {
    printf("applicationDidReceiveMemoryWarning\r\n");
}

- (void)applicationWillTerminate:(UIApplication*)application {
    printf("applicationWillTerminate\r\n");
    [self cancel];
    [egwEngine release];
}

- (BOOL)willFinishInitializingGfxContext:(egwGfxContextEAGLES*)context {
    printf("willFinishInitializingGfxContext\r\n");
    return YES;
}

- (void)didFinishInitializingGfxContext:(egwGfxContextEAGLES*)context {
    printf("didFinishInitializingGfxContext\r\n");
    return;
}

- (BOOL)willShutDownGfxContext:(egwGfxContextEAGLES*)context {
    printf("willShutDownGfxContext\r\n");
    return YES;
}

- (void)didShutDownGfxContext:(egwGfxContextEAGLES*)context {
    printf("didShutDownGfxContext\r\n");
    return;
}

- (void)didUpdateContext:(egwGfxContextEAGLES*)context framesPerSecond:(EGWsingle)fps {
    printf("didUpdateContext:framesPerSecond: %f\r\n", fps);
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    printf("touchesBegan %d\r\n", [touches count]);
    return;
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    printf("touchesCancelled\r\n");
    return;
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    printf("touchesEnded %d\r\n", [touches count]);
    return;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    if([touches count] == 1) {
        CGPoint p1, p2, pd;
        UITouch* touch = [touches anyObject];
        
        p1 = [touch previousLocationInView:nil];
        p2 = [touch locationInView:nil];
        pd = CGPointMake(p2.x - p1.x, p2.y - p1.y);
        
        _yaw = egwRadReduce02PIf(_yaw + ((EGWsingle)pd.x * 0.005f));
        _pitch = egwClampf(_pitch + ((EGWsingle)pd.y * -0.005f), 0.1f, EGW_MATH_PI - 0.1f);
    } else if([touches count] == 2) {
        int i = 0;
        CGPoint p1[2], p2[2];
        EGWsingle d[2], dd;
        
        for(UITouch* touch in [touches objectEnumerator]) {
            p1[i] = [touch previousLocationInView:nil];
            p2[i] = [touch locationInView:nil];
            ++i;
        }
        
        d[0] = sqrtf(((float)(p1[1].x - p1[0].x) * (float)(p1[1].x - p1[0].x)) + ((float)(p1[1].y - p1[0].y) * (float)(p1[1].y - p1[0].y)));
        d[1] = sqrtf(((float)(p2[1].x - p2[0].x) * (float)(p2[1].x - p2[0].x)) + ((float)(p2[1].y - p2[0].y) * (float)(p2[1].y - p2[0].y)));
        dd = d[1] - d[0];
        
        _dist += dd * 0.005f;
    }
    
    egwVector3f camPos; egwVecInit3f(&camPos, egwCosf(_yaw) * egwSinf(_pitch) * _dist, egwCosf(_pitch) * _dist, egwSinf(_yaw) * egwSinf(_pitch) * _dist);
    [[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS] orientateByLookingAt:&egwSIVecZero3f withCameraAt:&camPos];
    
    return;
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
    printf("accelerometer\r\n");
    return;
}

- (void)startedActionAt:(egwPoint2i*)avgPosition pads:(EGWuint)padCount {
    printf("startedActionAt:<%d,%d> pads:<%d>\r\n",
           avgPosition->axis.x, avgPosition->axis.y,
           padCount);
    
    egwLineSegment4f pickRay; pickRay.t = EGW_SFLT_MAX;
    egwOrthogonalCamera* camera = (egwOrthogonalCamera*)[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS];
    [camera pickingRay:(egwRay4f*)&pickRay fromPoint:avgPosition];
    
    if(_hookedObject == nil) {
        egwButton* button = (egwButton*)[egwSIAsstMngr retrieveAsset:@"testButton"];
        if([button tryHookingWithPickingRay:(egwRay4f*)&pickRay])
            [button setPressed:YES];
    }
    
    /*if(_hookedObject == nil) {
        egwSlider* slider = (egwSlider*)[egwSIAsstMngr retrieveAsset:@"testSlider"];
        if([slider tryHookingWithPickingRay:(egwRay4f*)&pickRay])
            [slider setPressed:YES];
    }*/
}

- (void)canceledAction {
    printf("canceledAction\r\n");
    return;
}

- (void)continuedTappingAt:(egwPoint2i*)avgPosition taps:(EGWuint)tapCount time:(EGWtime)elapsed {
    printf("continuedTappingAt:<%d,%d> taps:<%d> time:<%f>\r\n",
           avgPosition->axis.x, avgPosition->axis.y,
           tapCount,
           elapsed);
    
    if(![_hookedObject isKindOfClass:[egwButton class]])
        [_hookedObject unhook];
}

- (void)finishedTappingAt:(egwPoint2i*)avgPosition taps:(EGWuint)tapCount time:(EGWtime)elapsed {
    printf("finishedTappingAt:<%d,%d> taps:<%d> time:<%f>\r\n",
           avgPosition->axis.x, avgPosition->axis.y,
           tapCount,
           elapsed);
    
    egwLineSegment4f pickRay; pickRay.t = EGW_SFLT_MAX;
    egwPerspectiveCamera* camera = (egwPerspectiveCamera*)[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS];
    [camera pickingRay:(egwRay4f*)&pickRay fromPoint:avgPosition];
    
    printf("pickRay:O<%f,%f,%f,%f> N<%f,%f,%f,%f> s<%f> t<%f>\r\n",
           pickRay.line.origin.axis.x, pickRay.line.origin.axis.y, pickRay.line.origin.axis.z, pickRay.line.origin.axis.w,
           pickRay.line.normal.axis.x, pickRay.line.normal.axis.y, pickRay.line.normal.axis.z, pickRay.line.normal.axis.w,
           pickRay.s, pickRay.t);
    
    if([_hookedObject isKindOfClass:[egwButton class]])
        [(egwButton*)_hookedObject press];
    
    [_hookedObject unhook];
}

- (void)continuedSwipingAt:(egwPoint2i*)avgPosition covering:(egwSpan2i*)avgTotalSpan moving:(egwSpan2i*)avgDeltaSpan pads:(EGWuint)padCount time:(EGWtime)elapsed {
    printf("continuedSwipingAt:<%d,%d> covering:<%d,%d,%d,%d> moving:<%d,%d,%d,%d> pads:<%d> time:<%f>\r\n",
           avgPosition->axis.x, avgPosition->axis.y,
           avgTotalSpan->origin.axis.x, avgTotalSpan->origin.axis.y, avgTotalSpan->extents.axis.x, avgTotalSpan->extents.axis.y,
           avgDeltaSpan->origin.axis.x, avgDeltaSpan->origin.axis.y, avgDeltaSpan->extents.axis.x, avgDeltaSpan->extents.axis.y,
           padCount,
           elapsed);
    
    if([_hookedObject isKindOfClass:[egwSlider class]]) {
        egwLineSegment4f pickRay; pickRay.t = EGW_SFLT_MAX;
        egwOrthogonalCamera* camera = (egwOrthogonalCamera*)[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS];
        [camera pickingRay:(egwRay4f*)&pickRay fromPoint:avgPosition];
        
        [_hookedObject updateHookWithPickingRay:(egwRay4f*)&pickRay];
    } else
        [_hookedObject unhook];
    
    if(!_hookedObject) {
        _yaw = egwRadReduce02PIf(_yaw + (avgDeltaSpan->extents.axis.x * 0.005f));
        _pitch = egwClampf(_pitch + (avgDeltaSpan->extents.axis.y * -0.005f), 0.1f, EGW_MATH_PI - 0.1f);
        
        egwVector3f camPos; egwVecInit3f(&camPos, egwCosf(_yaw) * egwSinf(_pitch) * _dist, egwCosf(_pitch) * _dist, egwSinf(_yaw) * egwSinf(_pitch) * _dist);
        [[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS] orientateByLookingAt:&egwSIVecZero3f withCameraAt:&camPos];
    }
}

- (void)finishedSwipingAt:(egwPoint2i*)avgPosition covering:(egwSpan2i*)avgTotalSpan pads:(EGWuint)maxPadCount time:(EGWtime)elapsed {
    printf("finishedSwipingAt:<%d,%d> covering:<%d,%d,%d,%d> pads:<%d> time:<%f>\r\n",
           avgPosition->axis.x, avgPosition->axis.y,
           avgTotalSpan->origin.axis.x, avgTotalSpan->origin.axis.y, avgTotalSpan->extents.axis.x, avgTotalSpan->extents.axis.y,
           maxPadCount,
           elapsed);
    
    [_hookedObject unhook];
}

- (void)continuedPinchingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalDist moving:(EGWsingle)deltaDist time:(EGWtime)elapsed {
    printf("continuedPinchingAt:<%d,%d> covering:<%f> moving:<%f> time:<%f>\r\n",
           ctrPosition->axis.x, ctrPosition->axis.y,
           totalDist, deltaDist,
           elapsed);
    
    [_hookedObject unhook];
    
    if(!_hookedObject) {
        _dist += deltaDist * 0.025f;
        
        egwVector3f camPos; egwVecInit3f(&camPos, egwCosf(_yaw) * egwSinf(_pitch) * _dist, egwCosf(_pitch) * _dist, egwSinf(_yaw) * egwSinf(_pitch) * _dist);
        [[egwSIGfxRdr renderingCameraForQueue:EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS] orientateByLookingAt:&egwSIVecZero3f withCameraAt:&camPos];
    }
}

- (void)finishedPinchingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalDist time:(EGWtime)elapsed {
    printf("finishedPinchingAt:<%d,%d> covering:<%f> time:<%f>\r\n",
           ctrPosition->axis.x, ctrPosition->axis.y,
           totalDist,
           elapsed);

    [_hookedObject unhook];
}

- (void)continuedRotatingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalAngle moving:(EGWsingle)deltaAngle time:(EGWtime)elapsed {
    printf("continuedRotatingAt:<%d,%d> covering:<%f> moving:<%f> time:<%f>\r\n",
           ctrPosition->axis.x, ctrPosition->axis.y,
           totalAngle, deltaAngle,
           elapsed);
    
    [_hookedObject unhook];
}

- (void)finishedRotatingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalAngle time:(EGWtime)elapsed {
    printf("finishedRotatingAt:<%d,%d> covering:<%f> time:<%f>\r\n",
           ctrPosition->axis.x, ctrPosition->axis.y,
           totalAngle,
           elapsed);

    [_hookedObject unhook];
}

- (void)widget:(id<egwPWidget>)widget did:(EGWuint32)action {
    switch(action) {
        case EGW_ACTION_HOOK: {
            printf("Hooked %s\r\n", [[(id<egwPAsset>)widget identity] UTF8String]);
            [widget retain];
            [_hookedObject release];
            _hookedObject = (id<egwPHook>)widget;
        } break;
        
        case EGW_ACTION_UNHOOK: {
            printf("Unhooked %s\r\n", [[(id<egwPAsset>)widget identity] UTF8String]);
            [_hookedObject release];
            _hookedObject = nil;
        } break;
    }
}

- (void)buttonDidPress:(egwButton*)button {
    printf("buttonDidPress\r\n");
    
    [(egwPointSound*)[egwSIAsstMngr retrieveAsset:@"testMusic"] stopPlayback];
    [(egwPointSound*)[egwSIAsstMngr retrieveAsset:@"testSound"] setDelegate:self];
    [(egwPointSound*)[egwSIAsstMngr retrieveAsset:@"testSound"] startPlayback];
}

- (void)sliderDidChange:(egwSlider*)slider toOffset:(EGWsingle)offset {
    printf("sliderDidChange <%f>\r\n", offset);
}

- (void)sound:(id<egwPSound>)sound did:(EGWuint32)action {
    if(action == EGW_ACTION_FINISH) {
        printf("soundDidFinish\r\n");
        [(egwPointSound*)sound setDelegate:nil];
        
        egwSpritedImage* original = (egwSpritedImage*)[egwSIAsstMngr retrieveAsset:@"testSprite"];
        egwSpritedImage* copy = nil;
        
        for(EGWint i = 0; i < 10; ++i) {
            copy = [original copy];
            egwMatrix44f orient; egwMatTranslate44fs(NULL, (1.5f * ((EGWsingle)rand() / (EGWsingle)RAND_MAX)) - 0.75f, (0.5f * ((EGWsingle)rand() / (EGWsingle)RAND_MAX)) - 0.25f, (1.5f * ((EGWsingle)rand() / (EGWsingle)RAND_MAX)) - 0.75f, &orient);
            [copy orientateByTransform:&orient];
            [copy setEvaluationTimer:(id<egwPTimer>)[egwSIAsstMngr retrieveAsset:@"testTimer"]];
            [copy startRendering];
            [copy release];
        }
        
        [original startRendering];
        [(id<egwPTimer>)[egwSIAsstMngr retrieveAsset:@"testTimer"] startActuating];
        [(id<egwPTimer>)[egwSIAsstMngr retrieveAsset:@"tmr_obj_Scene"] startActuating];
    }
}

@end


int main(int argc, char* argv[]) {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    UIApplicationMain(argc, argv, nil, @"egwUnitTestA");
    [pool release];
}

//#endif

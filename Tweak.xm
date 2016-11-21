#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#include <IOKit/hid/IOHIDEventSystem.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>
#include <stdio.h>
#include <dlfcn.h>

@interface SBBannerController : NSObject

+ (SBBannerController *)sharedInstance;
- (BOOL)isShowingBanner;

@end

@interface SBBulletinBannerItem : NSObject
- (void (^)(id, SEL))action;
@end

@interface SBUIBannerContext : NSObject
@property (nonatomic, strong, readonly) SBBulletinBannerItem *item;
@end

typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
typedef void* (*clientCreatePointer)(const CFAllocatorRef);
extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();


void touch_event(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {

    if (IOHIDEventGetType(event) == kIOHIDEventTypeDigitizer) {

        NSArray *children = (NSArray *)IOHIDEventGetChildren(event);
        if ([children count] > 0) {

            CGFloat pressure = IOHIDEventGetFloatValue((__IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerPressure);
            if (pressure >= 1200.0f) {

                if ([[NSClassFromString(@"SBBannerController") sharedInstance] isShowingBanner]) {

                    SBUIBannerContext *bannerContext = [[NSClassFromString(@"SBBannerController") sharedInstance] valueForKey:@"_bannerContext"];

                    if (!bannerContext) {
                        return;
                    }

                    SBBulletinBannerItem *bannerItem = bannerContext.item;
                    if (!bannerItem || [bannerItem action]) {
                        return;
                    }

                    [bannerItem action](0, 0);

                }

            }
        }
    }

}

%ctor {

    clientCreatePointer clientCreate;
    void *handle = dlopen(0, 9);
    *(void**)(&clientCreate) = dlsym(handle,"IOHIDEventSystemClientCreate");
    IOHIDEventSystemClientRef ioHIDEventSystem = (__IOHIDEventSystemClient *)clientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientScheduleWithRunLoop(ioHIDEventSystem, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientRegisterEventCallback(ioHIDEventSystem, (IOHIDEventSystemClientEventCallback)touch_event, NULL, NULL);

}
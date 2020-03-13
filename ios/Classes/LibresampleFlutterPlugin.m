#import "LibresampleFlutterPlugin.h"
#if __has_include(<libresample_flutter/libresample_flutter-Swift.h>)
#import <libresample_flutter/libresample_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "libresample_flutter-Swift.h"
#endif

@implementation LibresampleFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibresampleFlutterPlugin registerWithRegistrar:registrar];
}
@end

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PdfSnapshot, NSObject)

RCT_EXTERN_METHOD(generate:(NSDictionary *)options
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

@end

//
//  ROFastFlags.h
//  RobloxOptimizer
//
//  Automated Roblox ClientAppSettings.json generation and sandbox injection.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ROFastFlags : NSObject

+ (NSDictionary<NSString *, id> *)currentFlagsDictionary;
+ (BOOL)writeFastFlagsConfigurationWithError:(NSError * _Nullable * _Nullable)error;
+ (NSString *)bundleSettingsPath;
+ (NSString *)documentsSettingsPath;
+ (NSString *)applicationSupportSettingsPath;

@end

NS_ASSUME_NONNULL_END

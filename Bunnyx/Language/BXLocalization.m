//
//  BXLocalization.m
//  Bunnyx
//

#import "BXLocalization.h"
#import "LanguageManager.h"

static NSBundle *BXCurrentLanguageBundle(void) {
    NSString *code = [LanguageManager sharedManager].currentLanguageCode;
    if (code.length == 0) {
        return [NSBundle mainBundle];
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:code ofType:@"lproj"];
    NSBundle *bundle = path ? [NSBundle bundleWithPath:path] : nil;
    return bundle ?: [NSBundle mainBundle];
}

NSString *BXLocalizedString(NSString *key) {
    if (key.length == 0) { return @""; }
    NSBundle *bundle = BXCurrentLanguageBundle();
    return NSLocalizedStringFromTableInBundle(key, nil, bundle, nil);
}



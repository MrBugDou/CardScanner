//
//  DDCardScanner.h
//  DDCardScanner
//
//  Created by DouDou on 2022/6/23.
//
#import <Foundation/Foundation.h>

//! Project version number for DDCardScanner.
FOUNDATION_EXPORT double DDCardScannerVersionNumber;

//! Project version string for WeCash.
FOUNDATION_EXPORT const unsigned char DDCardScannerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DDCardScanner/PublicHeader.h>

#if __has_include(<DDCardScanner/exbankcard.h>)

#import <DDCardScanner/exbankcard.h>

#elif __has_include("exbankcard.h")

#import "exbankcard.h"

#endif

#if __has_include(<DDCardScanner/excards.h>)

#import <DDCardScanner/excards.h>

#elif __has_include("excards.h")

#import "excards.h"

#endif

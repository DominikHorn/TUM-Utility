//
//  PDFParser.h
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFParser : NSObject

- (NSString*)getPdfString:(NSURL*)url;

@end

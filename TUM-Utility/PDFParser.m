//
//  PDFParser.m
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDFParser.h"
#import "TET_ios/TET_objc.h"

@implementation PDFParser

- (NSString*)getPdfString:(NSURL*)url {
    /* global option list */
    NSString *globaloptlist =
    [NSString stringWithFormat:@"searchpath={{%@} {%@/extractor_ios.app} {%@/extractor_ios.app/resource/cmap}}",
     url, NSHomeDirectory(), NSHomeDirectory()];
    
    /* option list to switch on TET logging */
    //NSString *loggingoptlist = [NSString stringWithFormat:@"logging {filename={%@/trace.txt} remove}", documentsDir];
    
    /* document-specific option list */
    NSString *docoptlist = @"";
    
    /* page-specific option list */
    NSString *pageoptlist = @"granularity=page";
    
    /* separator to emit after each chunk of text. This depends on the
     * application's needs;
     * for granularity=word a space character may be useful.
     */
#define SEPARATOR @"\n"
    
    int pageno = 0;
    NSMutableString *pdfText = [[NSMutableString alloc]init];;
    NSString *warningText=@"";
    
    TET *tet = [[TET alloc] init];
    if (!tet) {
        return nil;
    }
    
    @try {
        NSInteger n_pages;
        NSInteger doc;
        
        //[tet set_option:loggingoptlist];
        [tet set_option:globaloptlist];
        
        doc = [tet open_document:[url path] optlist:docoptlist];
        
        if (doc == -1)
        {
            warningText = [NSString stringWithFormat:@"Error %ld in %@(): %@\n",
                           (long)[tet get_errnum], [tet get_apiname], [tet get_errmsg]];
            NSLog(@"%@", warningText);
            return nil;
        }
        
        /* get number of pages in the document */
        n_pages = (NSInteger) [tet pcos_get_number:doc path:@"length:pages"];
        
        /* loop over pages in the document */
        for (pageno = 1; pageno <= n_pages; ++pageno)
        {
            NSString *text;
            NSInteger page;
            
            page = [tet open_page:doc pagenumber:pageno optlist:pageoptlist];
            
            if (page == -1)
            {
                warningText = [NSString stringWithFormat:@"%@\nError %ld in %@() on page %d: %@\n",
                               warningText, (long)[tet get_errnum], [tet get_apiname], pageno, [tet get_errmsg]];
                continue;                        /* try next page */
            }
            
            /* Retrieve all text fragments; This is actually not required
             * for granularity=page, but must be used for other granularities.
             */
            while ((text = [tet get_text:page]) != nil)
            {
                [pdfText appendString:text];
                [pdfText appendString:SEPARATOR];
            }
            
            if ([tet get_errnum] != 0)
            {
                warningText  = [NSString stringWithFormat:@"%@\nError %ld in %@() on page %d: %@\n", warningText, (long)[tet get_errnum], [tet get_apiname], pageno, [tet get_errmsg]];
            }
            
            [tet close_page:page];
        }
        
        [tet close_document:doc];
    }
    
    @catch (TETException *ex) {
        NSString *exception=@"";
        if (pageno == 1) {
            exception = [NSString stringWithFormat:@"Error %ld in %@(): %@\n",
                         (long)[ex get_errnum], [ex get_apiname], [ex get_errmsg]];
        } else {
            exception = [NSString stringWithFormat:@"Error %ld in %@() on page %d: %@\n",
                         (long)[ex get_errnum], [ex get_apiname], pageno, [ex get_errmsg]];
        }
        NSLog(@"TETException occured: %@", exception);
    }
    @catch (NSException *ex) {
        NSLog(@"NSException occured because %@", [ex reason]);
    }
    @finally {
        if (tet)
            tet = nil;
    }
    
    
    /* show the warning(s) that occured while processing the file */
    if (warningText.length>0) {
        NSLog(@"%@", warningText);
    }
    
    return pdfText;
}

@end

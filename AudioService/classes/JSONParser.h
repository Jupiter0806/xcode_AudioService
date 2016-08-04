//
//  JSONParser.h
//  playground
//
//  Created by Jupiter Li on 3/08/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONParser : NSObject

@property (readonly) NSString *json_str;

- (id) initWithJSONStr: (NSString *)json_str;

- (int) getIntegerValueOfKey: (NSString *)key;
- (NSString *) getStringValueOfKey: (NSString *)key;
- (NSArray *) getArrayValueOfKey: (NSString *)key;

@end

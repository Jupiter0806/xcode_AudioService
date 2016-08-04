//
//  JSONParser.m
//  playground
//
//  Created by Jupiter Li on 3/08/2016.
//  Copyright © 2016 Jupiter Li. All rights reserved.
//

#import "JSONParser.h"

@interface JSONParser()  {
    NSDictionary *res;
}

@end

@implementation JSONParser

- (id) initWithJSONStr: (NSString *)json_str {
    NSLog(@"Initialise a json parser with string %@", json_str);
    
    self = [super init];
    
    _json_str = json_str;
    
    NSData *data = [json_str dataUsingEncoding:NSUTF8StringEncoding];
    
    if (NSClassFromString(@"NSJSONSerialization")) {
        
        NSError *error = nil;
        
        id object = [NSJSONSerialization
                     JSONObjectWithData:data
                     options:0
                     error:&error];
        
        if (error) {
            NSLog(@"Parsing json in string to object failed");
        }
        
        if ([object isKindOfClass:[NSDictionary class]]) {
            res = object;
        
        } else {
            NSLog(@"The parsing result is not in format of NSDictionary.");
        }
    } else {
        NSLog(@"NSJSONSerialization is not available.");
    }
    
    return self;
}

- (int) getIntegerValueOfKey: (NSString *)key {
    return [[res objectForKey:key] integerValue];
}
- (NSString *) getStringValueOfKey : (NSString *)key {
    return [res objectForKey:key];
}
- (NSArray *) getArrayValueOfKey: (NSString *)key {
    return [res objectForKey:key];
}

@end

//
//  Controller.m
//
//  Created by Paul Kim on 8/21/09.
//  Copyright 2009 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "Controller.h"
#import "CAPWebService.h"
#import "NSDate-Utilities.h"

NSString *const kUserStorageKey = @"user";

@implementation Controller

- (void)awakeFromNib
{
    if ([[NSUserDefaults standardUserDefaults] stringForKey:kUserStorageKey]) {
        _userTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUserStorageKey];
    }
}

- (IBAction)goButtonClicked:(id)sender
{
    _password = _passTextField.stringValue;
    _username = _userTextField.stringValue;
    
    _progressLabel.stringValue = @"";
    
    [_goButton setTitle:@"go"];
    
    _mergeRequest = _checkBox.state == NSOnState;
    
    [[NSUserDefaults standardUserDefaults] setValue:_userTextField.stringValue forKey:kUserStorageKey];
    
    NSInteger day = [[NSDate date] weekday];
    
    NSDate *startDate = [[NSDate dateWithDaysBeforeNow:day] dateAtStartOfDay];
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    
    NSString *startString = [formatter stringFromDate:startDate];
    NSString *endString = [formatter stringFromDate:[NSDate date]];
    
    NSDictionary *payLoad = @{@"pass" : _passTextField.stringValue,
                              @"user" : _userTextField.stringValue,
                              @"start" : startString,
                              @"end" : endString};
    
    [[CAPWebService sharedWebService] makeRequestForTarget:self
                                               requestType:kCAPRequestTypeTimeEntries
                                               withPayLoad:payLoad
                                                usingBlock:^(id responseData, NSError *error) {
                                                    if (!error) {
                                                        [self gotTimes:responseData];
                                                    }
                                                    else {
                                                        [_goButton setTitle:@"error"];
                                                    }
                                                }];
    
}

- (BOOL)_isHeader:(NSInteger)rowIndex
{
    return [_timesAndHeaders[rowIndex] isKindOfClass:[NSDate class]];
}

#pragma mark NSTableDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _timesAndHeaders.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEEE, dd. MMMM"];

    id time = _timesAndHeaders[rowIndex];
              
    if ([time isKindOfClass:[NSDate class]]) {
        return [formatter stringFromDate:_timesAndHeaders[rowIndex]];
    }
    else {
        return [NSString stringWithFormat:@"%.02f %@ - %@ ", [time[@"duration"] floatValue] / (60 * 60),
                (time[@"projectName"] == [NSNull null] ? @"(no project)" : time[@"projectName"]),
                (time[@"description"] == [NSNull null] ? @"(no description)" : time[@"description"])];
        
    }
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	return [self _isHeader:row];
}

#pragma mark Private methods

- (void)gotTimes:(NSArray *)array
{
    NSMutableArray *timesAndHeadersBuilder = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    
    __block NSDate *currentDayDate;
    
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSDate *startDate = [formatter dateFromString:obj[@"start"]];
        NSDate *endDate = [formatter dateFromString:obj[@"stop"]];
        
        if (idx == 0) {
            [timesAndHeadersBuilder addObject:startDate];
            currentDayDate = startDate;
        }
        
        long pID = [obj[@"pid"] longValue];

        NSMutableDictionary *time = @{
                                      @"start" : startDate,
                                      @"end" : endDate ? endDate : [NSNull null],
                                      @"duration" : @([obj[@"duration"] integerValue]),
                                      @"pID" : pID == 0 ? [NSNull null] : @(pID),
                                      @"projectName" : [NSNull null],
                                      @"description" : obj[@"description"] ? obj[@"description"] : [NSNull null]
                                      }.mutableCopy; //to add project name later
        
        if (currentDayDate.weekday != startDate.weekday) {
            [timesAndHeadersBuilder addObject:startDate];
        }
        [timesAndHeadersBuilder addObject:time];        
        currentDayDate = startDate;
    }];
    
    _timesAndHeaders = timesAndHeadersBuilder;
    
    if (_mergeRequest) {
        [self mergeDayTimes];
    }
    
    [self getProjectsForTimes:_timesAndHeaders];
    
    [_tableView reloadData];
}

- (void)getProjectsForTimes:(NSArray *)times
{
    NSMutableArray *pIDs = [NSMutableArray array];
    
    [_timesAndHeaders enumerateObjectsUsingBlock:^(id time, NSUInteger idx, BOOL *stop) {
        if (![time isKindOfClass:[NSDate class]]) {
            if (![pIDs containsObject:time[@"pID"]] && time[@"pID"] != [NSNull null]) {
                [pIDs addObject:time[@"pID"]];
            }
        }
    }];
    
    __block NSMutableArray *projectsBuilder = [NSMutableArray array];
    
    [pIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *payLoad = @{@"pass" : _passTextField.stringValue,
                                  @"user" : _userTextField.stringValue,
                                  @"pID" : [pIDs[idx] stringValue]};
        
        
        [[CAPWebService sharedWebService] makeRequestForTarget:self
                                                   requestType:kCAPRequestTypeProjectDetails
                                                   withPayLoad:payLoad
                                                    usingBlock:^(id responseData, NSError *error) {
                                                        if (!error) {
                                                            [projectsBuilder addObject:responseData];
                                                        }
                                                        else {
                                                            [_goButton setTitle:@"error"];
                                                        }
                                                        
                                                        if (projectsBuilder.count == pIDs.count) {
                                                            [self didGetProjects:projectsBuilder];
                                                        }
                                                    }];
    }];
}

- (void)didGetProjects:(NSArray *)projects
{
    __block CGFloat totalDuration = 0.0f;

    [_timesAndHeaders enumerateObjectsUsingBlock:^(id time, NSUInteger idx, BOOL *stop) {
        if (![time isKindOfClass:[NSDate class]]) {
            if (time[@"pID"] != [NSNull null]) {
                __block BOOL set = NO;
                [projects enumerateObjectsUsingBlock:^(NSDictionary *project, NSUInteger idx2, BOOL *stop2) {
                    NSNumber *pID = project[@"data"][@"id"];
                    
                    if ([project[@"data"][@"billable"] boolValue] && !set) {
                        totalDuration += [time[@"duration"] integerValue] / (60.0f * 60.0f);
                        set = YES;
                    }
                    
                    if ([pID isEqualToNumber:time[@"pID"]]) {
                        [time addEntriesFromDictionary:@{@"projectName" : project[@"data"][@"name"]}];
                    }
                }];
            }
        }
    }];
    
    _progressLabel.stringValue = [NSString stringWithFormat:@"total billable: %.02f", totalDuration];

    _projects = projects;
    [_tableView reloadData];
}

- (void)mergeDayTimes
{
    __block NSMutableArray *timesAndHeadersBuilder = [NSMutableArray array];
    __block NSMutableDictionary *projectsBuilder;
    
    [_timesAndHeaders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDate class]]) {
            [timesAndHeadersBuilder addObject:obj];
            projectsBuilder = [NSMutableDictionary dictionary];
        }
        else {
            if (obj[@"pID"] != [NSNull null]) {
                if ([projectsBuilder objectForKey:obj[@"pID"]]) {
                    [projectsBuilder[obj[@"pID"]] addObject:obj];
                }
                else {
                    NSMutableArray *projectTimes = @[obj].mutableCopy;
                    [projectsBuilder addEntriesFromDictionary:@{obj[@"pID"] : projectTimes}];
                }
                if (idx == _timesAndHeaders.count - 1 || [_timesAndHeaders[idx + 1] isKindOfClass:[NSDate class]]) {
                    
                    [projectsBuilder enumerateKeysAndObjectsUsingBlock:^(id key, id obj2, BOOL *stop1) {
                        
                        __block CGFloat duration;
                        [obj2 enumerateObjectsUsingBlock:^(id projectTime, NSUInteger idx2, BOOL *stop2) {
                            duration += [projectTime[@"duration"] floatValue];
                        }];
                        
                        
                        [timesAndHeadersBuilder addObject:@{
                         @"start" : [NSNull null],
                         @"end" : [NSNull null],
                         @"duration" : @(duration),
                         @"pID" : key,
                         @"projectName" : [NSNull null],
                         @"description" : [NSNull null]
                         }.mutableCopy];
                    }];
                }
            }
            else {
                [timesAndHeadersBuilder addObject:obj];
            }
        }
    }];
    
    _timesAndHeaders = timesAndHeadersBuilder;
}

@end

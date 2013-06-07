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
NSString *const kPassStorageKey = @"pass";

@implementation Controller

- (void)awakeFromNib
{
    if ([[NSUserDefaults standardUserDefaults] stringForKey:kUserStorageKey]) {
        _userTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUserStorageKey];
    }

    if ([[NSUserDefaults standardUserDefaults] stringForKey:kPassStorageKey]) {
        _passTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kPassStorageKey];
        _rememberPass.state = NSOnState;
    }
}

- (IBAction)goButtonClicked:(id)sender
{
    _password = _passTextField.stringValue;
    _username = _userTextField.stringValue;
    
    _progressLabel.stringValue = @"";
    _goButton.title = @"...";
    
    _mergeRequest = (_checkBox.state == NSOnState);

        // Saves the username and if needed - password also
    [[NSUserDefaults standardUserDefaults] setValue:_username forKey:kUserStorageKey];

    if (_rememberPass.state == NSOnState) {
        [[NSUserDefaults standardUserDefaults] setValue:_password forKey:kPassStorageKey];
    }

        // And makes the request thingies
    NSInteger day = [[NSDate date] weekday];
    NSDate *startDate = [[NSDate dateWithDaysBeforeNow:day] dateAtStartOfDay];
    NSDateFormatter *formatter = [NSDateFormatter new];
    
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    
    NSString *startString = [formatter stringFromDate:startDate];
    NSString *endString = [formatter stringFromDate:[NSDate date]];
    
    NSDictionary *payLoad = @{@"pass" : _passTextField.stringValue,
                              @"user" : _userTextField.stringValue,
                              @"start" : startString,
                              @"end" : endString};
    
    [[CAPWebService sharedWebService] makeRequestForTarget:self requestType:kCAPRequestTypeTimeEntries withPayLoad:payLoad usingBlock:^(id responseData, NSError *error) {
        if (!error) {
            [self gotTimes:responseData];

            _goButton.title = @"refresh";
        }
        else {
            _goButton.title = @"error";
        }
    }];
}

- (BOOL)isHeader:(NSInteger)rowIndex
{
    return [_timesAndHeaders[rowIndex] isKindOfClass:[NSDate class]];
}

- (void)wantedDecimalsCountChanged:(NSStepper *)stepper
{
    [_tableView reloadData];
}

#pragma mark NSTableDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _timesAndHeaders.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id time = _timesAndHeaders[rowIndex];

    if ([time isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"EEEE, dd. MMMM";

        return [formatter stringFromDate:_timesAndHeaders[rowIndex]];
    }
    else if ([time[@"duration"] doubleValue] < 0.0f) {
        return [NSString stringWithFormat:@"... %@", time[@"projectName"]];
    }
    else {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSString *numberOfDecimals = @"";

        for (int i = 0; i <= _stepper.integerValue; i++) {
            if (i == 1) {
                numberOfDecimals = @".0";
            }
            else if (i > 1) {
                numberOfDecimals = [NSString stringWithFormat:@"%@0", numberOfDecimals];
            }
        }

        formatter.format = [NSString stringWithFormat:@"###0%@", numberOfDecimals];

        return [NSString stringWithFormat:@"%@ %@ %@ %@ ",
                [formatter stringFromNumber:@([time[@"duration"] doubleValue] / (60.0f * 60.0f))],
                ((time[@"projectName"] == [NSNull null]) ? @"" : time[@"projectName"]),
                ((time[@"description"] == [NSNull null]) ? @"" : @"-"),
                ((time[@"description"] == [NSNull null]) ? @"" : time[@"description"])];
    }
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	return [self isHeader:row];
}

#pragma mark Private methods

- (void)gotTimes:(NSArray *)array
{
    NSMutableArray *timesAndHeadersBuilder = [NSMutableArray array];
    NSDateFormatter *formatter = [NSDateFormatter new];
    
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
    
    __block NSDate *currentDayDate;
    
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSDate *startDate = [formatter dateFromString:obj[@"start"]];
        NSDate *endDate = [formatter dateFromString:obj[@"stop"]];
        long pID = [obj[@"pid"] longValue];
        
        if (idx == 0) {
            [timesAndHeadersBuilder addObject:startDate];
            currentDayDate = startDate;
        }

        NSMutableDictionary *time = @{@"start" : startDate,
                                      @"end" : ((endDate) ? endDate : [NSNull null]),
                                      @"duration" : @([obj[@"duration"] integerValue]),
                                      @"pID" : ((pID == 0) ? [NSNull null] : @(pID)),
                                      @"projectName" : [NSNull null],
                                      @"description" : ((obj[@"description"]) ? obj[@"description"] : [NSNull null])}.mutableCopy; //to add project name later
        
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
            if (![pIDs containsObject:time[@"pID"]] && (time[@"pID"] != [NSNull null])) {
                [pIDs addObject:time[@"pID"]];
            }
        }
    }];
    
    __block NSMutableArray *projectsBuilder = [NSMutableArray array];
    
    [pIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *payLoad = @{@"pass" : _passTextField.stringValue,
                                  @"user" : _userTextField.stringValue,
                                  @"pID" : [pIDs[idx] stringValue]};

        _goButton.title = @"...";

        [[CAPWebService sharedWebService] makeRequestForTarget:self requestType:kCAPRequestTypeProjectDetails withPayLoad:payLoad usingBlock:^(id responseData, NSError *error) {
            if (!error) {
                [projectsBuilder addObject:responseData];

                _goButton.title = @"refresh";
            }
            else {
                _goButton.title = @"error";
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
                        CGFloat duration = [time[@"duration"] integerValue] / (60.0f * 60.0f);
                        totalDuration += (duration > 0.0f) ? duration : 0.0f;
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

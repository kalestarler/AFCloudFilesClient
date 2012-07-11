//
//  AFCloudFilesClient.m
//
//  Created by kalestarler on 28/6/12.
//

#import "AFCloudFilesClient.h"

#define CLOUDFILES_AUTH_URL @"https://auth.api.rackspacecloud.com/v1.0"

@implementation AFCloudFilesClient

@synthesize cfUsername, cfAPIKey, authToken, storageURL, cdnManagementURL;
@synthesize cfClient, delegate, progressBar;

-(void)dealloc {
    
    [cfUsername release];
    [cfAPIKey release];
    [authToken release]; 
    [storageURL release];
    [cdnManagementURL release];
    [cfClient release];
    [delegate release];
    
    [super dealloc];
}

-(id)initWithUsername:(NSString *)username andKey:(NSString *)apiKey {
    
    [super init];
    if(self) {
        
        cfUsername = [[NSString alloc] initWithString:username];
        cfAPIKey = [[NSString alloc] initWithString:apiKey];
        authToken = [[NSString alloc] init];
        storageURL = [[NSString alloc] init];
        cdnManagementURL = [[NSString alloc] init];
        cfClient = [[AFHTTPClient alloc] init];
        progressBar = [[UIProgressView alloc] init];
        
    }
    return self;
}

-(void)authenticate {
    
    BOOL authenticated = NO;
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceAuthTokenExpiryKey"]) {
        
        NSDate *currentDate = [NSDate date];
        NSDate *expiryDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceAuthTokenExpiryKey"];
        NSDate *expiryDatePlusOneDay = [expiryDate dateByAddingTimeInterval:60*60*24];
        
        if([expiryDatePlusOneDay compare:currentDate] == NSOrderedAscending) {
            //expiry is earlier
            authenticated = NO;
        }
        else if([expiryDatePlusOneDay compare:currentDate] == NSOrderedDescending) {
            //expiry is later
            authenticated = YES;
        }
    }
    
    if(!authenticated) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:CLOUDFILES_AUTH_URL]];
        [request setValue:cfUsername forHTTPHeaderField:@"X-Auth-User"];
        [request setValue:cfAPIKey forHTTPHeaderField:@"X-Auth-Key"];
        
        AFHTTPRequestOperation *authOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [authOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            authToken = [[operation.response allHeaderFields] objectForKey:@"X-Auth-Token"];
            storageURL = [[operation.response allHeaderFields] objectForKey:@"X-Storage-Url"];
            cdnManagementURL = [[operation.response allHeaderFields] objectForKey:@"X-CDN-Management-Url"];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"AFRackspaceAuthTokenExpiryKey"];
            [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:@"AFRackspaceAuthTokenKey"];
            [[NSUserDefaults standardUserDefaults] setObject:storageURL forKey:@"AFRackspaceStorageURLKey"];
            [[NSUserDefaults standardUserDefaults] setObject:cdnManagementURL forKey:@"AFRackspaceCDNManagementURLKey"];
            
            if([delegate respondsToSelector:@selector(AFCloudFilesClientAuthenticationSucceeded:)]) {
                
                [delegate AFCloudFilesClientAuthenticationSucceeded:self];
            }
        } 
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          
                                          if([delegate respondsToSelector:@selector(AFCloudFilesClientAuthenticationFailed:)]) {
                                              
                                              [delegate AFCloudFilesClientAuthenticationFailed:self];
                                          }
                                      }];
        
        [authOp start];
        [request release];
        [authOp release];
    }
    else {
        
        authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceAuthTokenKey"];
        storageURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceStorageURLKey"];
        cdnManagementURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceCDNManagementURLKey"];
        
        if([delegate respondsToSelector:@selector(AFCloudFilesClientAuthenticationSucceeded:)]) {
            
            [delegate AFCloudFilesClientAuthenticationSucceeded:self];
        }
    }
}

-(void)uploadFileToContainer:(NSString *)container withFilename:(NSString *)filename data:(NSData *)data andContentType:(NSString *)contentType {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", storageURL, container, filename];
    NSURL *uploadURLAndPath = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:uploadURLAndPath];
    [request setValue:authToken forHTTPHeaderField:@"X-Auth-Token"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:data];
    
    AFHTTPRequestOperation *uploadOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [uploadOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if([delegate respondsToSelector:@selector(AFCloudFilesClient:withAFHTTPRequestOperation:completedUploadWithResponse:)]) {
            
            [delegate AFCloudFilesClient:self withAFHTTPRequestOperation:operation completedUploadWithResponse:responseObject];
        }
    
    } 
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        
                                        if([delegate respondsToSelector:@selector(AFCloudFilesClient:withAFHTTPRequestOperation:failedUploadWithError:)]) {
                                            
                                            [delegate AFCloudFilesClient:self withAFHTTPRequestOperation:operation failedUploadWithError:error];
                                        }
                                    }];
    [uploadOp setUploadProgressBlock:^(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        progressBar.progress = totalBytesWritten/totalBytesExpectedToWrite;
    }];
    
    [uploadOp start];
    [request release];
    [uploadOp release];
}

-(void)setProgressBar:(UIProgressView *)appProgressBar {
    
    progressBar = appProgressBar;
}

@end

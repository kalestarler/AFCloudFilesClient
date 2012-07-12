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
        
        authenticated = NO;
        cfUsername = [[NSString alloc] initWithString:username];
        cfAPIKey = [[NSString alloc] initWithString:apiKey];
        authToken = [[NSString alloc] init];
        storageURL = [[NSString alloc] init];
        cdnManagementURL = [[NSString alloc] init];
        cfClient = [[AFHTTPClient alloc] init];
        progressBar = [[UIProgressView alloc] init];
        [self authenticate];
    }
    return self;
}

#pragma mark - authentication

-(void)authenticate {
    
    //check for saved auth token first
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
            
            authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceAuthTokenKey"];
            storageURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceStorageURLKey"];
            cdnManagementURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"AFRackspaceCDNManagementURLKey"];
            
            authenticated = YES;
        }
    }
    
    //if there is no valid saved auth token, acquire new one
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
            
            authenticated = YES;
        } 
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          
                                          //if fail, try to authenticate again
                                          [self performSelector:@selector(authenticate) withObject:nil afterDelay:1.0];
                                      }];
        
        [authOp start];
        [request release];
        [authOp release];
    }
}

#pragma mark - upload file to container

-(void)uploadFileToContainer:(NSString *)container withFilename:(NSString *)filename data:(NSData *)data andContentType:(NSString *)contentType {
    
    if (!authenticated) {
        
        if([delegate respondsToSelector:@selector(AFCloudFilesClient:withAFHTTPRequestOperation:failedUploadWithError:)]) {
            
            NSError *error = [[NSError alloc] init];
            [error setValue:@"AFCloudFilesClient not authenticated. Upload operation aborted." forKey:NSLocalizedDescriptionKey];
            
            [delegate AFCloudFilesClient:self withAFHTTPRequestOperation:nil failedUploadWithError:error];
            
            [error release];
        }
    }
    else {
            
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
}

-(void)setProgressBar:(UIProgressView *)appProgressBar {
    
    progressBar = appProgressBar;
}

#pragma mark - retrieve object from container

-(void)retrieveImageWithFilename:(NSString *)filename fromContainer:(NSString *)container {
    
     __block UIImage *image;
    
    if (!authenticated) {
        
        if([delegate respondsToSelector:@selector(AFCloudFilesClient:withAFHTTPRequestOperation:failedDownloadWithError:)]) {
            
            NSError *error = [[NSError alloc] init];
            [error setValue:@"AFCloudFilesClient not authenticated. Download operation aborted." forKey:NSLocalizedDescriptionKey];
            
            [delegate AFCloudFilesClient:self withAFHTTPRequestOperation:nil failedDownloadWithError:error];
            
            [error release];
        }
    }
    else {
        
        NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", storageURL, container, filename];
        NSURL *downloadURLAndPath = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:downloadURLAndPath];
        [request setValue:authToken forHTTPHeaderField:@"X-Auth-Token"];
        [request setHTTPMethod:@"GET"];
        
        AFHTTPRequestOperation *downloadOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [downloadOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            UIImage *responseImage = [[UIImage alloc] initWithData:responseObject];
            image = responseImage;
            [responseImage release];
            
            if ([delegate respondsToSelector:@selector(retrievedImage:WithFilename:fromContainer:)]) {
                
                [delegate retrievedImage:image WithFilename:filename fromContainer:container];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            if([delegate respondsToSelector:@selector(AFCloudFilesClient:withAFHTTPRequestOperation:failedDownloadWithError:)]) {
            
                [delegate AFCloudFilesClient:self withAFHTTPRequestOperation:operation failedDownloadWithError:error];
            }
        }];
        
        [downloadOp start];
        [request release];
        [downloadOp release];
    }
}

@end

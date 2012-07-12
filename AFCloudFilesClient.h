//
//  AFCloudFilesClient.h
//
//  Created by kalestarler on 28/6/12.
//

#import <UIKit/UIKit.h>
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@protocol AFCloudFilesClientDelegate;

@interface AFCloudFilesClient : NSObject {
    
    BOOL authenticated;
}

@property(nonatomic, retain) NSString *cfUsername;
@property(nonatomic, retain) NSString *cfAPIKey;
@property(nonatomic, retain) NSString *authToken;
@property(nonatomic, retain) NSString *storageURL;
@property(nonatomic, retain) NSString *cdnManagementURL;
@property(nonatomic, retain) AFHTTPClient *cfClient;
@property(nonatomic, retain) id<AFCloudFilesClientDelegate> delegate;
@property(nonatomic, retain) UIProgressView *progressBar;

-(id)initWithUsername:(NSString *)username andKey:(NSString *)apiKey;
-(void)authenticate;

-(void)uploadFileToContainer:(NSString *)container withFilename:(NSString *)filename data:(NSData *)data andContentType:(NSString *)contentType;
-(void)setProgressBar:(UIProgressView *)appProgressBar;

-(void)retrieveImageWithFilename:(NSString *)filename fromContainer:(NSString *)container;

@end

@protocol AFCloudFilesClientDelegate <NSObject>
@optional

-(void)AFCloudFilesClient:(AFCloudFilesClient *)client withAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation completedUploadWithResponse:(id)responseObject;
-(void)AFCloudFilesClient:(AFCloudFilesClient *)client withAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation failedUploadWithError:(NSError *)error;

-(void)retrievedImage:(UIImage *)image WithFilename:(NSString *)filename fromContainer:(NSString *)container;
-(void)AFCloudFilesClient:(AFCloudFilesClient *)client withAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation failedDownloadWithError:(NSError *)error;

@end

//
//  AFCloudFilesClient.h
//
//  Created by kalestarler on 28/6/12.
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@protocol AFCloudFilesClientDelegate;

@interface AFCloudFilesClient : NSObject {

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
-(void)uploadImageToContainer:(NSString *)container withFilename:(NSString *)filename data:(NSData *)data andContentType:(NSString *)contentType;
-(void)setProgressBar:(UIProgressView *)appProgressBar;

@end

@protocol AFCloudFilesClientDelegate <NSObject>
-(void)AFCloudFilesClientAuthenticationSucceeded:(AFCloudFilesClient *)client;
-(void)AFCloudFilesClientAuthenticationFailed:(AFCloudFilesClient *)client;
@optional
-(void)AFCloudFilesClient:(AFCloudFilesClient *)client withAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation completedUploadWithResponse:(id)responseObject;
-(void)AFCloudFilesClient:(AFCloudFilesClient *)client withAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation failedUploadWithError:(NSError *)error;

@end

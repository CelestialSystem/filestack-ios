//
//  Filestack.m
//  Filestack
//
//  Created by Łukasz Cichecki on 20/01/16.
//  Copyright © 2016 Filestack. All rights reserved.
//

#import "Filestack.h"
#import "FSAPIURL.h"
#import "FSAPIClient.h"
#import "FSSessionSettings.h"
#import <AFNetworking/AFNetworking.h>

@interface Filestack ()

@property (nonatomic, strong) NSString *apiKey;

@end

@implementation Filestack

- (instancetype)initWithApiKey:(NSString *)apiKey andDelegate:(id <FSFilestackDelegate>)delegate {
    if (self = [super init]) {
        self.apiKey = apiKey;
        self.delegate = delegate;
    }
    return self;
}

- (instancetype)initWithApiKey:(NSString *)apiKey {
    return [self initWithApiKey:apiKey andDelegate:nil];
}

- (void)pickURL:(NSString *)url completionHandler:(void (^)(FSBlob *blob, NSError *error))completionHandler {
    NSDictionary *parameters = @{@"key": _apiKey, @"url": url};
    NSDictionary *sessionSettings = @{FSSessionSettingsURIParams: @YES};
    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];

    [apiClient POST:FSURLPickPath parameters:parameters options:nil sessionSettings:sessionSettings completionHandler:^(FSBlob *blob, NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegatePickSuccess:blob];
        }
        completionHandler(blob, error);
    }];
}

- (void)remove:(FSBlob *)blob completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *deleteURL = [FSAPIURL URLFilePathWithBlobURL:blob.url];
    NSDictionary *parameters = @{@"key": _apiKey};

    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];
    [apiClient DELETE:deleteURL parameters:parameters completionHandler:^(NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegateRemoveSuccess];
        }
        completionHandler(error);
    }];
}

- (void)stat:(FSBlob *)blob withOptions:(FSStatOptions *)statOptions completionHandler:(void (^)(FSMetadata *metadata, NSError *error))completionHandler {
    NSDictionary *sessionSettings = @{FSSessionSettingsBaseURL: blob.url, FSSessionSettingsURIParams: @NO};
    NSDictionary *parameters = [statOptions toQueryParameters];
    NSString *statURL = [FSAPIURL URLMetadataPathWithBlobURL:blob.url];

    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];
    [apiClient GET:statURL parameters:parameters options:statOptions sessionSettings:sessionSettings completionHandler:^(FSMetadata *metadata, NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegateStatSuccess:metadata];
        }
        completionHandler(metadata, error);
    }];
}

- (void)download:(FSBlob *)blob completionHandler:(void (^)(NSData *data, NSError *error))completionHandler {
    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];
    [apiClient GET:blob.url parameters:nil completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegateDownloadSuccess:data];
        }
        completionHandler(data, error);
    }];
}

- (void)storeURL:(NSString *)url withOptions:(FSStoreOptions *)storeOptions completionHandler:(void (^)(FSBlob *blob, NSError *error))completionHandler {
    NSDictionary *sessionSettings = @{FSSessionSettingsURIParams: @YES};
    NSString *storeURL = [FSAPIURL URLForStoreOptions:storeOptions storeURL:YES andApiKey:_apiKey];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:[storeOptions toQueryParameters]];
    [parameters removeObjectForKey:@"mimetype"];
    parameters[@"url"] = url;

    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];
    [apiClient POST:storeURL parameters:parameters options:storeOptions sessionSettings:sessionSettings completionHandler:^(FSBlob *blob, NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegateStoreSucccess:blob];
        }
        completionHandler(blob, error);
    }];
}

- (void)store:(NSData *)data withOptions:(FSStoreOptions *)storeOptions completionHandler:(void (^)(FSBlob *blob, NSError *error))completionHandler {
    NSDictionary *parameters = [storeOptions toQueryParameters];
    NSString *postURL = [FSAPIURL URLForStoreOptions:storeOptions storeURL:NO andApiKey:_apiKey];
    FSAPIClient *apiClient = [[FSAPIClient alloc] initWithApiKey:_apiKey];
    [apiClient POST:postURL withData:data parameters:parameters multipartOptions:storeOptions completionHandler:^(FSBlob *blob, NSError *error) {
        if (error) {
            [self delegateRequestError:error];
        } else {
            [self delegateStoreSucccess:blob];
        }
        completionHandler(blob, error);
    }];
}

- (void)delegateRequestError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(filestackRequestError:)]) {
        [_delegate filestackRequestError:error];
    }
}

- (void)delegateStatSuccess:(FSMetadata *)metadata {
    if ([_delegate respondsToSelector:@selector(filestackStatSuccess:)]) {
        [_delegate filestackStatSuccess:metadata];
    }
}

- (void)delegateStoreSucccess:(FSBlob *)blob {
    if ([_delegate respondsToSelector:@selector(filestackStoreSuccess:)]) {
        [_delegate filestackStoreSuccess:blob];
    }
}

- (void)delegateDownloadSuccess:(NSData *)data {
    if ([_delegate respondsToSelector:@selector(filestackDownloadSuccess:)]) {
        [_delegate filestackDownloadSuccess:data];
    }
}

- (void)delegatePickSuccess:(FSBlob *)blob {
    if ([_delegate respondsToSelector:@selector(filestackPickURLSuccess:)]) {
        [_delegate filestackPickURLSuccess:blob];
    }
}

- (void)delegateRemoveSuccess {
    if ([_delegate respondsToSelector:@selector(filestackRemoveSuccess)]) {
        [_delegate filestackRemoveSuccess];
    }
}

@end

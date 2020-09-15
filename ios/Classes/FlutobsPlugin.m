#import "FlutobsPlugin.h"
#import <OBS/OBS.h>

static FlutterMethodChannel* channel;

@interface FlutobsPlugin()

@property (nonatomic, strong) OBSClient *client;

@end



@implementation FlutobsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  channel = [FlutterMethodChannel
      methodChannelWithName:@"flutobs"
            binaryMessenger:[registrar messenger]];
  FlutobsPlugin* instance = [[FlutobsPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if([@"initSDK" isEqualToString:call.method]){
        NSDictionary *dic = call.arguments;
        NSString *appKey = [dic objectForKey:@"appKey"];
        NSLog(@"%@",appKey);
        NSString *appSecret = [dic objectForKey:@"appSecret"];
        NSLog(@"%@",appSecret);
        NSString *endPoint = [dic objectForKey:@"endPoint"];
        NSLog(@"%@",endPoint);
        
        OBSStaticCredentialProvider *credentailProvider = [[OBSStaticCredentialProvider alloc] initWithAccessKey:appKey secretKey:appSecret];
    
        OBSServiceConfiguration *conf = [[OBSServiceConfiguration alloc] initWithURLString:endPoint credentialProvider:credentailProvider];
        // 初始化client
        self.client  = [[OBSClient alloc] initWithConfiguration:conf];
    } else if ([@"upload" isEqualToString:call.method]) {
        NSDictionary *dic = call.arguments;
        NSString *filePath = [dic objectForKey:@"filePath"];
        NSLog(@"Start upload filePath === %@",filePath);
        NSString *bucketname = [dic objectForKey:@"bucketname"];
        NSLog(@"Start upload bucketname === %@",bucketname);
        NSString *objectname = [dic objectForKey:@"objectname"];
        NSLog(@"Start upload objectname === %@",objectname);
//        NSURL *url = [NSURL fileURLWithPath:filePath];
//        url.lastPathComponent;
        
//        NSString *filePath = [[NSBundle mainBundle]pathForResource:@"fileName" ofType:@"Type"];
        OBSPutObjectWithFileRequest *request = [[OBSPutObjectWithFileRequest alloc]initWithBucketName:bucketname objectKey:objectname uploadFilePath:filePath];
        // 开启后台上传，当应用退出到后台后，上传任务
        request.background = YES;
        // 上传进度
        request.uploadProgressBlock = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"%0.1f%%",(float)floor(totalBytesSent*10000/totalBytesExpectedToSend)/100);
            float progress = (float)floor(totalBytesSent*10000/totalBytesExpectedToSend)/100;
            [channel invokeMethod:@"progress" arguments:[NSNumber numberWithFloat:progress] result:nil];
        };
        // 上传文件
        [self.client putObject:request completionHandler:^(OBSPutObjectResponse *response, NSError *error){
            NSLog(@"%@",response.etag);
            if(error){
                // 打印错误信息
                NSLog(@"文件上传失败");
                NSLog(@"%@",error);
            }
            // 上传文件成功，返回200，打印返回响应值
            if([response.statusCode isEqualToString:@"200"]){
                NSLog(@"文件上传成功");
                NSLog(@"%@",response);
                NSLog(@"%@",response.etag);
                result(@(YES));
            }
            result(@(NO));
        }];
    }else {
        result(FlutterMethodNotImplemented);
    }
}



@end

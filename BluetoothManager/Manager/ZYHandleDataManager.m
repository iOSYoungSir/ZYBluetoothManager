//
//  ZYHandleDataManager.m
//  BluetoothManager
//
//  Created by tzyang on 2019/3/19.
//  Copyright © 2019年 tzyang. All rights reserved.
//

#import "ZYHandleDataManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>

static ZYHandleDataManager * manager = nil;


@implementation ZYHandleDataManager

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZYHandleDataManager alloc]init];
    });
    return manager;
}

/**
 加密 keySize=128  ECB模式
 @param data byte数组 data
 @param aKey key
 @return 加密后的data
 */
+ (NSData *)aes128EncryptWithData:(NSData *)data key:(Byte *)aKey{
    return [[self shareManager] aes128EncryptWithData:data key:aKey];
}

- (NSData *)aes128EncryptWithData:(NSData *)data key:(Byte *)aKey{
    unsigned char result [kCCKeySizeAES128 + 1];
    bzero(result, kCCKeySizeAES128);
    size_t numBytesCrypted = 0;
    
    //详见文档
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,//kCCEncrypt：加密 ；kCCDecrypt：解密
                                          kCCAlgorithmAES128,//区分AES加密与DES加密
                                          kCCOptionECBMode,//加密模式 ECB
                                          aKey,//key
                                          kCCKeySizeAES128,//keySize 表示密钥的长度
                                          NULL,//向量
                                          data.bytes,//要加密的数据
                                          16,//位数 数据的长度
                                          result,//用于接收加密后的结果
                                          sizeof(result),//加密后的数据的长度
                                          &numBytesCrypted);//实际加密的数据的长度
    
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytes:result length:numBytesCrypted];
        ZYLog(@"AES加密成功 resultData = %@",resultData);
        return resultData;
    }
    else{
        ZYLog(@"AES加密失败");
    }
    
    return nil;
}

/**
 解密 keySize=128  ECB模式
 @param data byte数组 data
 @param aKey key
 @return 解密后的data
 */
+ (NSData *)aes128DecryptWithData:(NSData *)data key:(Byte *)aKey{
    return [[self shareManager] aes128DecryptWithData:data key:aKey];
}

- (NSData *)aes128DecryptWithData:(NSData *)data key:(Byte *)aKey{
    
    unsigned char result [kCCKeySizeAES128];
    bzero(result, sizeof(result));
    size_t numBytesCrypted = 0;
    
    //详见文档
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,//kCCEncrypt：加密 ；kCCDecrypt：解密
                                          kCCAlgorithmAES128,//区分AES加密与DES加密
                                          kCCOptionECBMode,//加密模式 ECB
                                          aKey,//key
                                          kCCKeySizeAES128,//keySize
                                          NULL,//向量
                                          data.bytes,//
                                          16,//位数
                                          result,//
                                          sizeof(result),//
                                          &numBytesCrypted);//
    
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytes:result length:numBytesCrypted];
        ZYLog(@"AES解密成功 resultData = %@",resultData);
        return resultData;
    }
    else{
        ZYLog(@"AES解密失败");
    }
    
    return nil;
}

/**
 转换成ByteData 16进制
 @param string 要转换的字符串
 @return 转换后的ByteData
 */
+ (NSData *)byteDataWithString:(NSString *)string{
    return [[self shareManager] byteDataWithString:string];
}

- (NSData *)byteDataWithString:(NSString *)string{
    // hexString的长度应为偶数
    if ([string length] % 2 != 0)
        return nil;
    
    NSUInteger len = [string length];
    NSMutableData *retData = [[NSMutableData alloc] init];
    const char *ch = [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    for (int i=0 ; i<len ; i+=2) {
        
        int height=0;
        if (ch[i]>='0' && ch[i]<='9')
            height = ch[i] - '0';
        else if (ch[i]>='A' && ch[i]<='F')
            height = ch[i] - 'A' + 10;
        else if (ch[i]>='a' && ch[i]<='f')
            height = ch[i] - 'a' + 10;
        else
            // 错误数据
            return nil;
        
        int low=0;
        if (ch[i+1]>='0' && ch[i+1]<='9')
            low = ch[i+1] - '0';
        else if (ch[i+1]>='A' && ch[i+1]<='F')
            low = ch[i+1] - 'A' + 10;
        else if (ch[i+1]>='a' && ch[i+1]<='f')
            low = ch[i+1] - 'a' + 10;
        else
            // 错误数据
            return nil;
        int byteValue = height*16 + low;
        [retData appendBytes:&byteValue length:1];
    }
    ZYLog(@"byteData %@",retData);
    return retData;
}


/**
 将传入的Data类型转换成String并返回
 @param data 传入的data
 @return 转换后的String
 */
+ (NSString *)transformStringWithData:(NSData *)data{
    return [[self shareManager] transformStringWithData:data];
}

- (NSString *)transformStringWithData:(NSData *)data{
    NSString *result;
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; i++) {
        //02x 表示两个位置 显示的16进制
        [hexString appendString:[NSString stringWithFormat:@"%02lx",(unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    
    return result;
}

/**
 将16进制字符串转换成string
 @param hexString 待转换的16进制字符串
 @return 转换后的String
 */
+ (NSString *)convertHexStringFrom:(NSString *)hexString{
    return [[self shareManager] convertHexStringFrom:hexString];
}

- (NSString *)convertHexStringFrom:(NSString *)hexString{
    if (!hexString || [hexString length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([hexString length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [hexString length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [hexString substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    NSString *string = [[NSString alloc]initWithData:hexData encoding:NSUTF8StringEncoding];
    ZYLog(@"string %@",hexString);
    return string;
}

/**
 bae64编码 - 对data
 @param data 传入的data
 @return 编码后的String
 */
+ (NSString *)base64EncodeWithData:(NSData *)data{
    return [[self shareManager] base64EncodeWithData:data];
}

- (NSString *)base64EncodeWithData:(NSData *)data{
    if (data) {
        NSString *base64String = [data base64EncodedStringWithOptions:0];
        return base64String;
    }
    else{
        return nil;
    }
    
}

/**
 bae64解码 - 对data
 @param base64Data base64编码过得data
 @return 解码后的Data
 */
+ (NSData *)base64DencodeWithData:(NSData *)base64Data{
    return [[self shareManager] base64DencodeWithData:base64Data];
}

- (NSData *)base64DencodeWithData:(NSData *)base64Data{
    if (base64Data) {
        NSString * base64String = [self transformStringWithData:base64Data];
        NSData *data = [[NSData alloc]initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
        return data;
    }
    else{
        return nil;
    }
}

/**
 bae64编码 - 对string
 @param string 传入的string
 @return 编码后的String
 */
+ (NSString *)base64EncodeWithString:(NSString *)string{
    return [[self shareManager] base64EncodeWithString:string];
}

- (NSString *)base64EncodeWithString:(NSString *)string{
    if (string) {
        NSData * data = [self byteDataWithString:string];
        NSString *base64String = [data base64EncodedStringWithOptions:0];
        return base64String;
    }
    else{
        return nil;
    }
}

/**
 bae64解码 - 对string
 @param base64String base64编码过得string
 @return 解码后的Data
 */
+ (NSData *)base64DencodeWithString:(NSString *)base64String{
    return [[self shareManager] base64DencodeWithString:base64String];
}

- (NSData *)base64DencodeWithString:(NSString *)base64String{
    if (base64String) {
        NSData *data = [[NSData alloc]initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
        return data;
    }
    else{
        return nil;
    }
}


@end

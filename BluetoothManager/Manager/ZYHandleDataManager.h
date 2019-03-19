//
//  ZYHandleDataManager.h
//  BluetoothManager
//
//  Created by tzyang on 2019/3/19.
//  Copyright © 2019年 tzyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZYHandleDataManager : NSObject

/**
 加密 keySize=128  ECB模式
 @param data byte数组 data
 @param aKey key
 @return 加密后的data
 */
+ (NSData *)aes128EncryptWithData:(NSData *)data key:(Byte *)aKey;

/**
 解密 keySize=128  ECB模式
 @param data byte数组 data
 @param aKey key
 @return 解密后的data
 */
+ (NSData *)aes128DecryptWithData:(NSData *)data key:(Byte *)aKey;

/**
 转换成ByteData
 @param string 要转换的字符串
 @return 转换后的ByteData
 */
+ (NSData *)byteDataWithString:(NSString *)string;

/**
 将传入的Data类型转换成String并返回
 @param data 传入的data
 @return 转换后的String
 */
+ (NSString *)transformStringWithData:(NSData *)data;

/**
 将16进制字符串转换成string
 @param hexString 待转换的16进制字符串
 @return 转换后的String
 */
+ (NSString *)convertHexStringFrom:(NSString *)hexString;

/**
 bae64编码 - data
 @param data 传入的data
 @return 编码后的String
 */
+ (NSString *)base64EncodeWithData:(NSData *)data;

/**
 bae64解码 - data
 @param base64Data base64编码过得data
 @return 解码后的Data
 */
+ (NSData *)base64DencodeWithData:(NSData *)base64Data;

/**
 bae64编码 - string
 @param string 传入的string
 @return 编码后的String
 */
+ (NSString *)base64EncodeWithString:(NSString *)string;

/**
 bae64解码 - string
 @param base64String base64编码过得string
 @return 解码后的Data
 */
+ (NSData *)base64DencodeWithString:(NSString *)base64String;


@end

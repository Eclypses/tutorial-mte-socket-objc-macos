// The MIT License (MIT)
//
// Copyright (c) Eclypses, Inc.
//
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


#ifndef EcdhP256_h
#define EcdhP256_h

#import "mtesupport_ecdh.h"

@protocol EcdhEntropyCallback
- (int)getRandom: (size_t)size : (uint8_t *)output;
@end

@interface EcdhP256 : NSObject {
    id<EcdhEntropyCallback> myEntropyCb;
    uint8_t privateKeyBuffer[SZ_ECDH_P256_PRIVATE_KEY];
    uint8_t publicKeyBuffer[SZ_ECDH_P256_PUBLIC_KEY];
    uint8_t remotePublicKeyBuffer[SZ_ECDH_P256_PUBLIC_KEY];
    uint8_t sharedSecretBuffer[SZ_ECDH_P256_SECRET_DATA];
    Boolean keysCreated;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic) byte_array localPrivateKey;
@property (nonatomic) byte_array localPublicKey;
@property (nonatomic) byte_array remotePublicKey;
@property (nonatomic) byte_array myEntropy;

- (id)initWithName:(NSString *)name;
- (int)setEntropy: (size_t)entropySize : (uint8_t *)entropyData;
- (void)setEntropyCallback:(id<EcdhEntropyCallback>)cb;
+ (int)getRandom: (size_t)size : (uint8_t *)output;
- (int)createKeyPair: (NSMutableArray *)buffer;
- (int)getSharedSecret:(NSArray *)peerPublicKey :(NSMutableArray *)buffer;
+ (void)zeroize: (size_t)size :(uint8_t *)data;

typedef NS_ENUM(NSInteger, ResultCodes) {
    Success = ECDH_P256_SUCCESS,
    RandomFail = ECDH_P256_RANDOM_FAIL,
    InvalidPubKey = ECDH_P256_INVALID_PUBKEY,
    InvalidPrivKey = ECDH_P256_INVALID_PRIVKEY,
    MemoryFail = ECDH_P256_MEMORY_FAIL
};

typedef NS_ENUM(NSInteger, Constants) {
    PublicKeySize = SZ_ECDH_P256_PUBLIC_KEY,
    PrivateKeySize = SZ_ECDH_P256_PRIVATE_KEY,
    SecretDataSize = SZ_ECDH_P256_SECRET_DATA
};

@end

#endif /* EcdhP256_h */

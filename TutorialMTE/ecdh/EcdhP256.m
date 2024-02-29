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


#import <Foundation/Foundation.h>
#import "EcdhP256.h"

@implementation EcdhP256

-(id)initWithName:(NSString *)name {
    if(self = [super init]) {
        _name = name;
        _localPrivateKey.size = PrivateKeySize;
        _localPrivateKey.data = privateKeyBuffer;
        _localPublicKey.size = PublicKeySize;
        _localPublicKey.data = publicKeyBuffer;
        _remotePublicKey.size = PublicKeySize;
        _remotePublicKey.data = remotePublicKeyBuffer;
        keysCreated = false;
    }
    return self;
}

// MARK: Public Methods
- (int)createKeyPair: (NSMutableArray *)buffer {
    int status = Success;
    if (!keysCreated) {
        if (_myEntropy.data == nil && myEntropyCb == nil) {
            status = ecdh_p256_create_keypair(&(_localPrivateKey), &(_localPublicKey), nil, nil);
        } else {
            status = ecdh_p256_create_keypair(&(_localPrivateKey), &(_localPublicKey), entropyCallbackBlock, (__bridge void *)(self));
        }
        
        if (status != Success) {
            printf("Error in %s. Error Code %d\n", __FUNCTION__, status);
            return status;
        }
        keysCreated = true;
    }
    for (int i = 0; i < _localPublicKey.size; i++) {
        [buffer addObject:@(_localPublicKey.data[i])];
    }
    return status;
}

- (int)getSharedSecret:(NSArray *)peerPublicKey :(NSMutableArray *)buffer {
    for (int i = 0; i < PublicKeySize; i++) {
        _remotePublicKey.data[i] = (uint8_t)[peerPublicKey[i] unsignedCharValue];
    }
    byte_array secretBuffer = {.size = SecretDataSize, .data = sharedSecretBuffer };
    int status = ecdh_p256_create_secret(_localPrivateKey, _remotePublicKey, &secretBuffer);
    if (status != Success) {
        printf("Error in %s. Error Code %d\n", __FUNCTION__, status);
        return status;
    }
    keysCreated = false;
    for (int i = 0; i < secretBuffer.size; i++) {
        [buffer addObject:@(secretBuffer.data[i])];
    }
    [EcdhP256 zeroize:secretBuffer.size :secretBuffer.data];
    return status;
}

+ (int)getRandom: (size_t)size :(uint8_t *)output {
    printf("Entering %s\n", __FUNCTION__);
    int status = ecdh_p256_random((byte_array){.size = size, .data = output });
    if (status != Success) {
        printf("Error in %s. Error Code %d\n", __FUNCTION__, status);
    }
    return status;
}

+ (void)zeroize: (size_t)size :(uint8_t *)data {
    ecdh_p256_zeroize(data, size);
}

// MARK: Callback Methods
- (int)setEntropy: (size_t)entropySize : (uint8_t *)entropyData {
    if (entropySize != PrivateKeySize) {
        return MemoryFail;
    }
    _myEntropy.size = entropySize;
    _myEntropy.data = entropyData;
    return Success;
}

- (void)setEntropyCallback:(id<EcdhEntropyCallback>)cb {
    myEntropyCb = cb;
}

int entropyCallbackBlock(void *context, byte_array entropyInput) {
    EcdhP256 *callbackClass = (__bridge EcdhP256 *)context;
    return [callbackClass entropyCallback:entropyInput.size :entropyInput.data];
}

- (int)entropyCallback: (size_t)entropySize : (uint8_t *)entropyData {
    if (myEntropyCb != nil) {
        return [myEntropyCb getRandom:entropySize :entropyData];
    }
    if (_myEntropy.data != nil) {
        entropySize = _myEntropy.size;
        entropyData = _myEntropy.data;
        return Success;
    }
    return [EcdhP256 getRandom:entropySize :entropyData];
}

@end




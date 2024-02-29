/*
 THIS SOFTWARE MAY NOT BE USED FOR PRODUCTION. Otherwise,
 The MIT License (MIT)
 
 Copyright (c) Eclypses, Inc.
 
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "MteSetupInfo.h"

@implementation MteSetupInfo
-(id)init
{
    if(self = [super init]) {
        ecdhManager = [[EcdhP256 alloc]initWithName:@"ecdhManager"];
        
        // Create public key size.
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:PublicKeySize];
        
        // Create the private and public keys.
        const int res = [ecdhManager createKeyPair:temp];
        if (res < 0)
        {
            [NSException raise:NSGenericException
                        format:@"MteSetupInfo load: MteSetupInfo init error."];
        }
        
        publicKey = temp;
        
    }
    
    return self;
}

-(NSMutableArray*)getPublicKey
{
    return [publicKey copy];
}

-(NSMutableArray*)getSharedSecret
{
    if (_peerPublicKey.count == 0)
    {
        [NSException raise:NSGenericException
                    format:@"Peer public key not set."];
    }
    
    // Create temp array.
    NSMutableArray *secret = [NSMutableArray arrayWithCapacity:SecretDataSize];
    
    // Create shared secret.
    int res = [ecdhManager getSharedSecret:_peerPublicKey :secret];
    if (res < 0)
    {
        [NSException raise:NSGenericException
                    format:@"Unable to get shared secret."];
    }
    
    return secret;
}

+(byte_array)convertNSArrayToByteArray:(NSMutableArray*)source
{
    byte_array temp;
    temp.size = source.count;
    uint8_t *arr = malloc(sizeof(uint8_t) * source.count);
    temp.data = arr;
    
    for (int i = 0; i < source.count; i++) {
        temp.data[i] = (uint8_t)[[source objectAtIndex:i] unsignedCharValue];
    }
    
    return temp;
}

+(NSMutableArray*)convertByteArrayToNSArray:(byte_array)source
{
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < source.size; i++) {
        [temp addObject:@(source.data[i])];
    }
    
    return temp;
}

@end

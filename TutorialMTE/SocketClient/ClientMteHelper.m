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

#import "ClientMteHelper.h"

@implementation ClientMteHelper

-(id)init
{
    if(self = [super init]) {
        clientEncoderInfo = [[MteSetupInfo alloc]init];
        clientDecoderInfo = [[MteSetupInfo alloc]init];
    }
    
    return self;
}

-(bool)initMte
{
    // ==================
    // Step 2 - Licensing
    // ==================
    // Initialize MTE license. If a license code is not required (e.g., trial
    // mode), this can be skipped.
    if (![MteBase initLicense : @LICENSE_COMPANY_NAME code: @LICENSE_KEY])
    {
        printf("There was an error attempting to initialize the MTE License.\n");
        return false;
    }
    
#if defined USE_MTE_CORE
    encoder = MTE_AUTORELEASE([[MteEnc alloc]init] );
    decoder = MTE_AUTORELEASE([[MteDec alloc]init] );
#endif
#if defined USE_MKE_ADDON
    encoder = MTE_AUTORELEASE([[MteMkeEnc alloc]init] );
    decoder = MTE_AUTORELEASE([[MteMkeDec alloc]init] );
#endif
#if defined USE_FLEN_ADDON
    static const size_t fixedBytes = MAX_INPUT_BYTES;
    encoder = MTE_AUTORELEASE([[MteFlenEnc alloc]initWithFixedBytes:fixedBytes] );
    decoder = MTE_AUTORELEASE([[MteDec alloc]init] );
#endif
    
    // Exchange entropy, nonce, and personalization string between the client and server.
    if (![self exchangeMteInfo] )
    {
        printf("There was an error attempting to exchange information between this and the client.\n");
        return false;
    }
    return true;
}

// =============================
// Step 3 - Information Exchange
// =============================
-(bool)exchangeMteInfo
{
    // The client Encoder and the server Decoder will be paired.
    // The client Decoder and the server Encoder will be paired.
    
    // Prepare to send client information.
    
    // Create personalization strings.
    NSUUID *encPersonal =[[NSUUID alloc]init];
    NSString *encPersonalString = [encPersonal UUIDString];
    clientEncoderInfo.personal = encPersonalString;
    
    NSUUID *decPersonal =[[NSUUID alloc]init];
    NSString *decPersonalString = [decPersonal UUIDString];
    clientDecoderInfo.personal = decPersonalString;
    
    // Send out information to the server.
    // 1 - client Encoder public key (to server Decoder)
    // 2 - client Encoder personalization string (to server Decoder)
    // 3 - client Decoder public key (to server Encoder)
    // 4 - client Decoder personalization string (to server Encoder)
    byte_array encPublicKey = [MteSetupInfo convertNSArrayToByteArray:[clientEncoderInfo getPublicKey]];
    byte_array decPublicKey = [MteSetupInfo convertNSArrayToByteArray:[clientDecoderInfo getPublicKey]];
    
    send_message('1', encPublicKey.data, encPublicKey.size);
    send_message('2', (char*)[encPersonalString UTF8String], encPersonalString.length);
    send_message('3', decPublicKey.data, decPublicKey.size);
    send_message('4', (char*)[decPersonalString UTF8String], decPersonalString.length);
    
    // Wait for ack from server.
    struct recv_msg recvData =receive_message();
    
    if (![[[NSString stringWithFormat:@"%c", recvData.header] uppercaseString]  isEqual: @"A"])
    {
        return false;
    }
    
    // Processing incoming messages, all 4 will be needed.
    uint8_t recvCount = 0;
    
    // Loop until all 4 data are received from server, can be in any order.
    while (recvCount < 4)
    {
        // Receive the next message from the server.
        recvData = receive_message();
        
        // Evaluate the header.
        // 1 - client Decoder public key (from server Encoder)
        // 2 - client Decoder nonce (from server Encoder)
        // 3 - client Encoder public key (from server Decoder)
        // 4 - client Encoder nonce (from server Decoder)
        byte_array temp = {.size = recvData.message.size, .data = recvData.message.data};
        NSMutableArray *tempArray = [MteSetupInfo convertByteArrayToNSArray:temp];
        switch(recvData.header)
        {
            case '1':
            {
                if (clientDecoderInfo.peerPublicKey == NULL || clientDecoderInfo.peerPublicKey.count == 0)
                {
                    recvCount++;
                }
                clientDecoderInfo.peerPublicKey = tempArray;
                break;
            }
            case '2':
            {
                if (clientDecoderInfo.nonce == NULL || clientDecoderInfo.nonce.count == 0)
                {
                    recvCount++;
                }
                clientDecoderInfo.nonce = tempArray;
                
                break;
            }
            case '3':
            {
                if (clientEncoderInfo.peerPublicKey == NULL || clientEncoderInfo.peerPublicKey.count == 0)
                {
                    recvCount++;
                }
                clientEncoderInfo.peerPublicKey = tempArray;
                break;
            }
            case '4':
            {
                if (clientEncoderInfo.nonce == NULL || clientEncoderInfo.nonce.count == 0)
                {
                    recvCount++;
                }
                clientEncoderInfo.nonce = tempArray;
                break;
            }
            default:
            {
                // Unknown message, abort here, send an 'E' for error.
                send_message('E', "ERR", 3);
                return false;
            }
        }
    }
    
    // Now all values from server have been received, send an 'A' for acknowledge to server.
    send_message('A', "ACK", 3);
    
    return true;
}

// ======================
// Step 4 - Instantiation
// ======================
-(bool)createEncoder
{
    byte_array nonce = [MteSetupInfo convertNSArrayToByteArray:clientEncoderInfo.nonce];
    byte_array pubKey = [MteSetupInfo convertNSArrayToByteArray:[clientEncoderInfo getPublicKey]];
    byte_array peerKey = [MteSetupInfo convertNSArrayToByteArray:[clientEncoderInfo peerPublicKey]];
    
    // Display all info related to the Encoder.
    printf("Client Encoder public key:\n");
    [ClientMteHelper displayMessage:pubKey];
    printf("Client Encoder peer's key:\n");
    [ClientMteHelper displayMessage:peerKey];
    printf("Client Encoder nonce:\n");
    [ClientMteHelper displayMessage:nonce];
    printf("Client Encoder personalization:\n");
    printf("%s\n", [clientEncoderInfo.personal UTF8String]);
    
    // Create shared secret.
    NSMutableArray *secret = [clientEncoderInfo getSharedSecret];
    
    byte_array secretByteArray = [MteSetupInfo convertNSArrayToByteArray:secret];
    
    // Set Encoder entropy using this shared secret.
    [encoder setEntropy:secretByteArray.data bytes:secretByteArray.size];
    
    // Set Encoder nonce.
    [encoder setNonce:nonce.data bytes:nonce.size];
    
    // Instantiate Encoder.
    mte_status status = [encoder instantiate:clientEncoderInfo.personal];
    if (status != mte_status_success) {
        printf("Encoder Instantiate error. Error: %s, %s\n",
               [[MteBase getStatusName:status] UTF8String],
               [[MteBase getStatusDescription:status] UTF8String]);
        return false;
    }
    
    clientEncoderInfo = NULL;
    
    return true;
}

-(bool)createDecoder
{
    byte_array nonce = [MteSetupInfo convertNSArrayToByteArray:clientDecoderInfo.nonce];
    byte_array pubKey = [MteSetupInfo convertNSArrayToByteArray:[clientDecoderInfo getPublicKey]];
    byte_array peerKey = [MteSetupInfo convertNSArrayToByteArray:[clientDecoderInfo peerPublicKey]];
    
    // Display all info related to the Decoder.
    printf("Client Decoder public key:\n");
    [ClientMteHelper displayMessage:pubKey];
    printf("Client Decoder peer's key:\n");
    [ClientMteHelper displayMessage:peerKey];
    printf("Client Decoder nonce:\n");
    [ClientMteHelper displayMessage:nonce];
    printf("Client Decoder personalization:\n");
    printf("%s\n", [clientDecoderInfo.personal UTF8String]);
    
    // Create shared secret.
    NSMutableArray *secret = [clientDecoderInfo getSharedSecret];
    
    byte_array secretByteArray = [MteSetupInfo convertNSArrayToByteArray:secret];
    
    // Set Decoder entropy using this shared secret.
    [decoder setEntropy:secretByteArray.data bytes:secretByteArray.size];
    
    // Set Decoder nonce.
    [decoder setNonce:nonce.data bytes:nonce.size];
    
    // Instantiate Decoder.
    mte_status status = [decoder instantiate:clientDecoderInfo.personal];
    if (status != mte_status_success) {
        printf("Decoder Instantiate error. Error: %s, %s\n",
               [[MteBase getStatusName:status] UTF8String],
               [[MteBase getStatusDescription:status] UTF8String]);
        return false;
    }
    
    clientDecoderInfo = NULL;
    
    return true;
}

// =================
// Step 5 - Encoding
// =================
-(bool)encodeMessage:(byte_array) message : (byte_array*) encoded
{
    // Display original message.
    NSData *messageData = [NSData dataWithBytes:message.data length:message.size];
    NSString* messageStr = [NSString stringWithUTF8String:[messageData bytes]];
    printf("\nMessage to be encoded: %s\n", [messageStr UTF8String]);
    
    // Encode the message.
    mte_status status;
    size_t encodedBytes;
    const void* encodedMessage = [encoder encode:message.data dataBytes:message.size encodedBytes:&encodedBytes status:&status];
    
    // Ensure that it encoded successfully.
    if (status != mte_status_success)
    {
        printf("Error encoding (%s): %s\n",
               [[MteBase getStatusName:status] UTF8String],
               [[MteBase getStatusDescription:status] UTF8String]);
        return false;
    }
    encoded->size = encodedBytes;
    encoded->data = encodedMessage;
    
    // Display encoded message.
    printf("Encoded message being sent:\n");
    [ClientMteHelper displayMessage:*encoded];
    
    return true;
}

// =================
// Step 6 - Decoding
// =================
-(bool)decodeMessage:(byte_array) encoded : (byte_array*) decoded
{
    // Display encoded message.
    printf("\nEncoded message received:\n");
    [ClientMteHelper displayMessage:encoded];
    
    // Decode the encoded message.
    mte_status status;
    size_t decodedBytes;
    const void* decodedMessage = [decoder decode:encoded.data encodedBytes:encoded.size decodedBytes:&decodedBytes status:&status];
    
    // Ensure that there were no decoding errors.
    if ([MteBase statusIsError:status])
    {
        printf("Error decoding (%s): %s\n",
               [[MteBase getStatusName:status] UTF8String],
               [[MteBase getStatusDescription:status] UTF8String]);
        return false;
    }
    
    // Set decoded message.
    //*decoded = [MteSetupInfo createByteArrayPointer:decodedMessage :decodedBytes];
    
    decoded->size = decodedBytes;
    decoded->data = decodedMessage;
    
    // Display decoded message.
    NSData *messageData = [NSData dataWithBytes:decoded->data length:decoded->size];
    NSString* messageStr = [NSString stringWithUTF8String:[messageData bytes]];
    printf("\nDecoded message: %s\n", [messageStr UTF8String]);
    
    return true;
}

-(uint64_t)getTimestamp
{
    NSTimeInterval timeInSeconds = [[NSDate date] timeIntervalSince1970];
    return timeInSeconds;
}

+(void)displayMessage:(const byte_array) message
{
    NSMutableString *hex = [NSMutableString new];
    for (NSInteger i = 0; i < message.size; i++) {
        [hex appendFormat:@"%02x", message.data[i]];
    }
    
    printf("%s\n", [[hex uppercaseString] UTF8String]);
}

// =================
// Step 7 - Clean Up
// =================
-(void)finishMte
{
    // Uninstantiate Encoder and Decoder.
    [encoder uninstantiate];
    [decoder uninstantiate];
}
@end

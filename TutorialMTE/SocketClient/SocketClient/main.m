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

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import "MteBase.h"

#import "mte_alloca.h"
#include <netdb.h>

//---------------------------------------------------
// MKE and Fixed length add-ons are NOT in all SDK
// MTE versions. If the name of the SDK includes
// "-MKE" then it will contain the MKE add-on. If the
// name of the SDK includes "-FLEN" then it contains
// the Fixed length add-on.
//---------------------------------------------------

/* Step 5 */
//-----------------------------------
// To use the core MTE, uncomment the
// following preprocessor definition.
//-----------------------------------
#define USE_MTE_CORE
//---------------------------------------
// To use the MTE MKE add-on, uncomment
// the following preprocessor definition.
//---------------------------------------
//#define USE_MKE_ADDON
//-------------------------------------------------
// To use the MTE Fixed length add-on,
// uncomment the following preprocessor definition.
//-------------------------------------------------
//#define USE_FLEN_ADDON

/* Step 6 */
#if defined USE_MTE_CORE
#import "MteEnc.h"
#import "MteDec.h"
#endif
#if defined USE_MKE_ADDON
#import "MteMkeEnc.h"
#import "MteMkeDec.h"
#endif
#if defined USE_FLEN_ADDON
#import "MteFlenEnc.h"
#import "MteDec.h"
#endif

const char* serverIpAddress = "localhost";
const char* serverPort = "27015";
char ipBuff[25];
char portBuff[5];

#if defined USE_MTE_CORE
MteEnc* encoder;
const char* mteType = "Core";
#endif
#if defined USE_MKE_ADDON
MteMkeEnc* encoder;
const char* mteType = "MKE";
#endif
#if defined USE_FLEN_ADDON
MteFlenEnc* encoder;
const char* mteType = "FLEN";
#endif

mte_status encoderStatus;

#if defined USE_MTE_CORE || defined USE_FLEN_ADDON
MteDec* decoder;
#endif

#if defined USE_MKE_ADDON
MteMkeDec* decoder;
#endif

mte_status decoderStatus;

int main()
{
    printf("Starting Objective-C Socket Client.\n");
    printf("Using MTE Version: %s-%s\n", [MteBase.getVersion UTF8String], mteType);
    
    // Request server ip and port
    printf("Please enter ip address of Server, press Enter to use default: %s\n", serverIpAddress);
    fgets(ipBuff, 25, stdin);
    if (strncmp(ipBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        ipBuff[strlen(ipBuff) - 1] = '\0';
        serverIpAddress = ipBuff;
    }
    
    printf("Server is at %s\n", serverIpAddress);
    
    printf("Please enter port to use, press Enter to use default: %s\n", serverPort);
    fgets(portBuff, 25, stdin);
    
    if (strncmp(portBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        portBuff[strlen(portBuff) - 1] = '\0';
        serverPort = portBuff;
    }
    
    /* Step 7 */
    // Check MTE License
    if (![MteBase initLicense : @"LicenseCompanyName" code:@"LicenseKey"]) {
        printf("There was an error attempting to initialize the MTE License.\n");
        exit(EXIT_FAILURE);
    }
    
    // MARK: MTE Setup
    /* Step 8 */
#if defined USE_MTE_CORE
    encoder = MTE_AUTORELEASE([[MteEnc alloc]init] );
#endif
#if defined USE_MKE_ADDON
    encoder = MTE_AUTORELEASE([[MteMkeEnc alloc]init] );
#endif
#if defined USE_FLEN_ADDON
    static const size_t fixedBytes = 8;
    encoder = MTE_AUTORELEASE([[MteFlenEnc alloc]initWithFixedBytes:fixedBytes] );
#endif
    
    // MARK: Create Entropy
    // IMPORTANT! ** This is an entirely insecure way of setting Entropy and MUST NEVER be used in a "real"
    // application. Please see MTE Developer's Guide for more information.
    // Create 'all-zero' entropy for this tutorial.
    
    /* Step 9 */
    // Get the minimum entropy length for the DRBG.
    size_t eMinBytes = [MteBase getDrbgsEntropyMinBytes : [encoder getDrbg] ];
    
    // then, allocate that length on the stack and zero it.
    char* entropy = MTE_ALLOCA(eMinBytes);
    memset(entropy, '0', eMinBytes);
        
    // MARK: Create Nonce(s)
    // In this tutorial, we set the encoder and decoder nonces differently so the encoded payloads will appear different
    // even though the data prior to encoding is the same. They are reversed on the Client so they match up with
    // the Server
    UInt64 encoderNonce = 1;
    UInt64 decoderNonce = 0;
    
    NSString* personalizationString = @"demo";
       
    // Set entropy and nonce
    [encoder setEntropy : entropy bytes : eMinBytes];
    [encoder setNonce : encoderNonce];
    
    // Instantiate encoder with PersonalizationString and check status
    encoderStatus = [encoder instantiate : personalizationString];
    if (encoderStatus != mte_status_success) {
        printf("Encoder Instantiate error. Error: %s, %s\n",
               [[MteBase getStatusName : encoderStatus]UTF8String],
               [[MteBase getStatusDescription : encoderStatus]UTF8String] );
        exit(EXIT_FAILURE);
    }
    
    /* Step 8 Continued */
#if defined USE_MTE_CORE || defined USE_FLEN_ADDON
    decoder = MTE_AUTORELEASE([[MteDec alloc]init] );
#endif
#if defined USE_MKE_ADDON
    decoder = MTE_AUTORELEASE([[MteMkeDec alloc]init] );
#endif
    
    /* Step 9 Continued */
    // MARK: Reset Entropy
    // MTE will have 'zeroed' the entropy when it was set on the encoder so we need to 'refill' it.
    memset(entropy, '0', eMinBytes);
    
    // Set entropy and nonce
    [decoder setEntropy : entropy bytes : eMinBytes];
    [decoder setNonce : decoderNonce] ;
    
    // Instantiate decoder with PersonalizationString and check status
    decoderStatus = [decoder instantiate : personalizationString];
    if (decoderStatus != mte_status_success) {
        printf("Decoder Instantiate error. Error: %s, %s\n",
               [[MteBase getStatusName : decoderStatus]UTF8String],
               [[MteBase getStatusDescription : decoderStatus]UTF8String] );
        exit(EXIT_FAILURE);
    }
        
    //MARK: Socket Setup
    
    // Socket Properties
    int server_sock = 0;
    char buffer[1024];
    struct addrinfo hints, * res;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    getaddrinfo(serverIpAddress, serverPort, &hints, &res);
    
    //Create Socket
    if ((server_sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) == -1) {
        perror("Client Socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    // Connect to Server
    if (connect(server_sock, res->ai_addr, res->ai_addrlen) == -1) {
        perror("Client Error: Connection Failed.");
        close(server_sock);
        exit(EXIT_FAILURE);
    }
    
    // MARK: Socket Communication
    printf("Client connected to Server.\n");
    
    while (true)
    {
        // MARK: Get user input
        
        printf("Please enter text to send: (To end please type 'quit')\n");
        fgets(buffer, 1024, stdin);
        if (strncmp(buffer, "quit", 3) == 0) {
            exit(EXIT_SUCCESS);
        }
        
        // Remove the newline character at the end of the message put there by fgets
        buffer[strlen(buffer) - 1] = '\0';
        
        /* Step 10 */
        // Encode the input
        size_t encodedBytes;
        const void* encodedResult = [encoder encode : buffer dataBytes : strlen(buffer) encodedBytes : &encodedBytes status : &encoderStatus];
        if (encoderStatus != mte_status_success) {
            printf("Error encoding: Status %s/ %s\n",
                   [[MteBase getStatusName : encoderStatus]UTF8String],
                   [[MteBase getStatusDescription : encoderStatus]UTF8String] );
            exit(EXIT_FAILURE);
        }
        
        // For demonstration purposes only to show packets.
        NSData* encodedData = [NSData dataWithBytes : encodedResult length : encodedBytes];
        NSString* base64String = [encodedData base64EncodedStringWithOptions : 0];
        printf("Base64 encoded representation of the packet being sent: %s\n", [base64String UTF8String]);
        
        // Get length of encoded data in network endianness
        uint32_t nBytes = htonl(encodedBytes);
        
        // Send encoded data length to Server first
        if (send(server_sock, &nBytes, sizeof(nBytes), 0) != sizeof(nBytes)) {
            perror("\nClient Error: Sending encoded data to Server\n");
            exit(EXIT_FAILURE);
        }
        
        // then, send encoded data to Server
        if (send(server_sock, encodedResult, encodedBytes, 0) != encodedBytes) {
            perror("\nClient Error: Writing to Server\n");
            exit(EXIT_FAILURE);
        }
        
        // MARK: Listen for Server response
        
        uint32_t value;
        if (recv(server_sock, &value, sizeof(value), MSG_WAITALL) < sizeof(value)) {
            perror("\nClient Error: Reading length data from Server\n");
            exit(EXIT_FAILURE);
        }
        if (strncmp(buffer, "end", 3) == 0) {
            printf("Server was disconnected.\n");
            exit(EXIT_SUCCESS);
        }
        
        // Convert message length data to host endianness
        uint32_t hBytes = ntohl(value);
        
        // Read the data from the socket
        if (recv(server_sock, buffer, hBytes, MSG_WAITALL) != hBytes) {
            perror("\nClient Error: Reading encoded data from Server\n");
            exit(EXIT_FAILURE);
        }
        
        // Add the null terminator to the buffer
        buffer[hBytes] = '\0';
        
        // Convert to Ascii Hex NSString just for display here. It's not necessary.
        NSData* receivedData = [NSData dataWithBytes : buffer length : hBytes];
        base64String = @"";
        base64String = [receivedData base64EncodedStringWithOptions : 0];
        
        printf("Base64 encoded representation of the received packet: %s\n", [base64String UTF8String]);
        
        /* Step 10 Continued */
        // Now, decode what we received
        size_t decodedBytes = 0;
        [decoder decode : buffer encodedBytes : hBytes decodedBytes : &decodedBytes status : &decoderStatus] ;
        if ([MteBase statusIsError : decoderStatus]) {
            printf("Decoder error. Error: %s, %s\n",
                   [[MteBase getStatusName : decoderStatus]UTF8String],
                   [[MteBase getStatusDescription : decoderStatus]UTF8String] );
            exit(EXIT_FAILURE);
        }
    }
    return 0;
}

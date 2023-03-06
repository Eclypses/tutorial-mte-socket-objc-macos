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

const char* port = "27015";
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
    printf("Starting Objective-C Socket Server.\n");
    printf("Using MTE Version %s-%s\n", [MteBase.getVersion UTF8String], mteType);
        
    // Request port
    printf("Please enter port to use, press Enter to use default: %s\n", port);
    fgets(portBuff, 25, stdin);
    if (strncmp(portBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        portBuff[strlen(portBuff) - 1] = '\0';
        port = portBuff;
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
    UInt64 encoderNonce = 0;
    UInt64 decoderNonce = 1;
    
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
    struct sockaddr_storage client_addr;
    socklen_t client_size;
    struct addrinfo hints, * res;
    int master_socket, client_sock;
    int yes = 1;
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    getaddrinfo(NULL, port, &hints, &res);
    char buffer[1024];
    
    // Create a master socket
    if ((master_socket = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) == 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    // lose the pesky "Address already in use" error message
    if (setsockopt(master_socket, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    
    //bind the socket to defined PORT
    if (bind(master_socket, res->ai_addr, res->ai_addrlen) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }
    
    // Open the listener
    listen(master_socket, 1);
    printf("Listening for a new connection on port %s . . .\n\n", port);
    
    // MARK: Socket Communication
    
    // Accept an incoming connection:
    client_size = sizeof(client_addr);
    client_sock = accept(master_socket, (struct sockaddr*)&client_addr, &client_size);
    
    if (client_sock < 0) {
        perror("Can't accept");
        exit(EXIT_FAILURE);
    }
    
    // We don't want any more new connections so we'll close the master_socket
    close(master_socket);
    printf("Master_Socket on port %s closed. No new connections will be accepted during this session.\n", port);
    
    while (true) {
        // MARK: Listen for Client Messages
        printf("Listening for messages from Client . . .\n\n");
        
        // Listen for size of incoming message
        uint32_t nBytes;
        if (recv(client_sock, &nBytes, sizeof(nBytes), MSG_WAITALL) != sizeof(nBytes)) {
            printf("Connection closed..\n");
            exit(EXIT_SUCCESS);
        }
        
        // Set length to host endianness
        uint32_t hBytes = ntohl(nBytes);
        
        // receive the data
        if (recv(client_sock, buffer, hBytes, MSG_WAITALL) != hBytes) {
            printf("Client has disconnected. Server is shutting down.\n");
            exit(EXIT_SUCCESS);
        }
        
        // Add the null terminator to the buffer
        buffer[hBytes] = '\0';
        
        NSData* receivedData = [NSData dataWithBytes : buffer length : hBytes];
        NSString* base64String = [receivedData base64EncodedStringWithOptions : 0];
        printf("Base64 encoded representation of the received packet: %s\n", [base64String UTF8String]);
        
        /* Step 10 */
        // Now, decode what we received
        size_t decodedBytes = 0;
        void* decodedResult = [decoder decode : buffer encodedBytes : hBytes decodedBytes : &decodedBytes status : &decoderStatus];
        if ([MteBase statusIsError : decoderStatus]) {
            printf("Decoder error. Error: %s, %s\n",
                   [[MteBase getStatusName : decoderStatus]UTF8String],
                   [[MteBase getStatusDescription : decoderStatus]UTF8String] );
            exit(EXIT_FAILURE);
        }
        
        // Convert decoded data to NSString for display here. Again, it's not necessary.
        NSData* decodedData = [NSData dataWithBytes : decodedResult length : decodedBytes];
        NSString* decodedStr = [NSString stringWithUTF8String : [decodedData bytes] ];
        printf("Decoded Message: \n\t%s\n", [decodedStr UTF8String]);
        
        /* Step 10 Continued */
        // Re-encode what we received from client
        size_t encodedBytes;
        const void* encodedResult = [encoder encode : decodedResult dataBytes : decodedBytes
                                       encodedBytes : &encodedBytes status : &encoderStatus];
        if (encoderStatus != mte_status_success) {
            printf("Encoder error. Error: %s, %s\n",
                   [[MteBase getStatusName : encoderStatus]UTF8String],
                   [[MteBase getStatusDescription : encoderStatus]UTF8String] );
            exit(EXIT_FAILURE);
        }
        
        // For demonstration purposes only to show packets.
        NSData* encodedData = [NSData dataWithBytes : encodedResult length : encodedBytes];
        base64String = @"";
        base64String = [encodedData base64EncodedStringWithOptions : 0];
        printf("Base64 encoded representation of the packet being sent: %s\n", [base64String UTF8String]);
        
        // MARK: Respond to Server
        
        // Get length of encoded data in network endianness
        nBytes = htonl(encodedBytes);
        
        // Send the length data
        if (send(client_sock, &nBytes, sizeof(nBytes), 0) != sizeof(nBytes)) {
            perror("Unable to send reponse to Client");
            exit(EXIT_FAILURE);
        }
        
        // Send the real data
        if (send(client_sock, encodedResult, encodedBytes, 0) != encodedBytes) {
            perror("Unable to send reponse to Client");
            exit(EXIT_FAILURE);
        }
    }
    return 0;
}

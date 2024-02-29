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
#include <netdb.h>


#import "ServerSocketManager.h"
#include "globals.h"
#import "MteBase.h"
#import "mte_alloca.h"
#import "EcdhP256.h"
#import "MteSetupInfo.h"
#import "ServerMteHelper.h"

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

char portBuff[6];

@interface mainHelper : NSObject
{

}
+(void)displayProgramInfo;
+(bool)runDiagnosticTest;
+(void)handleUserOutput;
+(bool)sendMessage:(const byte_array)message;
+(bool)receiveMessage:(byte_array*)message;
+(void)closeProgram;
@end

ServerMteHelper* mteHelper;


int main()
{
    [mainHelper displayProgramInfo];
    
    // Request port
    printf("Please enter port to use, press Enter to use default: %s\n", DEFAULT_PORT);
    fgets(portBuff, 25, stdin);
    if (strncmp(portBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        portBuff[strlen(portBuff) - 1] = '\0';
    } else {
        strlcpy(portBuff, DEFAULT_PORT, sizeof(DEFAULT_PORT));
    }
    
    // Create socket.
    int socketCreation = create_socket();
    if (socketCreation == 0)
    {
        printf("Unable to create socket.");
        exit(EXIT_FAILURE);
    }
    
    int socketBinding = bind_socket(atoi(portBuff));
    if (socketBinding == 0)
    {
        printf("Unable to bind socket.");
        exit(EXIT_FAILURE);
    }
    
    printf("Listening for new client connection...\n");
    
    int socketListening = listen_socket();
    if (socketListening == 0)
    {
        printf("Unable to listen to socket.");
        exit(EXIT_FAILURE);
    }
    
    int socketAccepting = accept_socket(portBuff);
    if (socketAccepting == 0)
    {
        printf("Unable to accept the socket.");
        exit(EXIT_FAILURE);
    }
    
    printf("Connected with Client.\n");
    
    // Init the MTE.
    mteHelper = [[ServerMteHelper alloc]init];
    [mteHelper initMte];
    
    // Create the Decoder.
    if (![mteHelper createDecoder])
    {
        printf("There was a problem creating the Decoder.");
        exit(EXIT_FAILURE);
    }
    
    // Create the Encoder.
    if (![mteHelper createEncoder])
    {
        printf("There was a problem creating the Encoder.");
        exit(EXIT_FAILURE);
    }
    
    // Run the diagnostic test.
    if (![mainHelper runDiagnosticTest])
    {
        printf("There was a problem running the diagnostic test.");
        exit(EXIT_FAILURE);
    }
    
    // Handle user output coming from the client.
    [mainHelper handleUserOutput];
      
    // End the program.
    [mainHelper closeProgram];
    return 0;
}

@implementation mainHelper
+(void)displayProgramInfo
{
    // Display the language and application.
    printf("Starting Objective-C Socket Server.\n");

     // Display version of MTE and type.
   #if defined USE_MTE_CORE
     const char* mteType = "Core";
   #endif
   #if defined USE_MKE_ADDON
     const char* mteType = "MKE";
   #endif
   #if defined USE_FLEN_ADDON
     const char* mteType = "FLEN";
   #endif
    
    printf("Using MTE Version %s-%s\n", [MteBase.getVersion UTF8String], mteType);
}

+(bool)runDiagnosticTest
{
    // Receive and decode the message.
    byte_array decoded;
    if (![self receiveMessage:&decoded])
    if (decoded.size == 0)
    {
        return false;
    }
    
    // Check that is successfully decoded as "ping".
    NSData *decodedData = [NSData dataWithBytes:decoded.data length:decoded.size];
    NSString* decodedStr = [NSString stringWithUTF8String:[decodedData bytes]];
    if ([decodedStr isEqualToString:@"ping"])
    {
        printf("Server Decoder decoded the message from the client Encoder successfully.\n");
    }
    else
    {
        fprintf(stderr, "Server Decoder DID NOT decode the message from the client Encoder successfully.\n");
        return false;
    }
    
    // Create "ack" message.
    byte_array message;
    message.size = 3;
    message.data = "ack";
    
    // Encode and send message.
    if (![self sendMessage:message])
    {
        return false;
    }
    
    return true;
}

+(bool)sendMessage:(const byte_array)message
{
    // Encode the message.
    byte_array encoded;
    if (![mteHelper encodeMessage:message :&encoded])
    {
        return false;
    }
    
    // Send the encoded message.
    const size_t res = send_message('m', encoded.data, encoded.size);
    if (res == 0)
    {
        return false;
    }
    return true;
}

+(bool)receiveMessage:(byte_array*)message
{
    // Wait for return message.
    struct recv_msg msgStruct = receive_message();
    if (msgStruct.success == false || msgStruct.message.size == 0 || ![[[NSString stringWithFormat:@"%c", msgStruct.header] uppercaseString]  isEqual: @"M"])
    {
        printf("Client closed connection.\n");
        return false;
    }
    
    // Decode the message.
    byte_array encoded = msgStruct.message;
    if (![mteHelper decodeMessage:encoded :message])
    {
        return false;
    }
    return true;
    
}

+(void)handleUserOutput
{
    while (true)
    {
        // MARK: Listen for Client Messages
        printf("Listening for messages from Client . . .\n\n");
        
        // Receive and decode the message from the client.
        byte_array decoded;
        if (![self receiveMessage:&decoded])
        if (decoded.size == 0)
        {
            break;
        }
        
        // Encode and send the input.
        if (![self sendMessage:decoded])
        {
            break;
        }
        
        // Free the decoded message.
        decoded.size = 0;
        decoded.data = nil;
    }
}

+(void)closeProgram
{
    // Finish MTE.
    [mteHelper finishMte];
    
    // Close the socket.
    close_socket();
    
    printf("Program stopped.\n");
}


@end



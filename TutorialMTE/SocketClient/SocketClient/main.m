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

#import "MteBase.h"
#import "mte_alloca.h"
#import "EcdhP256.h"
#import "MteSetupInfo.h"
#import "ClientSocketManager.h"
#import "ClientMteHelper.h"
#include "globals.h"

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
char ipBuff[15];


@interface mainHelper : NSObject
{
    
}
+(void)displayProgramInfo;
+(bool)runDiagnosticTest;
+(void)handleUserInput;
+(bool)sendMessage:(const byte_array)message;
+(bool)receiveMessage:(byte_array*)message;
+(void)closeProgram;
@end

ClientMteHelper* mteHelper;

int main()
{
    [mainHelper displayProgramInfo];
    
    // Request server.
    printf("Please enter ip address of Server, press Enter to use default: %s\n", DEFAULT_SERVER_IP);
    fgets(ipBuff, 25, stdin);
    if (strncmp(ipBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        ipBuff[strlen(ipBuff) - 1] = '\0';
    } else {
        strlcpy(ipBuff, DEFAULT_SERVER_IP, sizeof(DEFAULT_SERVER_IP));
    }
    
    printf("Server is at %s\n", ipBuff);
    
    // Request port.
    printf("Please enter port to use, press Enter to use default: %s\n", DEFAULT_PORT);
    fgets(portBuff, 25, stdin);
    if (strncmp(portBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        portBuff[strlen(portBuff) - 1] = '\0';
    } else {
        strlcpy(portBuff, DEFAULT_PORT, sizeof(DEFAULT_PORT));
    }
    
    int socket_creation = create_socket();
    if (socket_creation == 0)
    {
        printf("Unable to create socket.");
        return socket_creation;
    }
    
    int socket_connection = connect_socket(ipBuff, (uint16_t)atoi(portBuff));
    if (socket_connection == 0)
    {
        printf("Unable to connect to socket.");
        return socket_connection;
    }
    
    printf("Client connected to Server.\n");
    
    // Init the MTE.
    mteHelper = [[ClientMteHelper alloc]init];
    [mteHelper initMte];
    
    // Create the Encoder.
    if (![mteHelper createEncoder])
    {
        printf("There was a problem creating the Encoder.");
        exit(EXIT_FAILURE);
    }
    
    // Create the Decoder.
    if (![mteHelper createDecoder])
    {
        printf("There was a problem creating the Decoder.");
        exit(EXIT_FAILURE);
    }
    
    // Run the diagnostic test.
    if (![mainHelper runDiagnosticTest])
    {
        printf("There was a problem running the diagnostic test.");
        exit(EXIT_FAILURE);
    }
    
    // Handle user input.
    [mainHelper handleUserInput];
    
    // End the program.
    [mainHelper closeProgram];
    return 0;
}

@implementation mainHelper
+(void)displayProgramInfo
{
    // Display the language and application.
    printf("Starting Objective-C Socket Client.\n");
    
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
    // Create "ping" message.
    byte_array message;
    message.size = 4;
    message.data = "ping";
    
    // Encode and send message.
    if (![self sendMessage:message])
    {
        return false;
    }
    
    // Receive and decode the message.
    byte_array decoded;
    if (![self receiveMessage:&decoded])
    {
        return false;
    }
    
    // Check that is successfully decoded as "ack".
    NSData *decodedData = [NSData dataWithBytes:decoded.data length:decoded.size];
    NSString* decodedStr = [NSString stringWithUTF8String:[decodedData bytes]];
    if ([decodedStr isEqualToString:@"ack"])
    {
        printf("Client Decoder decoded the message from the server Encoder successfully.\n");
    }
    else
    {
        fprintf(stderr, "Client Decoder DID NOT decode the message from the server Encoder successfully.\n");
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
        printf("Server closed connection.\n");
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

+(void)handleUserInput
{
    while (true)
    {
        // Prompt user for input to send to other side.
        char input[MAX_INPUT_BYTES] = "";
        
        printf("Please enter text up to %i bytes to send: (To end please type 'quit')\n", MAX_INPUT_BYTES);
        fflush(stdout);
        (void)fgets(input, sizeof(input), stdin);
        input[strlen(input) - 1] = '\0';
        if (strcasecmp(input, "quit") == 0)
        {
            break;
        }
        
        byte_array message;
        message.size = strlen(input);
        message.data = input;
        
        // Encode and send the input.
        if (![self sendMessage:message])
        {
            break;
        }
        
        // Receive and decode the returned data.
        byte_array decoded;
        if (![self receiveMessage:&decoded])
        {
            break;
        }
        
        // Compare the decoded message to the original.
        NSData *decodedData = [NSData dataWithBytes:decoded.data length:decoded.size];
        NSString* decodedStr = [NSString stringWithUTF8String:[decodedData bytes]];
        NSData* inputData = [NSData dataWithBytes:input length:strlen(input)];
        NSString* inputStr = [NSString stringWithUTF8String:[inputData bytes] ];
        if ([decodedStr isEqualToString:inputStr])
        {
            printf("The original input and decoded return match.\n");
        }
        else
        {
            fprintf(stderr,"The original input and decoded return DO NOT match.\n");
            break;
        }
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

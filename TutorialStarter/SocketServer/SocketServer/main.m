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

// Refer to the ReadMe.md and the source code in the TutorialMTE project to
// review the implementation of the MTE in a secure fashion.
// There are some other enhancements added to in this tutorial, such as a
// diagnostic test.

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#import "ServerSocketManager.h"
#include "globals.h"

char portBuff[6];

@interface mainHelper : NSObject
{

}
+(void)displayProgramInfo;
+(void)handleUserOutput;
+(bool)sendMessage:(const byte_array)message;
+(bool)receiveMessage:(byte_array*)message;
+(void)closeProgram;
@end

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
    
    // =========================================================
    // Step 1 - Encoder and Decoder Creation
    // Step 2 - Licensing
    // Step 3 - Information Exchange
    // Step 4 - Instantiation
    // Implemented with ServerMtheHelper.h and ServerMteHelper.m
    // =========================================================
    
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
}

+(bool)sendMessage:(const byte_array)message
{
    // =================
    // Step 5 - Encoding
    // =================
    
    // Send the message.
    const size_t res = send_message(message.data, message.size);
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
    if (msgStruct.success == false || msgStruct.message.size == 0)
    {
        printf("Client closed connection.\n");
        return false;
    }
    
    message->size = msgStruct.message.size;
    message->data = msgStruct.message.data;
    
    // =================
    // Step 6 - Decoding
    // =================
  
    return true;
    
}

+(void)handleUserOutput
{
    while (true)
    {
        // MARK: Listen for Client Messages
        printf("Listening for messages from Client . . .\n\n");
        
        // Receive the message from the client.
        byte_array message;
        if (![self receiveMessage:&message])
        {
            break;
        }
        
        // Send the input.
        if (![self sendMessage:message])
        {
            break;
        }
    }
}

+(void)closeProgram
{
    // =================
    // Step 7 - Clean Up
    // =================
    
    // Close the socket.
    close_socket();
    
    printf("Program stopped.\n");
}

@end



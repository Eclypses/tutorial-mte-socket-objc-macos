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

const char* serverIpAddress = "localhost";
const char* serverPort = "27015";
char ipBuff[25];
char portBuff[5];

int main()
{
    printf("Starting Objective-C Socket Client.\n");
    
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
        
        // For demonstration purposes only to show packets.
       printf("Packet being sent: %s\n", buffer);
        
        // Get length of message
        UInt64 buffBytes = strlen(buffer);
        
        // Get length of encoded data in network endianness
        uint32_t nBytes = htonl(buffBytes);
        
        // Send encoded data length to Server first
        if (send(server_sock, &nBytes, sizeof(nBytes), 0) != sizeof(nBytes)) {
            perror("\nClient Error: Sending encoded data to Server\n");
            exit(EXIT_FAILURE);
        }
        
        // then, send encoded data to Server
        if (send(server_sock, buffer, buffBytes, 0) != buffBytes) {
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
       
        printf("Received packet: %s\n", buffer);
        
    }
    return 0;
}

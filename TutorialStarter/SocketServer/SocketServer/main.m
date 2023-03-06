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

const char* port = "27015";
char portBuff[5];




int main()
{
    printf("Starting Objective-C Socket Server.\n");
    
    // Request port
    printf("Please enter port to use, press Enter to use default: %s\n", port);
    fgets(portBuff, 25, stdin);
    if (strncmp(portBuff, "\n", 3) != 0) {
        // Remove the newline character at the end of the message put there by fgets
        portBuff[strlen(portBuff) - 1] = '\0';
        port = portBuff;
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
        printf("Received packet: %s\n", buffer);
        
        printf("Packet being sent: %s\n", buffer);
                
        // Send the length data
        if (send(client_sock, &nBytes, sizeof(nBytes), 0) != sizeof(nBytes)) {
            perror("Unable to send reponse to Client");
            exit(EXIT_FAILURE);
        }
        
        // Send the real data
        if (send(client_sock, buffer, hBytes, 0) != hBytes) {
            perror("Unable to send reponse to Client");
            exit(EXIT_FAILURE);
        }
    }
    return 0;
}

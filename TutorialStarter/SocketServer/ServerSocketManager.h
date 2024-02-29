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

#ifndef ServerSocketManager_h
#define ServerSocketManager_h

#include "globals.h"
#include <stdbool.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define CHUNK_BYTES 64

struct recv_msg
{
    bool success;
    byte_array message;
};

#ifdef __cplusplus
extern "C"
{
#endif

/// <summary>
/// Creates the socket.
/// </summary>
/// <returns>1 if socket was created, 0 otherwise.</returns>
int create_socket();

/// <summary>
/// Binds the socket to the port.
/// </summary>
/// <param name="port">The port number.</param>
/// <returns>1 if socket was bound, 0 otherwise.</returns>
int bind_socket(int port);

/// <summary>
/// Listens for a socket connection.
/// </summary>
/// <returns>1 is socket is listening, 0 otherwise.</returns>
int listen_socket();

/// <summary>
/// Accepts the socket connection.
/// </summary>
/// <param name="port">The port number.</param>
/// <returns>1 is socket connection was accepted, 0 otherwise.</returns>
int accept_socket(char* port);

/// <summary>
/// Closes the socket.
/// </summary>
void close_socket();

/// <summary>
/// Sends the message through the socket.
/// </summary>
/// <param name="message">The message to be sent.</param>
/// <param name="message_bytes">The size of the message in bytes.</param>
/// <returns>The number of bytes sent.</returns>
size_t send_message(const char* message, size_t message_bytes);

/// <summary>
/// Receives the message through the socket.
/// </summary>
/// <returns>Struct that contains the message, message size in bytes, and success result.</returns>
struct recv_msg receive_message();

/// <summary>
/// Determines if the socket is valid.
/// </summary>
/// <returns></returns>
static bool is_socket_valid();

/// <summary>
/// Receives data for the amount of bytes needed.
/// </summary>
/// <param name="data">The data to be received.</param>
/// <param name="bytes_needed">The </param>
/// <returns></returns>
static bool recv_data(uint8_t* data, size_t bytes_needed);

#ifdef __cplusplus
}
#endif

#endif

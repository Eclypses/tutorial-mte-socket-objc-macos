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

#ifndef globals_h
#define globals_h

#define DEFAULT_PORT "27015"
#define DEFAULT_SERVER_IP "127.0.0.1"
#define MAX_INPUT_BYTES 100

#import "stddef.h"
#import "stdint.h"

// ***
// This is borrowed from the mte-support-ecdh package to assist in
// handling a pointer to the data and size.
// ***
typedef struct byte_array_ {
  size_t size;
  uint8_t *data;
} byte_array;
#endif /* globals_h */

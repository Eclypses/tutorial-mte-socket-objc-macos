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

#ifndef ClientMteHelper_h
#define ClientMteHelper_h


#import <Foundation/Foundation.h>
#import "ClientSocketManager.h"
#import "MteSetupInfo.h"
#import "MteBase.h"

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

// =====================================
// Step 1 - Encoder and Decoder Creation
// =====================================

@interface ClientMteHelper : NSObject {
#if defined USE_MTE_CORE
    MteEnc* encoder;
    MteDec* decoder;
#endif
#if defined USE_MKE_ADDON
    MteMkeEnc* encoder;
    MteMkeDec* decoder;
#endif
#if defined USE_FLEN_ADDON
    MteFlenEnc* encoder;
    MteDec* decoder;
#endif
    // Create the client Encoder and Decoder info structs.
    // Client Encoder -> Server Decoder;
    MteSetupInfo* clientEncoderInfo;
    // Client Decoder <- Server Encoder;
    MteSetupInfo* clientDecoderInfo;
}

// Initialize ClientMteHelper.
-(id)init;

/// <summary>
/// Initialize the MTE, including the MTE itself, the license, and the randomizer.
/// </summary>
/// <returns>True if MTE is initialized properly, false otherwise.</returns>
-(bool)initMte;

/// <summary>
/// Exchanges the information needed between the client and server for MTE setup.
/// </summary>
/// <returns>True if the information was exchanged successfully.</returns>
-(bool)exchangeMteInfo;

/// <summary>
/// Creates the Encoder.
/// </summary>
/// <returns>True if the Encoder was created successfully.</returns>
-(bool)createEncoder;

/// <summary>
/// Creates the Decoder.
/// </summary>
/// <returns>True if the Decoder was created successfully.</returns>
-(bool)createDecoder;

/// <summary>
/// Encodes the given message with the MTE. * Note that the caller must
/// run a "free(*encoded)" after processing the result. Otherwise a
/// memory leak will occur!
/// </summary>
/// <param name="message">The message to be encoded.</param>
/// <param name="encoded">The encoded message.</param>
/// <returns>True if MTE encoded successfully.</returns>
-(bool)encodeMessage:(byte_array) message : (byte_array*) encoded;

/// <summary>
/// Decodes the given encoded message with the MTE. * Note that the caller must
/// run a "free(*decoded_message)" after processing the result. Otherwise a
/// memory leak will occur!
/// </summary>
/// <param name="encoded">The encoded message.</param>
/// <param name="decoded">The decoded message.</param>
/// <returns>True if MTE decoded successfully.</returns>
-(bool)decodeMessage:(byte_array) encoded : (byte_array*) decoded;

/// <summary>
/// Gets the current timestamp.
/// </summary>
/// <returns>The timestamp.</returns>
-(uint64_t)getTimestamp;

/// <summary>
/// Displays the message in an ASCII hex representation.
/// </summary>
/// <param name="message">The message to be displayed.</param>
+(void)displayMessage:(const byte_array) message;

/// <summary>
/// Finalizes the Encoder and Decoder. Finishes the MTE random calls.
/// </summary>
-(void)finishMte;

@end

#endif /* ClientMteHelper_h */

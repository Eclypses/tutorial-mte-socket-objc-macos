![Eclypses Logo alt text](./Eclypses_H_C_M-R.png =500x)

<div align="center" style="font-size:40pt; font-weight:900; font-family:arial; margin-top:300px; " >
Objective-C MacOS Server and Client Socket Tutorials</div>

<div align="center" style="font-size:28pt; font-family:arial; " >
MTE Implementation Tutorials </div>
<div align="center" style="font-size:15pt; font-family:arial; " >
Using MTE version 2.2.x</div>

[Introduction](#introduction)

[Socket Tutorial Server and Client](#socket-tutorial-server-and-client)<br>
- [Add MTE Files](#add-mte-files)<br>
- [Create Initial values](#create-initial-values)<br>
- [Check For License](#check-for-license)<br>
- [Create Encoder and/or Decoder](#create-encoder-and/or-decoder)<br>
- [Encode and Decode Sample Calls](#encode-and-decode-sample-calls)<br>

[Contact Eclypses](#contact-eclypses)


<div style="page-break-after: always; break-after: page;"></div>

# Introduction

This tutorial is sending messages via a socket connection. This is only a sample, the MTE does NOT require the usage of sockets, you can use whatever communication protocol that is needed.

This tutorial demonstrates how to use Mte Core, Mte MKE and Mte Fixed Length. Depending on what your needs are, these three different implementations can be used in the same application OR you can use any one of them. They are not dependent on each other and can run simultaneously in the same application if needed. 

The SDK that you received from Eclypses may not include the MKE or MTE FLEN add-ons. If your SDK contains either the MKE or the Fixed Length add-ons, the name of the SDK will contain "-MKE" or "-FLEN". If these add-ons are not there and you need them please work with your sales associate. If there is no need, please just ignore the MKE and FLEN options.

Here is a short explanation of when to use each, but it is encouraged to either speak to a sales associate or read the dev guide if you have additional concerns or questions.

***MTE Core:*** This is the recommended version of the MTE to use. Unless payloads are large or sequencing is needed this is the recommended version of the MTE and the most secure.

***MTE MKE:*** This version of the MTE is recommended when payloads are very large, the MTE Core would, depending on the token byte size, be multiple times larger than the original payload. Because this uses the MTE technology on encryption keys and encrypts the payload, the payload is only enlarged minimally.

***MTE Fixed Length:*** This version of the MTE is very secure and is used when the resulting payload is desired to be the same size for every transmission. The Fixed Length add-on is mainly used when using the sequencing verifier with MTE. In order to skip dropped packets or handle asynchronous packets the sequencing verifier requires that all packets be a predictable size. If you do not wish to handle this with your application then the Fixed Length add-on is a great choice. This is ONLY an encoder change - the decoder that is used is the MTE Core decoder.

In this tutorial we are creating an MTE Encoder and an MTE Decoder in the server as well as the client because we are sending secured messages in both directions. This is only needed when there are secured messages being sent from both sides, the server as well as the client. If only one side of your application is sending secured messages, then the side that sends the secured messages should have an Encoder and the side receiving the messages needs only a Decoder.

These steps should be followed on the server side as well as on the client side of the program.

**IMPORTANT**
>Please note the solution provided in this tutorial does NOT include the MTE library or supporting MTE library files. If you have NOT been provided an MTE library and supporting files, please contact Eclypses Inc. The solution will only work AFTER the MTE library and MTE library files have been incorporated.

# Socket Tutorial Server and Client Setup

To existing server and client projects, ...
## Add MTE Files

<ol>
<li>At the root of the project, create a new directory named "MTE", this will hold the needed MTE files.</li>
<br>
<li>Copy the "include" and "lib" directories from the mte-Darwin package into the new "MTE" directory.</li>
<br>
<li>If using the MTE Core, copy the MteBase.h, MteBase.m, MteEnc.h, MteEnc.m, MteDec.h, and MteDec.m files from the "src/objc" directory from the package to the "MTE" directory. If using the MTE MKE, copy the MteBase.h, MteBase.m, MteMkeEnc.h, MteMkeEnc.m, MteMkeDec.h and MteMkeDec.m files. If using the Mte Fixed length, copy the MteBase.h, MteBase.m, MteFlenEnc.h, MteFlenEnc.m, MteDec.h, and MteDec.m files.</li>
<br>
<li>Update the project settings of both SocketClient and SocketServer in Xcode with the following:</li>
<ul>
<li>Update the "Header Search Paths" in the "Build Settings" tab to include the "Mte/include" directory.</li>
<li>Update the "Library Search Paths" in the "Build Settings" tab to include the "Mte/lib" directory.</li>
<li>Add the objective-c source files in the "Compile Sources" section in the "Build Phases" tab of the SocketClient/SocketServer target.</li>
<li>Add the libmte_mteb.a,libmte_mtesupp.a, libmte_mtee.a, and libmte_mted.a files from the "MTE/lib" directory to the "Link Binary With Libraries" section in the "Build Phases" tab of the SocketClient/SocketServer target. If using the MTE MKE, also add the libmte_mkee.a and libmte_mked.a files. If using MTE Fixed length, also add the libmte_flen.a file.</li>
</ul>

<li>Navigate to each "main.m" file for both the SocketClient and SocketServer projects. Create the MTE Decoder and MTE Encoder as well as the accompanying MTE<sup>TM</sup> status for each as global variables. Also include fixed length parameter if using FLEN.</li>

```objective-c
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
```

<li>Add include statements for both the MTE Encoder and MTE Decoder near the beginning of the main.m files (SocketClient And SocketServer).</li>

```objective-c
#import "MteBase.h"
#import "mte_alloca.h"
#include <netdb.h>

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
```

<li>To ensure the MTE library is licensed correctly, run the license check. The LicenseCompanyName, and LicenseKey below should be replaced with your company’s MTE license information provided by Eclypses. If a trial version of the MTE is being used any value can be passed into those fields and it will work.</li>

```objective-c
// Check MTE License
if (![MteBase initLicense : @"LicenseCompanyName" code:@"LicenseKey"]) {
    printf("There was an error attempting to initialize the MTE License.\n");
    exit(EXIT_FAILURE);
}
```

<li>Create MTE Decoder Instances and MTE Encoder Instances.</li>
Here is a sample that creates the MTE Encoder.

```objective-c
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
```
Here is a sample that creates the MTE Decoder.
```objective-c
#if defined USE_MTE_CORE || defined USE_FLEN_ADDON
    decoder = MTE_AUTORELEASE([[MteDec alloc]init] );
#endif
#if defined USE_MKE_ADDON
    decoder = MTE_AUTORELEASE([[MteMkeDec alloc]init] );
#endif
```
<li>We need to be able to set the entropy, nonce, and personalization/identification values.</li>
These values should be treated like encryption keys and never exposed. For demonstration purposes in the tutorial we are setting these values in the code. In a production environment these values should be protected and not available to outside sources. For the entropy, we have to determine the size of the allowed entropy value based on the drbg we have selected. A code sample below is included to demonstrate how to get these values.

To set the entropy in the tutorial we are simply getting the minimum bytes required and creating a byte array of that length that contains all zeros. We want to set the default first to be blank.
```objective-c
// IMPORTANT! ** This is an entirely insecure way of setting Entropy
// and MUST NOT be used in a "real" application. See MTE Developer's Guide for more information.
// Get the minimum entropy length for the DRBG.
size_t eMinBytes = [MteBase getDrbgsEntropyMinBytes : [encoder getDrbg] ];

// then, allocate that length on the stack and zero it.
char* entropy = MTE_ALLOCA(eMinBytes);
memset(entropy, '0', eMinBytes);
```

To set the nonce and the personalization/identifier string we are simply adding our default values.
```objective-c
// In this tutorial, we set the encoder and decoder nonces differently so the encoded payloads will appear different
// even though the data prior to encoding is the same. They are reversed on the Client so they match up with the Server
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
```

*(For further information on Encoder constructor and initialization review the DevelopersGuide)*
```objective-c

// Initialize Decoder

// MTE will have 'zeroed' the entropy when it was set on the encoder so we need to 'refill' it.
memset(entropy, '0', eMinBytes);

// Instantiate the encoder.
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
```
*(For further information on Decoder constructor and initialization review the DevelopersGuide)*
<br>
***When the above steps are completed on both the server and the client, the MTE will be ready for use.***

<li>Finally, we need to add the MTE calls to encode and decode the messages that we are sending and receiving from the other side. (Ensure on the server side the Encoder is used to encode the outgoing text, then the Decoder is used to decode the incoming response.)</li>
<br>
Here is a sample of how to do this on the Client side.

```objective-c
// Encode the input
size_t encodedBytes;
const void* encodedResult = [encoder encode : buffer dataBytes : strlen(buffer) encodedBytes : &encodedBytes status : &encoderStatus];
if (encoderStatus != mte_status_success) {
    printf("Error encoding: Status %s/ %s\n",
      [[MteBase getStatusName : encoderStatus]UTF8String],
      [[MteBase getStatusDescription : encoderStatus]UTF8String] );
    exit(EXIT_FAILURE);
}
		
// Decode the incoming data.
size_t decodedBytes = 0;
[decoder decode : buffer encodedBytes : hBytes decodedBytes : &decodedBytes status : &decoderStatus] ;
if ([MteBase statusIsError : decoderStatus]) {
    printf("Decoder error. Error: %s, %s\n",
      [[MteBase getStatusName : decoderStatus]UTF8String],
      [[MteBase getStatusDescription : decoderStatus]UTF8String] );
    exit(EXIT_FAILURE);
}
```
Here is a sample of how to do this on the Server side.
```objective-c
// Decode the incoming data.
size_t decodedBytes = 0;
void* decodedResult = [decoder decode : buffer encodedBytes : hBytes decodedBytes : &decodedBytes status : &decoderStatus];
if ([MteBase statusIsError : decoderStatus]) {
    printf("Decoder error. Error: %s, %s\n",
      [[MteBase getStatusName : decoderStatus]UTF8String],
      [[MteBase getStatusDescription : decoderStatus]UTF8String] );
     exit(EXIT_FAILURE);
 }
 
// Encode the data with MTE
size_t encodedBytes;
const void* encodedResult = [encoder encode : decodedResult dataBytes : decodedBytes
    encodedBytes : &encodedBytes status : &encoderStatus];
if (encoderStatus != mte_status_success) {
    printf("Encoder error. Error: %s, %s\n",
      [[MteBase getStatusName : encoderStatus]UTF8String],
      [[MteBase getStatusDescription : encoderStatus]UTF8String] );
    exit(EXIT_FAILURE);
}
```
</ol>
<div style="page-break-after: always; break-after: page;"></div>

# Contact Eclypses

<p align="center" style="font-weight: bold; font-size: 22pt;">For more information, please contact:</p>
<p align="center" style="font-weight: bold; font-size: 22pt;"><a href="mailto:info@eclypses.com">info@eclypses.com</a></p>
<p align="center" style="font-weight: bold; font-size: 22pt;"><a href="https://www.eclypses.com">www.eclypses.com</a></p>
<p align="center" style="font-weight: bold; font-size: 22pt;">+1.719.323.6680</p>

<p style="font-size: 8pt; margin-bottom: 0; margin: 300px 24px 30px 24px; " >
<b>All trademarks of Eclypses Inc.</b> may not be used without Eclypses Inc.'s prior written consent. No license for any use thereof has been granted without express written consent. Any unauthorized use thereof may violate copyright laws, trademark laws, privacy and publicity laws and communications regulations and statutes. The names, images and likeness of the Eclypses logo, along with all representations thereof, are valuable intellectual property assets of Eclypses, Inc. Accordingly, no party or parties, without the prior written consent of Eclypses, Inc., (which may be withheld in Eclypses' sole discretion), use or permit the use of any of the Eclypses trademarked names or logos of Eclypses, Inc. for any purpose other than as part of the address for the Premises, or use or permit the use of, for any purpose whatsoever, any image or rendering of, or any design based on, the exterior appearance or profile of the Eclypses trademarks and or logo(s).
</p>

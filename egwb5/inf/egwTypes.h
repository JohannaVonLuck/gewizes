// Copyright (C) 2008-2011 JWmicro. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of the JWmicro nor the names of its contributors may
//    be used to endorse or promote products derived from this software
//    without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/// @defgroup geWizES_inf_types egwTypes
/// @ingroup geWizES_inf
/// Engine Types.
/// @{

/// @file egwTypes.h
/// Engine Types.

#import <float.h>
#import <stdint.h>
#import <sys/types.h>
#if defined(EGW_BUILDMODE_IPHONE) || defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)
#import <Foundation/Foundation.h>
#endif


// !!!: ***** Resolutions *****

// Operating System ID
#define EGW_OS_LINUX_ID             0x01
#define EGW_OS_WINDOWS_ID           0x02
#define EGW_OS_MACINTOSH_ID         0x04
#if defined(__linux)
    #define EGW_OS_LINUX
    #define EGW_OS_IDENT            EGW_OS_LINUX_ID
#elif defined(_WIN32) || defined(_WIN64) || defined (__WINDOWS__) || defined(__WIN32__)
    #define EGW_OS_WINDOWS
    #define EGW_OS_IDENT            EGW_OS_WINDOWS_ID
#elif defined(__APPLE__) || defined (__MACH__) || defined(__MAC_OS_X_VERSION_10_0)
    #define EGW_OS_MACINTOSH
    #define EGW_OS_IDENT            EGW_OS_MACINTOSH_ID
#else
    #error 'Operating system not supported.'
#endif

// Compiler ID
#define EGW_CC_GNUC_ID              0x01
#define EGW_CC_MSVC_ID              0x02
#define EGW_IASM_ATNT_ID            0x01
#define EGW_IASM_INTEL_ID           0x02
#if defined(__GNUC__)
    #define EGW_CC_GNUC
    #define EGW_CC_IDENT            EGW_CC_GNUC_ID
    #define EGW_CC_VER              (__GNUC__ * 100 + __GNUC_MINOR__)
    #define EGW_EXPORT              // nothing
    #define EGW_HALT                __asm__("int $3;")
    #define EGW_NO_OP               static_cast<void>(0)
    #define EGW_IASM_ATNT
    #define EGW_IASM_TYPE           EGW_IASM_ATNT_ID
#elif defined(_MSC_VER)
    #define EGW_CC_MSVC
    #define EGW_CC_IDENT            EGW_CC_MSVC_ID
    #define EGW_CC_VER              _MSC_VER
    #define EGW_USE_EXPORT
    #define EGW_EXPORT              export
    #define EGW_HALT                __debugbreak()
    #define EGW_NO_OP               (void)0
    #define EGW_IASM_INTEL
    #define EGW_IASM_TYPE           EGW_IASM_INTEL_ID
#else
    #error 'Compiler not supported.'
#endif

// CPU Architecture
#define EGW_ARCH_32_386_ID          0x7e82  // 32,386
#define EGW_ARCH_32_486_ID          0x7ee6  // 32,486
#define EGW_ARCH_32_586_ID          0x7f4a  // 32,586
#define EGW_ARCH_32_686_ID          0x7fae  // 32,686
#define EGW_ARCH_64_100_ID          0xfa64  // 64,100
#define EGW_ARCH_32_ARM_ID          0x7d64  // 32,100
#if defined(EGW_CC_GNUC)
    #if defined(__arm__)
        #define EGW_ARCH_ARM
        #define EGW_ARCH_IDENT      EGW_ARCH_32_ARM_ID
    #elif defined(i386) || defined(__i386__) 
        #define EGW_ARCH_32
        #if defined(__i686__)
            #define EGW_ARCH_32_686
            #define EGW_ARCH_IDENT  EGW_ARCH_32_686_ID
        #elif defined(__i586__)
            #define EGW_ARCH_32_586
            #define EGW_ARCH_IDENT  EGW_ARCH_32_586_ID
        #elif defined(__i486__)
            #define EGW_ARCH_32_486
            #define EGW_ARCH_IDENT  EGW_ARCH_32_486_ID
        #elif defined(__i386__)
            #define EGW_ARCH_32_386
            #define EGW_ARCH_IDENT  EGW_ARCH_32_386_ID
        #else
            #error 'Architecture not supported.'
        #endif
    #elif defined(__x86_64__) || defined(__IA64__)
        #define EGW_ARCH_64
        #define EGW_ARCH_IDENT      EGW_ARCH_64_100_ID
    #else
        #error 'Architecture not supported.'
    #endif
#elif defined(EGW_CC_MSVC)
    #if defined(_M_IX86)
        #define EGW_ARCH_32
        #if (_M_IX86 == 600)
            #define EGW_ARCH_32_686
            #define EGW_ARCH_IDENT  EGW_ARCH_32_686_ID
        #elif (_M_IX86 == 500)
            #define EGW_ARCH_32_586
            #define EGW_ARCH_IDENT  EGW_ARCH_32_586_ID
        #elif (_M_IX86 == 400)
            #define EGW_ARCH_32_486
            #define EGW_ARCH_IDENT  EGW_ARCH_32_486_ID
        #elif (_M_IX86 == 300)
            #define EGW_ARCH_32_386
            #define EGW_ARCH_IDENT  EGW_ARCH_32_386_ID
        #else
            #error 'Architecture not supported.'
        #endif
    #elf defined(_WIN64) || defined(_M_IA64)
        #define EGW_ARCH_64
        #define EGW_ARCH_IDENT  EGW_ARCH_64_100_ID
    #else
        #error 'Architecture not supported.'
    #endif
#else
    #error 'Architecture not supported.'
#endif

// Dependency Macros
#if defined(EGW_ARCH_32)
    #define EGW_ARCH_DEP_REGSIZE        0x20
    #define EGW_ARCH_DEP_REGMAXVAL      0xffffffff
    #define EGW_ARCH_DEP_REGNAME(RG16)  e##RG16
    #define EGW_ARCH_DEP_WORDNAME       dword
#elif defined(EGW_ARCH_64)
    #define EGW_ARCH_DEP_REGSIZE        0x40
    #define EGW_ARCH_DEP_REGMAXVAL      0xffffffffffffffff
    #define EGW_ARCH_DEP_REGNAME(RG16)  r##RG16
    #define EGW_ARCH_DEP_WORDNAME       qword
#elif defined(EGW_ARCH_ARM)
    #define EGW_ARCH_DEP_REGSIZE        0x20
    #define EGW_ARCH_DEP_REGMAXVAL      0xffffffff
    #define EGW_ARCH_DEP_REGNAME(RGN)   r##RGN
    #define EGW_ARCH_DEP_WORDNAME       dword
#endif
#if defined(EGW_CC_GNUC)
    //#if !defined(EGW_ARCH_ARM)
    //    #define EGW_ATRB_FASTCALL       __attribute__((fastcall))
    //#else
        #define EGW_ATRB_FASTCALL       // nothing
    //#endif
#elif defined(EGW_CC_MSVC)
    #if !defined(EGW_ARCH_ARM)
        #define EGW_ATRB_FASTCALL       __fastcall
    #else
        #define EGW_ATRB_FASTCALL       // nothing
    #endif
#endif

// Inline Assembly Macros with RBX(64)/EBX(32)
#if defined(EGW_IASM_ATNT)
    #if defined(EGW_ARCH_32)
        #define EGW_IASM_GPRB_LOAD(PTR) __asm__ __volatile__ ("movl %%eax, %%ebx" : : "a"(PTR) : )
        #define EGW_IASM_GPRB_PUSH  __asm__ __volatile__ ("push %ebx")
        #define EGW_IASM_GPRB_POP   __asm__ __volatile__ ("pop %ebx")
    #elif defined(EGW_ARCH_64)
        #define EGW_IASM_GPRB_LOAD(PTR) __asm__ __volatile__ ("movq %%rax, %%rbx" : : "a"(PTR) : )
        #define EGW_IASM_GPRB_PUSH  __asm__ __volatile__ ("push %rbx")
        #define EGW_IASM_GPRB_POP   __asm__ __volatile__ ("pop %rbx")
    #elif defined(EGW_ARCH_ARM)
        #define EGW_IASM_GPRB_LOAD(PTR) __asm__ __volatile__ ("movq %%r1, %%r2" : : "1"(PTR) : )
        #define EGW_IASM_GPRB_PUSH  __asm__ __volatile__ ("push %r2")
        #define EGW_IASM_GPRB_POP   __asm__ __volatile__ ("pop %r2")
    #endif
    #define EGW_IASM_GPRB_SAVE(PTR) __asm__ __volatile__ ("nop" : "=b"(PTR) : : "memory" )
#elif defined (EGW_IASM_INTEL)
    #define EGW_IASM_GPRB_LOAD(PTR) __asm { mov EGW_ARCH_DEP_REGNAME(bx),  EGW_ARCH_DEP_WORDNAME PTR }
    #define EGW_IASM_GPRB_SAVE(PTR) __asm { mov EGW_ARCH_DEP_WORDNAME PTR, EGW_ARCH_DEP_REGNAME(bx)  }
    #define EGW_IASM_GPRB_PUSH      __asm { push EGW_ARCH_DEP_REGNAME(bx) }
    #define EGW_IASM_GPRB_POP       __asm { pop EGW_ARCH_DEP_REGNAME(bx) }
#endif


// !!!: ***** Typedefs *****

typedef int8_t                  EGWint8;    ///< 8-bit signed integer type.
typedef int16_t                 EGWint16;   ///< 16-bit signed integer type.
typedef int32_t                 EGWint32;   ///< 32-bit signed integer type.
typedef int64_t                 EGWint64;   ///< 64-bit signed integer type.
typedef uint8_t                 EGWuint8;   ///< 8-bit unsigned integer type.
typedef uint16_t                EGWuint16;  ///< 16-bit unsigned integer type.
typedef uint32_t                EGWuint32;  ///< 32-bit unsigned integer type.
typedef uint64_t                EGWuint64;  ///< 64-bit unsigned integer type.
#ifndef EGW_ARCH_64
typedef int32_t                 EGWint;     ///< Register-sized signed integer type.
typedef uint32_t                EGWuint;    ///< Register-sized unsigned integer type.
#else
typedef int64_t                 EGWint;     ///< Register-sized signed integer type.
typedef uint64_t                EGWuint;    ///< Register-sized unsigned integer type.
#endif
#ifdef __LP64__
typedef EGWint64                EGWintptr;  ///< Pointer-sized signed integer pointer type.
typedef EGWuint64               EGWuintptr; ///< Pointer-sized unsigned integer pointer type.
#else
typedef EGWint                  EGWintptr;  ///< Pointer-sized signed integer pointer type.
typedef EGWuint                 EGWuintptr; ///< Pointer-sized unsigned integer pointer type.
#endif
typedef int8_t                  EGWchar;    ///< Character type.
typedef uint8_t                 EGWbyte;    ///< Byte data type.
typedef float                   EGWsingle;  ///< Single-precision floater type.
typedef double                  EGWdouble;  ///< Double-precision floater type.
typedef long double             EGWtriple;  ///< Triple-precision floater type.
typedef EGWdouble               EGWtime;    ///< Time type.


// !!!: ***** Defines *****

#define EGW_INT8_MIN            INT8_MIN
#define EGW_INT8_MAX            INT8_MAX
#define EGW_INT16_MIN           INT16_MIN
#define EGW_INT16_MAX           INT16_MAX
#define EGW_INT32_MIN           INT32_MIN
#define EGW_INT32_MAX           INT32_MAX
#define EGW_INT64_MIN           INT64_MIN
#define EGW_INT64_MAX           INT64_MAX
#define EGW_UINT8_MIN           UINT8_MIN
#define EGW_UINT8_MAX           UINT8_MAX
#define EGW_UINT16_MIN          UINT16_MIN
#define EGW_UINT16_MAX          UINT16_MAX
#define EGW_UINT32_MIN          UINT32_MIN
#define EGW_UINT32_MAX          UINT32_MAX
#define EGW_UINT64_MIN          UINT64_MIN
#define EGW_UINT64_MAX          UINT64_MAX
#ifndef EGW_ARCH_64
#define EGW_INT_MIN             EGW_INT32_MIN
#define EGW_INT_MAX             EGW_INT32_MAX
#define EGW_UINT_MAX            EGW_UINT32_MAX
#define EGW_UINT_MAX            EGW_UINT32_MAX
#else
#define EGW_INT_MIN             EGW_INT64_MIN
#define EGW_INT_MAX             EGW_INT64_MAX
#define EGW_UINT_MAX            EGW_UINT64_MAX
#define EGW_UINT_MAX            EGW_UINT64_MAX
#endif
#ifdef __LP64__
#define EGW_INTPTR_MIN          EGW_INT64_MIN
#define EGW_INTPTR_MAX          EGW_INT64_MAX
#define EGW_UINTPTR_MIN         EGW_UINT64_MIN
#define EGW_UINTPTR_MAX         EGW_UINT64_MAX
#else
#define EGW_INTPTR_MIN          EGW_INT_MIN
#define EGW_INTPTR_MAX          EGW_INT_MAX
#define EGW_UINTPTR_MIN         EGW_UINT_MIN
#define EGW_UINTPTR_MAX         EGW_UINT_MAX
#endif
#define EGW_CHAR_MIN            EGW_INT8_MIN
#define EGW_CHAR_MAX            EGW_INT8_MAX
#define EGW_BYTE_MIN            EGW_UINT8_MIN
#define EGW_BYTE_MAX            EGW_UINT8_MAX
#define EGW_SFLT_EPSILON        FLT_EPSILON
#define EGW_SFLT_MIN            FLT_MIN
#define EGW_SFLT_MAX            FLT_MAX
#define EGW_SFLT_NAN            ((EGWsingle)NAN)
#define EGW_SFLT_INF            ((EGWsingle)INFINITY)
#define EGW_DFLT_EPSILON        DBL_EPSILON
#define EGW_DFLT_MIN            DBL_MIN
#define EGW_DFLT_MAX            DBL_MAX
#define EGW_DFLT_NAN            ((EGWdouble)NAN)
#define EGW_DFLT_INF            ((EGWdouble)INFINITY)
#define EGW_TFLT_EPSILON        LDBL_EPSILON
#define EGW_TFLT_MIN            LDBL_MIN
#define EGW_TFLT_MAX            LDBL_MAX
#define EGW_TFLT_NAN            ((EGWtriple)NAN)
#define EGW_TFLT_INF            ((EGWtriple)INFINITY)
#define EGW_TIME_EPSILON        EGW_DFLT_EPSILON
#define EGW_TIME_MIN            EGW_DFLT_MIN
#define EGW_TIME_MAX            EGW_DFLT_MAX
#define EGW_TIME_NAN            EGW_DFLT_NAN
#define EGW_TIME_INF            EGW_DFLT_INF


// !!!: ***** Predefs *****

// Abstraction Layer
@protocol egwPContext;
@protocol egwPGfxContext;
@protocol egwPPhyContext;
@protocol egwPSndContext;
@protocol egwPCoreObject;

// System Layer
@protocol egwPHook;
@protocol egwPScreen;
@protocol egwPSingleton;
@protocol egwPTask;
@protocol egwPSubTask;

// Object Layer
@protocol egwPAsset;
@protocol egwPAssetBase;
@protocol egwPCoreObject;
@protocol egwPObjectNode;
@protocol egwPObjectBranch;
@protocol egwPObjectLeaf;
@protocol egwPInteractable;
@protocol egwPPlayable;
@protocol egwPRenderable;

// Ability Layer
@protocol egwPActioned;
@protocol egwPActuator;
@protocol egwPBounding;
@protocol egwPCamera;
@protocol egwPGeometry;
@protocol egwPInterpolator;
@protocol egwPLight;
@protocol egwPMaterial;
@protocol egwPOrientated;
@protocol egwPSound;
@protocol egwPStreamed;
@protocol egwPStreamer;
@protocol egwPTexture;
@protocol egwPTimed;
@protocol egwPTimer;
@protocol egwPWarned;
@protocol egwPWidget;

/// @}

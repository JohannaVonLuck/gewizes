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

/// @defgroup geWizES_inf_psingleton egwPSingleton
/// @ingroup geWizES_inf
/// Singleton Protcol.
/// @{

/// @file egwPSingleton.h
/// Singleton Protcol.

#import "egwTypes.h"


/// Singleton Protocol.
/// Defines interactions for singleton classes (e.g. ones that maintain only one unique instance).
@protocol egwPSingleton <NSObject>

/// Allocation Class Method.
/// Allocates and returns the singleton instance.
/// @return Singleton instance.
+ (id)alloc;

/// Deallocation Class Method.
/// Deallocates the singleton instance.
+ (void)dealloc;

/// Singleton Instance Class Accessor.
/// Returns the singleton instance.
/// @return Singleton instance.
+ (id)sharedSingleton;


/// Singleton Copy Method.
/// Averts copy and returns the singleton instance.
/// @return Singleton instance.
- (id)copy;

/// Singleton Mutable Copy Method.
/// Averts copy and returns the singleton instance.
/// @return Singleton instance.
- (id)mutableCopy;


/// IsAllocated Class Poller.
/// Polls the object to determine status.
/// @return YES if singleton is allocated, otherwise NO.
+ (BOOL)isAllocated;

@end

/// @}

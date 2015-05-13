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

/// @defgroup geWizES_math_vector egwVector
/// @ingroup geWizES_math
/// Vector.
/// @{

/// @file egwVector.h
/// Vector Interface.

#import "egwMathTypes.h"


// !!!: ***** Shared Instances *****

extern const egwVector2f egwSIVecZero2f;          ///< Shared 2-D zero vector instance.
extern const egwVector3f egwSIVecZero3f;          ///< Shared 3-D zero vector instance.
extern const egwVector4f egwSIVecZero4f;          ///< Shared 4-D zero vector instance.

extern const egwVector2f egwSIVecOne2f;           ///< Shared 2-D one vector instance.
extern const egwVector3f egwSIVecOne3f;           ///< Shared 3-D one vector instance.
extern const egwVector4f egwSIVecOne4f;           ///< Shared 4-D one vector instance.

extern const egwVector2f egwSIVecUnitX2f;         ///< Shared 2-D unit-X vector instance.
extern const egwVector3f egwSIVecUnitX3f;         ///< Shared 3-D unit-X vector instance.
extern const egwVector4f egwSIVecUnitX4f;         ///< Shared 4-D unit-X vector instance.

extern const egwVector2f egwSIVecUnitY2f;         ///< Shared 2-D unit-Y vector instance.
extern const egwVector3f egwSIVecUnitY3f;         ///< Shared 3-D unit-Y vector instance.
extern const egwVector4f egwSIVecUnitY4f;         ///< Shared 4-D unit-Y vector instance.

extern const egwVector3f egwSIVecUnitZ3f;         ///< Shared 3-D unit-Z vector instance.
extern const egwVector4f egwSIVecUnitZ4f;         ///< Shared 4-D unit-Z vector instance.

extern const egwVector4f egwSIVecUnitW4f;         ///< Shared 4-D unit-W vector instance.

extern const egwVector2f egwSIVecNegUnitX2f;      ///< Shared 2-D unit-X vector instance.
extern const egwVector3f egwSIVecNegUnitX3f;      ///< Shared 3-D unit-X vector instance.
extern const egwVector4f egwSIVecNegUnitX4f;      ///< Shared 4-D unit-X vector instance.

extern const egwVector2f egwSIVecNegUnitY2f;      ///< Shared 2-D unit-Y vector instance.
extern const egwVector3f egwSIVecNegUnitY3f;      ///< Shared 3-D unit-Y vector instance.
extern const egwVector4f egwSIVecNegUnitY4f;      ///< Shared 4-D unit-Y vector instance.

extern const egwVector3f egwSIVecNegUnitZ3f;      ///< Shared 3-D unit-Z vector instance.
extern const egwVector4f egwSIVecNegUnitZ4f;      ///< Shared 4-D unit-Z vector instance.

extern const egwVector4f egwSIVecNegUnitW4f;      ///< Shared 4-D unit-W vector instance.


// !!!: ***** Initialization *****

/// 2-D Vector Initialization Routine.
/// Initializes vector with provided parameters.
/// @param [out] vec_out 2-D vector output of initialization.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecInit2f(egwVector2f* vec_out, const EGWsingle x, const EGWsingle y);

/// 3-D Vector Initialization Routine.
/// Initializes vector with provided parameters.
/// @param [out] vec_out 3-D vector output of initialization.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecInit3f(egwVector3f* vec_out, const EGWsingle x, const EGWsingle y, const EGWsingle z);

/// 4-D Vector Initialization Routine.
/// Initializes vector with provided parameters.
/// @param [out] vec_out 4-D vector output of initialization.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @param [in] w W-coordinate value.
/// @return @a vec_out (for nesting).
egwVector4f* egwVecInit4f(egwVector4f* vec_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWsingle w);

/// Arrayed 2-D Vector Initialization Routine.
/// Initializes array of vectors with provided parameters.
/// @param [out] vecs_out Array of 2-D vector outputs of initializations.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecInit2fv(egwVector2f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Initialization Routine.
/// Initializes array of vectors with provided parameters.
/// @param [out] vecs_out Array of 3-D vector outputs of initializations.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecInit3fv(egwVector3f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4-D Vector Initialization Routine.
/// Initializes array of vectors with provided parameters.
/// @param [out] vecs_out Array of 4-D vector outputs of initializations.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @param [in] w W-coordinate value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecInit4fv(egwVector4f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWsingle w, const EGWintptr strideB_out, EGWuint count);

/// 2-D Vector Copy Routine.
/// Initializes vector from deep copy of another.
/// @param [in] vec_in 2-D vector input operand.
/// @param [out] vec_out 2-D vector output of copy.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecCopy2f(const egwVector2f* vec_in, egwVector2f* vec_out);

/// 3-D Vector Copy Routine.
/// Initializes vector from deep copy of another.
/// @param [in] vec_in 3-D vector input operand.
/// @param [out] vec_out 3-D vector output of copy.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecCopy3f(const egwVector3f* vec_in, egwVector3f* vec_out);

/// 4-D Vector Copy Routine.
/// Initializes vector from deep copy of another.
/// @param [in] vec_in 4-D vector input operand.
/// @param [out] vec_out 4-D vector output of copy.
/// @return @a vec_out (for nesting).
egwVector4f* egwVecCopy4f(const egwVector4f* vec_in, egwVector4f* vec_out);

/// Arrayed 2-D Vector Copy Routine.
/// Initializes array of vectors from copies of another.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecCopy2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Copy Routine.
/// Initializes array of vectors from copies of another.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecCopy3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, const EGWuint count);

/// Arrayed 4-D Vector Copy Routine.
/// Initializes array of vectors from copies of another.
/// @param [in] vecs_in Array of 4-D vector input operands.
/// @param [out] vecs_out Array of 4-D vector outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecCopy4fv(const egwVector4f* vecs_in, egwVector4f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Testing *****

/// 2-D Vector Equality Testing Routine.
/// Determines if two provided vectors are equivalent.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return 1 if @a vec_lhs is pair-wise equal to @a vec_rhs, otherwise 0.
EGWint egwVecIsEqual2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Equality Testing Routine.
/// Determines if two provided vectors are equivalent.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return 1 if @a vec_lhs is pair-wise equal to @a vec_rhs, otherwise 0.
EGWint egwVecIsEqual3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// 4-D Vector Equality Testing Routine.
/// Determines if two provided vectors are equivalent.
/// @param [in] vec_lhs 4-D vector lhs operand.
/// @param [in] vec_rhs 4-D vector rhs operand.
/// @return 1 if @a vec_lhs is pair-wise equal to @a vec_rhs, otherwise 0.
EGWint egwVecIsEqual4f(const egwVector4f* vec_lhs, const egwVector4f* vec_rhs);

/// 2-D Positional Vector Testing Routine.
/// Determines if provided vector is positional (i.e. w-coord <1>).
/// @param [in] vec_in 2-D vector input operand.
/// @return 1 if @a vec_in is positional, otherwise 0.
EGWint egwVecIsPointVec2f(const egwVector3f* vec_in);

/// 3-D Positional Vector Testing Routine.
/// Determines if provided vector is positional (i.e. w-coord <1>).
/// @param [in] vec_in 3-D vector input operand.
/// @return 1 if @a vec_in is positional, otherwise 0.
EGWint egwVecIsPointVec3f(const egwVector4f* vec_in);

/// 2-D Directional Vector Testing Routine.
/// Determines if provided vector is directional (i.e. w-coord <0>).
/// @param [in] vec_in 2-D vector input operand.
/// @return 1 if @a vec_in is directional, otherwise 0.
EGWint egwVecIsDirectionVec2f(const egwVector3f* vec_in);

/// 3-D Directional Vector Testing Routine.
/// Determines if provided vector is directional (i.e. w-coord <0>).
/// @param [in] vec_in 3-D vector input operand.
/// @return 1 if @a vec_in is directional, otherwise 0.
EGWint egwVecIsDirectionVec3f(const egwVector4f* vec_in);


// !!!: ***** Dot Product *****

/// 2-D Vector Dot Product Routine.
/// Calculates vector dot product with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Dot product scalar.
EGWsingle egwVecDotProd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Dot Product Routine.
/// Calculates vector dot product with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Dot product scalar.
EGWsingle egwVecDotProd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed 2-D Vector Dot Product Routine.
/// Calculates array of vector dot products with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] dtps_out Array of scalar outputs of dot products.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDotProd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dtps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Dot Product Routine.
/// Calculates array of vector dot products with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] dtps_out Array of scalar outputs of dot products.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDotProd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dtps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Cross Product *****

/// 2-D Vector Cross Product Routine.
/// Calculates vector cross product with provided parameters.
/// @note This operation projects R2 into R3.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Cross product scalar.
EGWsingle egwVecCrossProd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Cross Product Routine.
/// Calculates vector cross product with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of cross product.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecCrossProd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Cross Product Routine.
/// Calculates array of vector cross products with provided parameters.
/// @note This operation projects R2 into R3.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] crps_out Array of scalar outputs of cross products.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecCrossProd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* crps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Cross Product Routine.
/// Calculates array of vector cross products with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of cross products.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecCrossProd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Angle Between *****

/// Angle Between 2-D Vectors Routine.
/// Calculates angle between vectors with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Angle between scalar (radians).
EGWsingle egwVecAngleBtwn2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// Angle Between 3-D Vectors Routine.
/// Calculates angle between vectors with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Angle between scalar (radians).
EGWsingle egwVecAngleBtwn3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed Angle Between 2-D Vectors Routine.
/// Calculates angles between array of vectors with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] angles_out Array of scalar outputs of angle betweens.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecAngleBtwn2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Angle Between 3-D Vectors Routine.
/// Calculates angles between array of vectors with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] angles_out Array of scalar outputs of angle betweens.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecAngleBtwn3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Fast Angle Between *****

/// Fast Angle Between 2-D Vectors Routine.
/// Calculates fast angle between vectors via fast inverse square root and fast arc cosine with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Fast angle between scalar (radians).
EGWsingle egwVecFastAngleBtwn2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// Fast Angle Between 3-D Vectors Routine.
/// Calculates fast angle between vectors via fast inverse square root and fast arc cosine with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Fast angle between scalar (radians).
EGWsingle egwVecFastAngleBtwn3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed Fast Angle Between 2-D Vectors Routine.
/// Calculates fast angles between array of vectors via fast inverse square roots and fast arc cosines with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] angles_out Array of scalar outputs of fast angle betweens.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastAngleBtwn2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Fast Angle Between 3-D Vectors Routine.
/// Calculates fast angles between array of vectors via fast inverse square roots and fast arc cosines with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] angles_out Array of scalar outputs of fast angle betweens.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastAngleBtwn3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Magnitude *****

/// 2-D Vector Magnitude Routine.
/// Calculates vector magnitude with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @return Magnitude scalar.
EGWsingle egwVecMagnitude2f(const egwVector2f* vec_in);

/// 3-D Vector Magnitude Routine.
/// Calculates vector magnitude with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @return Magnitude scalar.
EGWsingle egwVecMagnitude3f(const egwVector3f* vec_in);

/// Arrayed 2-D Vector Magnitude Routine.
/// Calculates array of vector magnitudes with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of magnitudes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMagnitude2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, const EGWuint count);

/// Arrayed 3-D Vector Magnitude Routine.
/// Calculates array of vector magnitudes with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of magnitudes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMagnitude3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Magnitude Squared *****

/// 2-D Vector Magnitude Squared Routine.
/// Calculates vector magnitude squared with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @return Magnitude squared scalar.
EGWsingle egwVecMagnitudeSqrd2f(const egwVector2f* vec_in);

/// 3-D Vector Magnitude Squared Routine.
/// Calculates vector magnitude squared with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @return Magnitude squared scalar.
EGWsingle egwVecMagnitudeSqrd3f(const egwVector3f* vec_in);

/// Arrayed 2-D Vector Magnitude Squared Routine.
/// Calculates array of vector magnitudes squared with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of magnitudes squared.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMagnitudeSqrd2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Magnitude Squared Routine.
/// Calculates array of vector magnitudes squared with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of magnitudes squared.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMagnitudeSqrd3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Fast Magnitude *****

/// 2-D Vector Fast Magnitude Routine.
/// Calculates fast vector magnitude via fast inverse square root with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @return Fast magnitude scalar.
EGWsingle egwVecFastMagnitude2f(const egwVector2f* vec_in);

/// 3-D Vector Magnitude Routine.
/// Calculates fast vector magnitude via fast inverse square root with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @return Fast magnitude scalar.
EGWsingle egwVecFastMagnitude3f(const egwVector3f* vec_in);

/// Arrayed 2-D Vector Magnitude Routine.
/// Calculates array of fast vector magnitudes via fast inverse square roots with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of fast magnitudes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastMagnitude2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, const EGWuint count);

/// Arrayed 3-D Vector Magnitude Routine.
/// Calculates array of fast vector magnitudes via fast inverse square roots with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] mags_out Array of scalar outputs of fast magnitudes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastMagnitude3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Normalization *****

/// 2-D Vector Normalization Routine.
/// Performs vector normalization with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @param [out] vec_out 2-D vector output of normalization.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecNormalize2f(const egwVector2f* vec_in, egwVector2f* vec_out);

/// 3-D Vector Normalization Routine.
/// Performs vector normalization with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @param [out] vec_out 3-D vector output of normalization.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecNormalize3f(const egwVector3f* vec_in, egwVector3f* vec_out);

/// Arrayed 2-D Vector Normalization Routine.
/// Performs array of vector normalizations with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNormalize2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Normalization Routine.
/// Performs array of vector normalizations with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNormalize3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Normalization with Magnitude *****

/// 2-D Vector Normalization with Magnitude Routine.
/// Performs vector normalization with magnitude and provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] mag_rhs 2-D vector magnitude rhs operand.
/// @param [out] vec_out 2-D vector output of normalization.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecNormalizeMag2f(const egwVector2f* vec_lhs, const EGWsingle mag_rhs, egwVector2f* vec_out);

/// 3-D Vector Normalization with Magnitude Routine.
/// Performs vector normalization with magnitude and provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] mag_rhs 3-D vector magnitude rhs operand.
/// @param [out] vec_out 3-D vector output of normalization.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecNormalizeMag3f(const egwVector3f* vec_lhs, const EGWsingle mag_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Normalization with Magnitude Routine.
/// Performs array of vector normalizations with magnitudes and provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] mags_rhs Array of 2-D vectors magnitude rhs operands.
/// @param [out] vecs_out Array of 2-D vector outputs of normalizations.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNormalizeMag2fv(const egwVector2f* vecs_lhs, const EGWsingle* mags_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 2-D Vector Normalization with Magnitude Routine.
/// Performs array of vector normalizations with magnitudes and provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] mags_rhs Array of 3-D vectors magnitude rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of normalizations.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNormalizeMag3fv(const egwVector3f* vecs_lhs, const EGWsingle* mags_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Fast Normalization *****

/// 2-D Vector Fast Normalization Routine.
/// Performs fast vector normalization via fast inverse square root with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @param [out] vec_out 2-D vector output of fast normalization.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecFastNormalize2f(const egwVector2f* vec_in, egwVector2f* vec_out);

/// 3-D Vector Fast Normalization Routine.
/// Performs fast vector normalization via fast inverse square root with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @param [out] vec_out 3-D vector output of fast normalization.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecFastNormalize3f(const egwVector3f* vec_in, egwVector3f* vec_out);

/// Arrayed 2-D Vector Fast Normalization Routine.
/// Performs array of fast vector normalizations via fast inverse square roots with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of fast normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastNormalize2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Fast Normalization Routine.
/// Performs array of fast vector normalizations via fast inverse square roots with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of fast normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastNormalize3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Distance *****

/// 2-D Vector Distance Routine.
/// Calculates linear distance between vectors with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Distance scalar.
EGWsingle egwVecDistance2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Distance Routine.
/// Calculates linear distance between vectors with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Distance scalar.
EGWsingle egwVecDistance3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed 2-D Vector Distance Routine.
/// Calculates array of linear distances between vectors with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of distances.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDistance2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Distance Routine.
/// Calculates array of linear distances between vectors with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of distances.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDistance3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Distance Squared *****

/// 2-D Vector Distance Squared Routine.
/// Calculates squared linear distance between vectors with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Distance squared scalar.
EGWsingle egwVecDistanceSqrd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Distance Squared Routine.
/// Calculates squared linear distance between vectors with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Distance squared scalar.
EGWsingle egwVecDistanceSqrd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// 3-D Vector XZ Plane Distance Squared Routine.
/// Calculates squared linear distance between vectors, on XZ plane only, with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Distance squared scalar on XZ plane.
EGWsingle egwVecDistanceSqrdXZ3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed 2-D Vector Distance Squared Routine.
/// Calculates array of squared linear distances between vectors with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of distances squared.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDistanceSqrd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Distance Squared Routine.
/// Calculates array of squared linear distances between vectors with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of distances squared.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDistanceSqrd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector XZ Plane Distance Squared Routine.
/// Calculates array of squared linear distances between vectors, on XZ plane only, with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of distances squared on XZ plane.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecDistanceSqrdXZ3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Fast Distance *****

/// 2-D Vector Fast Distance Routine.
/// Calculates fast linear distance between vectors via fast inverse square root with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @return Fast distance scalar.
EGWsingle egwVecFastDistance2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs);

/// 3-D Vector Fast Distance Routine.
/// Calculates fast linear distance between vectors via fast inverse square root with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @return Fast distance scalar.
EGWsingle egwVecFastDistance3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs);

/// Arrayed 2-D Vector Fast Distance Routine.
/// Calculates array of fast linear distances between vectors via fast inverse square roots with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of fast distances.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastDistance2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Fast Distance Routine.
/// Calculates array of fast linear distances between vectors via fast inverse square roots with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] dsts_out Array of scalar outputs of fast distances.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecFastDistance3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Negation *****

/// 2-D Vector Negation Routine.
/// Calculates pair-wise vector negation (-v) with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @param [out] vec_out 2-D vector output of negation.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecNegate2f(const egwVector2f* vec_in, egwVector2f* vec_out);

/// 3-D Vector Negation Routine.
/// Calculates pair-wise vector negation (-v) with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @param [out] vec_out 3-D vector output of negation.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecNegate3f(const egwVector3f* vec_in, egwVector3f* vec_out);

/// Arrayed 2-D Vector Negation Routine.
/// Calculates array of pair-wise vector negations (-v) with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of negations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNegate2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Negation Routine.
/// Calculates array of pair-wise vector negations (-v) with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of negations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecNegate3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Inversion *****

/// 2-D Vector Inversion Routine.
/// Calculates pair-wise vector inversion (v^-1) with provided parameters.
/// @param [in] vec_in 2-D vector input operand.
/// @param [out] vec_out 2-D vector output of inversion.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecInvert2f(const egwVector2f* vec_in, egwVector2f* vec_out);

/// 3-D Vector Inversion Routine.
/// Calculates pair-wise vector inversion (v^-1) with provided parameters.
/// @param [in] vec_in 3-D vector input operand.
/// @param [out] vec_out 3-D vector output of inversion.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecInvert3f(const egwVector3f* vec_in, egwVector3f* vec_out);

/// Arrayed 2-D Vector Inversion Routine.
/// Calculates array of pair-wise vector inversions (v^-1) with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecInvert2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Inversion Routine.
/// Calculates array of pair-wise vector inversions (v^-1) with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecInvert3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Addition *****

/// 2-D Vector Addition Routine.
/// Calculates pair-wise vector addition with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @param [out] vec_out 2-D vector output of addition.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecAdd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out);

/// 3-D Vector Addition Routine.
/// Calculates pair-wise vector addition with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of addition.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecAdd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Addition Routine.
/// Calculates array of pair-wise vector additions with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] vecs_out Array of 2-D vector outputs of additions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecAdd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Addition Routine.
/// Calculates array of pair-wise vector additions with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of additions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecAdd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Subtraction *****

/// 2-D Vector Subtraction Routine.
/// Calculates pair-wise vector subtraction with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @param [out] vec_out 2-D vector output of subtration.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecSubtract2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out);

/// 3-D Vector Subtraction Routine.
/// Calculates pair-wise vector subtraction with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of subtration.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecSubtract3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Subtration Routine.
/// Calculates array of pair-wise vector subtractions with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] vecs_out Array of 2-D vector outputs of subtractions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecSubtract2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Subtration Routine.
/// Calculates array of pair-wise vector subtractions with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of subtractions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecSubtract3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Multiplication *****

/// 2-D Vector Multiplication Routine.
/// Calculates pair-wise vector multiplication with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @param [out] vec_out 2-D vector output of multiplication.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecMultiply2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out);

/// 3-D Vector Multiplication Routine.
/// Calculates pair-wise vector multiplication with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of multiplication.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecMultiply3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Multiplication Routine.
/// Calculates array of pair-wise vector multiplications with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [out] vecs_out Array of 2-D vector outputs of multiplications.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMultiply2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Multiplication Routine.
/// Calculates array of pair-wise vector multiplications with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of multiplications.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecMultiply3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Universal Scaling *****

/// 2-D Vector Universal Scaling Routine.
/// Calculates universal vector scaling with provided parameters.
/// @param [in] vec_lhs 2-D vector lhs operand.
/// @param [in] scale_rhs Universal scaling rhs operand.
/// @param [out] vec_out 2-D vector output of scaling.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecUScale2f(const egwVector2f* vec_lhs, const EGWsingle scale_rhs, egwVector2f* vec_out);

/// 3-D Vector Universal Scaling Routine.
/// Calculates universal vector scaling with provided parameters.
/// @param [in] vec_lhs 3-D vector lhs operand.
/// @param [in] scale_rhs Universal scaling rhs operand.
/// @param [out] vec_out 3-D vector output of scaling.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecUScale3f(const egwVector3f* vec_lhs, const EGWsingle scale_rhs, egwVector3f* vec_out);

/// Arrayed 2-D Vector Universal Scaling Routine.
/// Calculates array of universal vector scalings with provided parameters.
/// @param [in] vecs_lhs Array of 2-D vector lhs operands.
/// @param [in] scales_rhs Array of universal scaling rhs operands.
/// @param [out] vecs_out Array of 2-D vector outputs of scalings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecUScale2fv(const egwVector2f* vecs_lhs, const EGWsingle* scales_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3-D Vector Universal Scaling Routine.
/// Calculates array of universal vector scalings with provided parameters.
/// @param [in] vecs_lhs Array of 3-D vector lhs operands.
/// @param [in] scales_rhs Array of universal scaling rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of scalings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecUScale3fv(const egwVector3f* vecs_lhs, const EGWsingle* scales_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Summation *****

/// Arrayed 2-D Summation Routine.
/// Performs array of vector summations with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] vec_out 2-D vector output of summation.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecSummation2fv(const egwVector2f* vecs_in, egwVector2f* vec_out, const EGWintptr strideB_in, EGWuint count);

/// Arrayed 3-D Summation Routine.
/// Performs array of vector summations with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] vec_out 3-D vector output of summation.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecSummation3fv(const egwVector3f* vecs_in, egwVector3f* vec_out, const EGWintptr strideB_in, EGWuint count);


// !!!: ***** Find Extents *****

/// Arrayed 2-D Find Axis Extents Routine.
/// Performs array of vector axis extents finding with provided parameters.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] min_out 2-D vector output of minimum axis value extents.
/// @param [out] max_out 2-D vector output of maximum axis value extents.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
void egwVecFindExtentsAxs2fv(const egwVector2f* vecs_in, egwVector2f* min_out, egwVector2f* max_out, const EGWintptr strideB_in, EGWuint count);

/// Arrayed 3-D Find Axis Extents Routine.
/// Performs array of vector axis extents finding with provided parameters.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] min_out 3-D vector output of minimum axis value extents.
/// @param [out] max_out 3-D vector output of maximum axis value extents.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
void egwVecFindExtentsAxs3fv(const egwVector3f* vecs_in, egwVector3f* min_out, egwVector3f* max_out, const EGWintptr strideB_in, EGWuint count);

/// Arrayed 2-D Find Vector Extents Routine.
/// Performs array of vector vector extents finding with provided parameters.
/// @note The outputs of this method are pointers in order to be the most flexible to various situations.
/// @param [in] vecs_in Array of 2-D vector input operands.
/// @param [out] minX_out 2-D vector output of minimum X-axis value extent.
/// @param [out] maxX_out 2-D vector output of maximum X-axis value extent.
/// @param [out] minY_out 2-D vector output of minimum Y-axis value extent.
/// @param [out] maxY_out 2-D vector output of maximum Y-axis value extent.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
void egwVecFindExtentsVct2fv(const egwVector2f* vecs_in, egwVector2f** minX_out, egwVector2f** maxX_out, egwVector2f** minY_out, egwVector2f** maxY_out, const EGWintptr strideB_in, EGWuint count);

/// Arrayed 3-D Find Vector Extents Routine.
/// Performs array of vector vector extents finding with provided parameters.
/// @note The outputs of this method are pointers in order to be the most flexible to various situations.
/// @param [in] vecs_in Array of 3-D vector input operands.
/// @param [out] minX_out 3-D vector output of minimum X-axis value extent.
/// @param [out] maxX_out 3-D vector output of maximum X-axis value extent.
/// @param [out] minY_out 3-D vector output of minimum Y-axis value extent.
/// @param [out] maxY_out 3-D vector output of maximum Y-axis value extent.
/// @param [out] minZ_out 3-D vector output of minimum Z-axis value extent.
/// @param [out] maxZ_out 3-D vector output of maximum Z-axis value extent.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] count Array element count.
void egwVecFindExtentsVct3fv(const egwVector3f* vecs_in, const egwVector3f** const minX_out, const egwVector3f** const maxX_out, const egwVector3f** const minY_out, const egwVector3f** const maxY_out, const egwVector3f** const minZ_out, const egwVector3f** const maxZ_out, const EGWintptr strideB_in, EGWuint count);

/// @}

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

/// @defgroup geWizES_math_quaternion egwQuaternion
/// @ingroup geWizES_math
/// Quaternion.
/// @{

/// @file egwQuaternion.h
/// Quaternion Interface.

#import "egwMathTypes.h"


// !!!: ***** Shared Instances *****

extern const egwQuaternion4f egwSIQuatIdentity4f; ///< Shared 4-D identity quaternion instance.
extern const egwQuaternion4f egwSIQuatZero4f;     ///< Shared 4-D zero quaternion instance.


// !!!: ***** Initialization *****

/// 4-D Quaternion Initialization Routine.
/// Initializes quaternion with provided parameters.
/// @param [out] quat_out 4-D quaternion output of initialization.
/// @param [in] w W-coordinate value.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatInit4f(egwQuaternion4f* quat_out, const EGWsingle w, const EGWsingle x, const EGWsingle y, const EGWsingle z);

/// Arrayed 4-D Quaternion Initialization Routine.
/// Initializes array of quaternions with provided parameters.
/// @param [out] quats_out Array of 4-D quaternion outputs of initializations.
/// @param [in] w W-coordinate value.
/// @param [in] x X-coordinate value.
/// @param [in] y Y-coordinate value.
/// @param [in] z Z-coordinate value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatInit4fv(egwQuaternion4f* quats_out, const EGWsingle w, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWintptr strideB_out, EGWuint count);

/// 4-D Quaternion Copy Routine.
/// Initializes quaternion from deep copy of another.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of copy.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatCopy4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Copy Routine.
/// Initializes array of quaternions from copies of another.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatCopy4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Testing *****

/// 4-D Quaternion Equality Testing Routine.
/// Determines if two provided quaternion rotations are equivalent.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] quat_rhs 4-D quaternion rhs operand.
/// @return 1 if @a quat_lhs is rotational equal to @a quat_rhs, otherwise 0.
EGWint egwQuatIsEqual4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs);


// !!!: ***** Tensor (aka Norm, Dot Product) *****

/// 4-D Quaternion Tensor Routine.
/// Calculates quaternion tensor with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @return Tensor scalar.
EGWsingle egwQuatTensor4f(const egwQuaternion4f* quat_in);

/// Arrayed 4-D Quaternion Tensor Routine.
/// Calculates array of quaternion tensors with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] tsrs_out Array of scalar outputs of tensors.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatTensor4fv(const egwQuaternion4f* quats_in, EGWsingle* tsrs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Normalization *****

/// 4-D Quaternion Normalization Routine.
/// Performs quaternion normalization with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of normalization.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatNormalize4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Normalization Routine.
/// Performs array of quaternion normalizations with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatNormalize4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Fast Normalization *****

/// 4-D Quaternion Fast Normalization Routine.
/// Performs fast quaternion normalization via fast inverse square root with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of fast normalization.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatFastNormalize4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Fast Normalization Routine.
/// Performs array of fast quaternion normalizations via fast inverse square roots with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of fast normalizations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatFastNormalize4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Conjugation *****

/// 4-D Quaternion Conjugation Routine.
/// Calculates quaternion conjugation with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of conjugation.
/// @return @a vec_out (for nesting).
egwQuaternion4f* egwQuatConjugate4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Conjugation Routine.
/// Calculates array of quaternion conjugations with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of conjugations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatConjugate4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Negation *****

/// 4-D Quaternion Negation Routine.
/// Calculates pair-wise quaternion negation with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of negation.
/// @return @a vec_out (for nesting).
egwQuaternion4f* egwQuatNegate4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Negation Routine.
/// Calculates array of pair-wise quaternion negations with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of negations.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatNegate4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Inversion *****

/// 4-D Quaternion Inversion Routine.
/// Calculates quaternion inversion with provided parameters.
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] quat_out 4-D quaternion output of inversion.
/// @return @a vec_out (for nesting).
egwQuaternion4f* egwQuatInvert4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Inversion Routine.
/// Calculates array of quaternion inversions with provided parameters.
/// @param [in] quats_in Array of 4-D quaternion input operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatInvert4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Addition *****

/// 4-D Quaternion Addition Routine.
/// Calculates pair-wise quaternion addition with provided parameters.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] quat_rhs 4-D quaternion rhs operand.
/// @param [out] quat_out 4-D quaternion output of addition.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatAdd4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Addition Routine.
/// Calculates array of pair-wise quaternion additions with provided parameters.
/// @param [in] quats_lhs Array of 4-D quaternion lhs operands.
/// @param [in] quats_rhs Array of 4-D quaternion rhs operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of additions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatAdd4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Subtraction *****

/// 4-D Quaternion Subtraction Routine.
/// Calculates pair-wise quaternion subtraction with provided parameters.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] quat_rhs 4-D quaternion rhs operand.
/// @param [out] quat_out 4-D quaternion output of subtration.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatSubtract4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out);

/// Arrayed 4-D Quaternion Subtration Routine.
/// Calculates array of pair-wise quaternion subtractions with provided parameters.
/// @param [in] quats_lhs Array of 4-D quaternion lhs operands.
/// @param [in] quats_rhs Array of 4-D quaternion rhs operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of subtractions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatSubtract4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Multiplication *****

/// 4-D Quaternion Multiplication Routine.
/// Calculates quaternion multiply with provided parameters.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] quat_rhs 4-D quaternion rhs operand.
/// @param [out] quat_out 4-D quaternion output of multiply.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatMultiply4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out);

/// 4-D Quaternion Multiplication Routine.
/// Calculates array of quaternion multiplies with provided parameters.
/// @param [in] quats_lhs Array of 4-D quaternion lhs operands.
/// @param [in] quats_rhs Array of 4-D quaternion rhs operands.
/// @param [out] quats_out Array of 4-D quaternion outputs of multiplies.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwQuatMultiply4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Rotate *****

/// 4-D Quaternion Euler Rotation Routine.
/// Applies an Euler rotation about the LCS origin axes with the provided parameters.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] angles_r LCS axes angles of rotation (radians) about respective axis.
/// @param [in] order Rotation axes ordering setting (EGW_EULERROT_ORDER_*).
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateEuler4f(const egwQuaternion4f* quat_in, const egwVector3f* angles_r, const EGWint order, egwQuaternion4f* quat_out);

/// 4-D Quaternion Euler Rotation Routine.
/// Applies an Euler rotation about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] angleX_r Angle of rotation (radians) about LCS X-axis.
/// @param [in] angleY_r Angle of rotation (radians) about LCS Y-axis.
/// @param [in] angleZ_r Angle of rotation (radians) about LCS Z-axis.
/// @param [in] order Rotation axes ordering setting (EGW_EULERROT_ORDER_*).
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateEuler4fs(const egwQuaternion4f* quat_in, const EGWsingle angleX_r, const EGWsingle angleY_r, const EGWsingle angleZ_r, const EGWint order, egwQuaternion4f* quat_out);

/// 4-D Quaternion Axis-Angle Rotation Routine.
/// Applies an axis rotation (with magnitude as angle (radians)) about the provided LCS origin axis with the provided parameters.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] axis LCS axis of rotation.
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateAxis4f(const egwQuaternion4f* quat_in, const egwVector3f* axis, egwQuaternion4f* quat_out);

/// 4-D Quaternion Axis-Angle Rotation Routine.
/// Applies an axis rotation (with magnitude as angle (radians)) about the provided LCS origin axis with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] axisX LCS axis of rotation X-coordinate.
/// @param [in] axisY LCS axis of rotation Y-coordinate.
/// @param [in] axisZ LCS axis of rotation Z-coordinate.
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateAxis4fs(const egwQuaternion4f* quat_in, const EGWsingle axisX, const EGWsingle axisY, const EGWsingle axisZ, egwQuaternion4f* quat_out);

/// 4-D Quaternion Axis-Angle Rotation Routine.
/// Applies an axis-angle rotation about the provided LCS origin axis with the provided parameters.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] axis_u LCS unit-axis of rotation.
/// @param [in] angle_r Angle of rotation (radians).
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateAxisAngle4f(const egwQuaternion4f* quat_in, const egwVector3f* axis_u, EGWsingle angle_r, egwQuaternion4f* quat_out);

/// 4-D Quaternion Axis-Angle Rotation Routine.
/// Applies an axis-angle rotation about the provided LCS origin axis with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] axisX_u LCS unit-axis of rotation X-coordinate.
/// @param [in] axisY_u LCS unit-axis of rotation Y-coordinate.
/// @param [in] axisZ_u LCS unit-axis of rotation Z-coordinate.
/// @param [in] angle_r Angle of rotation (radians).
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateAxisAngle4fs(const egwQuaternion4f* quat_in, const EGWsingle axisX_u, const EGWsingle axisY_u, const EGWsingle axisZ_u, const EGWsingle angle_r, egwQuaternion4f* quat_out);

/// 4-D Quaternion Vector-Vector Rotation Routine.
/// Applies an axis-angle rotation about the calculated LCS origin axis from the provided parameters (calculated cross product and magnitude).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] vec_fr 3-D vector from operand.
/// @param [in] vec_to 3-D vector to operand.
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateVecVec4f(const egwQuaternion4f* quat_in, const egwVector3f* vec_fr, const egwVector3f* vec_to, egwQuaternion4f* quat_out);

/// 4-D Quaternion Vector-Vector Rotation Routine.
/// Applies an axis-angle rotation about the calculated LCS origin axis from the provided parameters (calculated cross product and magnitude).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] vecX_fr 3-D vector X-coordinate from operand.
/// @param [in] vecY_fr 3-D vector Y-coordinate from operand.
/// @param [in] vecZ_fr 3-D vector Z-coordinate from operand.
/// @param [in] vecX_to 3-D vector X-coordinate to operand.
/// @param [in] vecY_to 3-D vector Y-coordinate to operand.
/// @param [in] vecZ_to 3-D vector Z-coordinate to operand.
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateVecVec4fs(const egwQuaternion4f* quat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecZ_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, const EGWsingle vecZ_to, egwQuaternion4f* quat_out);

/// 4-D Quaternion Matrix Rotation Routine.
/// Applies a matrix rotation from the provided parameters.
/// @param [in] quat_in 4-D quaternion input operand. May be NULL (for identity).
/// @param [in] mat_in 4x4 matrix input operand.
/// @param [out] quat_out 4-D quaternion output of rotation of input operand.
/// @return @a quat_out (for nesting).
egwQuaternion4f* egwQuatRotateMatrix444f(const egwQuaternion4f* quat_in, const egwMatrix44f* mat_in, egwQuaternion4f* quat_out);


// !!!: ***** Vector Homomorphism *****

/// 4-D Quaternion 3-D Vector Homomorphism Routine.
/// Calculates vector homomorphism with the provided parameters.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of homomorphism.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecHomomorphize43f(const egwQuaternion4f* quat_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// 4-D Quaternion 4-D Vector Homomorphism Routine.
/// Calculates vector homomorphism with the provided parameters.
/// @param [in] quat_lhs 4-D quaternion lhs operand.
/// @param [in] vec_rhs 4-D vector rhs operand.
/// @param [out] vec_out 4-D vector output of homomorphism.
/// @return @a vec_out (for nesting).
egwVector4f* egwVecHomomorphize44f(const egwQuaternion4f* quat_lhs, const egwVector4f* vec_rhs, egwVector4f* vec_out);

/// Arrayed 4-D Quaternion 3-D Vector Homomorphism Routine.
/// Calculates array of vector homomorphisms with the provided parameters.
/// @param [in] quats_lhs Array of 4-D quaternion lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of homomorphisms.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecHomomorphize43fz(const egwQuaternion4f* quats_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4-D Quaternion 4-D Vector Homomorphism Routine.
/// Calculates array of vector homomorphisms with the provided parameters.
/// @param [in] quats_lhs Array of 4-D quaternion lhs operands.
/// @param [in] vecs_rhs Array of 4-D vector rhs operands.
/// @param [out] vecs_out Array of 4-D vector outputs of homomorphisms.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecHomomorphize44fz(const egwQuaternion4f* quats_lhs, const egwVector4f* vecs_rhs, egwVector4f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// @}

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

/// @defgroup geWizES_math_matrix egwMatrix
/// @ingroup geWizES_math
/// Matrix.
/// @{

/// @file egwMatrix.h
/// Matrix Interface.

#import "egwMathTypes.h"


// !!!: ***** Defines *****

#define EGW_MATRIX_SHEAR_TYPE_XBYY  0x0120  ///< Shearing type: X by Y.
#define EGW_MATRIX_SHEAR_TYPE_XBYZ  0x0102  ///< Shearing type: X by Z (4x4 only).
#define EGW_MATRIX_SHEAR_TYPE_YBYX  0x0210  ///< Shearing type: Y by X.
#define EGW_MATRIX_SHEAR_TYPE_YBYZ  0x0012  ///< Shearing type: Y by Z (4x4 only).
#define EGW_MATRIX_SHEAR_TYPE_ZBYX  0x0201  ///< Shearing type: Z by X (4x4 only).
#define EGW_MATRIX_SHEAR_TYPE_ZBYY  0x0021  ///< Shearing type: Z by Y (4x4 only).


// !!!: ***** Shared Instances *****

extern const egwMatrix33f egwSIMatIdentity33f;    ///< Shared 3x3 identity matrix instance.
extern const egwMatrix33f egwSIMatZero33f;        ///< Shared 3x3 zero matrix instance.

extern const egwMatrix44f egwSIMatIdentity44f;    ///< Shared 4x4 identity matrix instance.
extern const egwMatrix44f egwSIMatZero44f;        ///< Shared 4x4 zero matrix instance.


// !!!: ***** Initialization *****

/// 3x3 Matrix Initialization Routine.
/// Initializes matrix with provided parameters.
/// @note Values are entered in row-major for code clarity only.
/// @param [out] mat_out 3x3 matrix output of initialization.
/// @param [in] r1c1 Row 1 column 1 value.
/// @param [in] r1c2 Row 1 column 2 value.
/// @param [in] r1c3 Row 1 column 3 value.
/// @param [in] r2c1 Row 2 column 1 value.
/// @param [in] r2c2 Row 2 column 2 value.
/// @param [in] r2c3 Row 2 column 3 value.
/// @param [in] r3c1 Row 3 column 1 value.
/// @param [in] r3c2 Row 3 column 2 value.
/// @param [in] r3c3 Row 3 column 3 value.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatInit33f(egwMatrix33f* mat_out,
                            const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3,
                            const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3,
                            const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3);

/// 4x4 Matrix Initialization Routine.
/// Initializes matrix with provided parameters.
/// @note Values are entered in row-major for code clarity only.
/// @param [out] mat_out 4x4 matrix output of initialization.
/// @param [in] r1c1 Row 1 column 1 value.
/// @param [in] r1c2 Row 1 column 2 value.
/// @param [in] r1c3 Row 1 column 3 value.
/// @param [in] r1c4 Row 1 column 4 value.
/// @param [in] r2c1 Row 2 column 1 value.
/// @param [in] r2c2 Row 2 column 2 value.
/// @param [in] r2c3 Row 2 column 3 value.
/// @param [in] r2c4 Row 2 column 4 value.
/// @param [in] r3c1 Row 3 column 1 value.
/// @param [in] r3c2 Row 3 column 2 value.
/// @param [in] r3c3 Row 3 column 3 value.
/// @param [in] r3c4 Row 3 column 4 value.
/// @param [in] r4c1 Row 4 column 1 value.
/// @param [in] r4c2 Row 4 column 2 value.
/// @param [in] r4c3 Row 4 column 3 value.
/// @param [in] r4c4 Row 4 column 4 value.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatInit44f(egwMatrix44f* mat_out,
                            const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3, const EGWsingle r1c4,
                            const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3, const EGWsingle r2c4,
                            const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3, const EGWsingle r3c4,
                            const EGWsingle r4c1, const EGWsingle r4c2, const EGWsingle r4c3, const EGWsingle r4c4);

/// Arrayed 3x3 Matrix Initialization Routine.
/// Initializes array of matricies with provided parameters.
/// @note Values are entered in row-major for code clarity only.
/// @param [out] mats_out Array of 3x3 matrix outputs of initializations.
/// @param [in] r1c1 Row 1 column 1 value.
/// @param [in] r1c2 Row 1 column 2 value.
/// @param [in] r1c3 Row 1 column 3 value.
/// @param [in] r2c1 Row 2 column 1 value.
/// @param [in] r2c2 Row 2 column 2 value.
/// @param [in] r2c3 Row 2 column 3 value.
/// @param [in] r3c1 Row 3 column 1 value.
/// @param [in] r3c2 Row 3 column 2 value.
/// @param [in] r3c3 Row 3 column 3 value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInit33fv(egwMatrix33f* mats_out,
                     const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3,
                     const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3,
                     const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3,
                     const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Initialization Routine.
/// Initializes array of matricies with provided parameters.
/// @note Values are entered in row-major for code clarity only.
/// @param [out] mats_out Array of 4x4 matrix outputs of initializations.
/// @param [in] r1c1 Row 1 column 1 value.
/// @param [in] r1c2 Row 1 column 2 value.
/// @param [in] r1c3 Row 1 column 3 value.
/// @param [in] r1c4 Row 1 column 4 value.
/// @param [in] r2c1 Row 2 column 1 value.
/// @param [in] r2c2 Row 2 column 2 value.
/// @param [in] r2c3 Row 2 column 3 value.
/// @param [in] r2c4 Row 2 column 4 value.
/// @param [in] r3c1 Row 3 column 1 value.
/// @param [in] r3c2 Row 3 column 2 value.
/// @param [in] r3c3 Row 3 column 3 value.
/// @param [in] r3c4 Row 3 column 4 value.
/// @param [in] r4c1 Row 4 column 1 value.
/// @param [in] r4c2 Row 4 column 2 value.
/// @param [in] r4c3 Row 4 column 3 value.
/// @param [in] r4c4 Row 4 column 4 value.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInit44fv(egwMatrix44f* mats_out,
                     const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3, const EGWsingle r1c4,
                     const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3, const EGWsingle r2c4,
                     const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3, const EGWsingle r3c4,
                     const EGWsingle r4c1, const EGWsingle r4c2, const EGWsingle r4c3, const EGWsingle r4c4,
                     const EGWintptr strideB_out, EGWuint count);

/// 3x3 Matrix Copy Routine.
/// Initializes matrix from deep copy of another.
/// @param [in] mat_in 3x3 matrix input operand.
/// @param [out] mat_out 3x3 matrix output of copy.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatCopy33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out);

/// 4x4 Matrix Copy Routine.
/// Initializes matrix from deep copy of another.
/// @param [in] mat_in 4x4 matrix input operand.
/// @param [out] mat_out 4x4 matrix output of copy.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatCopy44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Copy Routine.
/// Initializes array of matricies from copies of another.
/// @param [in] mats_in Array of 3x3 matrix input operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatCopy33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Copy Routine.
/// Initializes array of matricies from copies of another.
/// @param [in] mats_in Array of 4x4 matrix input operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of copies.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatCopy44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Testing *****

/// 3x3 Matrix Equality Testing Routine.
/// Determines if two provided matricies are equivalent.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] mat_rhs 3x3 matrix rhs operand.
/// @return 1 if @a mat_lhs is pair-wise equal to @a mat_rhs, otherwise 0.
EGWint egwMatIsEqual33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs);

/// 4x4 Matrix Equality Testing Routine.
/// Determines if two provided matricies are equivalent.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] mat_rhs 4x4 matrix rhs operand.
/// @return 1 if @a mat_lhs is pair-wise equal to @a mat_rhs, otherwise 0.
EGWint egwMatIsEqual44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs);

/// 3x3 Matrix Homogeneality Testing Routine.
/// Determines if provided matrix is homogeneous (i.e. last row <0,0,1>).
/// @param [in] mat_in 3x3 matrix input operand.
/// @return 1 if @a mat_in is homogeneous, otherwise 0.
EGWint egwMatIsHomogeneous33f(const egwMatrix33f* mat_in);

/// 4x4 Matrix Homogeneality Testing Routine.
/// Determines if provided matrix is homogeneous (i.e. last row <0,0,0,1>).
/// @param [in] mat_in 4x4 matrix input operand.
/// @return 1 if @a mat_in is homogeneous, otherwise 0.
EGWint egwMatIsHomogeneous44f(const egwMatrix44f* mat_in);

/// 3x3 Matrix Orthogonality Testing Routine.
/// Determines if provided matrix is orthogonal (i.e. determinant is +/- 1).
/// @note This routine calculates matrix determinant then discards - use with caution.
/// @param [in] mat_in 3x3 matrix input operand.
/// @return 1 if @a mat_in is orthogonal, otherwise 0.
EGWint egwMatIsOrthogonal33f(const egwMatrix33f* mat_in);

/// 4x4 Matrix Orthogonality Testing Routine.
/// Determines if provided matrix is orthogonal (i.e. determinant is +/- 1).
/// @note This routine calculates matrix determinant then discards - use with caution.
/// @param [in] mat_in 4x4 matrix input operand.
/// @return 1 if @a mat_in is orthogonal, otherwise 0.
EGWint egwMatIsOrthogonal44f(const egwMatrix44f* mat_in);


// !!!: ***** Transpose *****

/// 3x3 Matrix Transpose Routine.
/// Performs matrix transpose with provided parameters.
/// @note Performs a full transpose, including translation column.
/// @param [in] mat_in 3x3 matrix input operand.
/// @param [out] mat_out 3x3 matrix output of transpose.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatTranspose33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out);

/// 4x4 Matrix Transpose Routine.
/// Performs matrix transpose with provided parameters.
/// @note Performs a full transpose, including translation column.
/// @param [in] mat_in 4x4 matrix input operand.
/// @param [out] mat_out 4x4 matrix output of transpose.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatTranspose44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Transpose Routine.
/// Performs array of matrix transposes with provided parameters.
/// @note Performs a full transpose, including translation column.
/// @param [in] mats_in Array of 3x3 matrix input operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of transposes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTranspose33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Transpose Routine.
/// Performs array of matrix transposes with provided parameters.
/// @note Performs a full transpose, including translation column.
/// @param [in] mats_in Array of 4x4 matrix input operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of transposes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTranspose44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Transpose of Homogeneous *****

/// 3x3 Homogeneous Matrix Transpose Routine.
/// Performs homogeneous matrix transpose with provided parameters.
/// @note Performs a partial transpose, excluding translation column.
/// @param [in] mat_in 3x3 homogeneous matrix input operand.
/// @param [out] mat_out 3x3 homogeneous matrix output of transpose.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatTransposeHmg33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out);

/// 4x4 Homogeneous Matrix Transpose Routine.
/// Performs homogeneous matrix transpose with provided parameters.
/// @note Performs a partial transpose, excluding translation column.
/// @param [in] mat_in 4x4 homogeneous matrix input operand.
/// @param [out] mat_out 4x4 homogeneous matrix output of transpose.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatTransposeHmg44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out);

/// Arrayed 3x3 Homogeneous Matrix Transpose Routine.
/// Performs array of homogeneous matrix transposes with provided parameters.
/// @note Performs a partial transpose, excluding translation column.
/// @param [in] mats_in Array of 3x3 homogeneous matrix input operands.
/// @param [out] mats_out Array of 3x3 homogeneous matrix outputs of transposes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTransposeHmg33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Homogeneous Matrix Transpose Routine.
/// Performs array of homogeneous matrix transposes with provided parameters.
/// @note Performs a partial transpose, excluding translation column.
/// @param [in] mats_in Array of 4x4 homogeneous matrix input operands.
/// @param [out] mats_out Array of 4x4 homogeneous matrix outputs of transposes.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTransposeHmg44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Determinant *****

/// 3x3 Matrix Determinant Routine.
/// Calculates matrix determinant with provided parameters.
/// @param [in] mat_in 3x3 matrix input operand.
/// @return Determinant scalar.
EGWsingle egwMatDeterminant33f(const egwMatrix33f* mat_in);

/// 4x4 Matrix Determinant Routine.
/// Calculates matrix determinant with provided parameters.
/// @param [in] mat_in 4x4 matrix input operand.
/// @return Determinant scalar.
EGWsingle egwMatDeterminant44f(const egwMatrix44f* mat_in);

/// Arrayed 3x3 Matrix Determinant Routine.
/// Calculates array of matrix determinants with provided parameters.
/// @param [in] mats_in Array of 3x3 matrix input operands.
/// @param [out] dets_out Array of scalar outputs of determinants.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatDeterminant33fv(const egwMatrix33f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Determinant Routine.
/// Calculates array of matrix determinants with provided parameters.
/// @param [in] mats_in Array of 4x4 matrix input operands.
/// @param [out] dets_out Array of scalar outputs of determinants.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatDeterminant44fv(const egwMatrix44f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Determinant of Homogeneous *****

/// 3x3 Homogeneous Matrix Determinant Routine.
/// Calculates homogeneous matrix determinant with provided parameters.
/// @param [in] mat_in 3x3 homogeneous matrix input operand.
/// @return Determinant scalar.
EGWsingle egwMatDeterminantHmg33f(const egwMatrix33f* mat_in);

/// 4x4 Homogeneous Matrix Determinant Routine.
/// Calculates homogeneous matrix determinant with provided parameters.
/// @param [in] mat_in 4x4 homogeneous matrix input operand.
/// @return Determinant scalar.
EGWsingle egwMatDeterminantHmg44f(const egwMatrix44f* mat_in);

/// Arrayed Homogeneous 3x3 Matrix Determinant Routine.
/// Calculates array of homogeneous matrix determinants with provided parameters.
/// @param [in] mats_in Array of 3x3 homogeneous matrix input operands.
/// @param [out] dets_out Array of scalar outputs of determinants.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatDeterminantHmg33fv(const egwMatrix33f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Homogeneous 4x4 Matrix Determinant Routine.
/// Calculates array of homogeneous matrix determinants with provided parameters.
/// @param [in] mats_in Array of 4x4 homogeneous matrix input operands.
/// @param [out] dets_out Array of scalar outputs of determinants.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatDeterminantHmg44fv(const egwMatrix44f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Trace *****

/// 3x3 Matrix Trace Routine.
/// Calculates matrix trace with provided parameters.
/// @param [in] mat_in 3x3 matrix input operand.
/// @return Trace scalar.
EGWsingle egwMatTrace33f(const egwMatrix33f* mat_in);

/// 4x4 Matrix Trace Routine.
/// Calculates matrix trace with provided parameters.
/// @param [in] mat_in 4x4 matrix input operand.
/// @return Trace scalar.
EGWsingle egwMatTrace44f(const egwMatrix44f* mat_in);

/// Arrayed 3x3 Matrix Trace Routine.
/// Calculates array of matrix traces with provided parameters.
/// @param [in] mats_in Array of 3x3 matrix input operands.
/// @param [out] trcs_out Array of scalar outputs of traces.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTrace33fv(const egwMatrix33f* mats_in, EGWsingle* trcs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Trace Routine.
/// Calculates array of matrix traces with provided parameters.
/// @param [in] mats_in Array of 4x4 matrix input operands.
/// @param [out] trcs_out Array of scalar outputs of traces.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatTrace44fv(const egwMatrix44f* mats_in, EGWsingle* trcs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: **** Inversion *****

/// 3x3 Matrix Inversion Routine.
/// Calculates matrix inversion with provided parameters.
/// @param [in] mat_in 3x3 matrix input operand.
/// @param [out] mat_out 3x3 matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatInvert33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out);

/// 4x4 Matrix Inversion Routine.
/// Calculates matrix inversion with provided parameters.
/// @param [in] mat_in 4x4 matrix input operand.
/// @param [out] mat_out 4x4 matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatInvert44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Inversion Routine.
/// Calculates array of matrix inversions with provided parameters.
/// @param [in] mats_in Array of 3x3 matrix input operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvert33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Inversion Routine.
/// Calculates array of matrix inversions with provided parameters.
/// @param [in] mats_in Array of 4x4 matrix input operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvert44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: **** Inversion with Determinant *****

/// 3x3 Matrix Inversion with Determinant Routine.
/// Calculates matrix inversion with determinant and provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] det_rhs 3x3 matrix determinant rhs operand.
/// @param [out] mat_out 3x3 matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatInvertDet33f(const egwMatrix33f* mat_lhs, const EGWsingle det_rhs, egwMatrix33f* mat_out);

/// 4x4 Matrix Inversion with Determinant Routine.
/// Calculates matrix inversion with determinant and provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] det_rhs 4x4 matrix determinant rhs operand.
/// @param [out] mat_out 4x4 matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatInvertDet44f(const egwMatrix44f* mat_lhs, const EGWsingle det_rhs, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Inversion with Determinant Routine.
/// Calculates array of matrix inversions with determinants and provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] dets_rhs Array of determinants rhs operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of inversions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvertDet33fv(const egwMatrix33f* mats_lhs, const EGWsingle* dets_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Inversion with Determinant Routine.
/// Calculates array of matrix inversions with determinants and provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] dets_rhs Array of determinants rhs operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of inversions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvertDet44fv(const egwMatrix44f* mats_lhs, const EGWsingle* dets_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: **** Inversion of Orthogonal *****

/// 3x3 Orthogonal Matrix Inversion Routine.
/// Calculates orthogonal matrix inversion with provided parameters.
/// @param [in] mat_in 3x3 orthogonal matrix input operand.
/// @param [out] mat_out 3x3 orthogonal matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatInvertOtg33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out);

/// 4x4 Orthogonal Matrix Inversion Routine.
/// Calculates orthogonal matrix inversion with provided parameters.
/// @param [in] mat_in 4x4 orthogonal matrix input operand.
/// @param [out] mat_out 4x4 orthogonal matrix output of inversion.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatInvertOtg44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out);

/// Arrayed 3x3 Orthogonal Matrix Inversion Routine.
/// Calculates array of orthogonal matrix inversions with provided parameters.
/// @param [in] mats_in Array of 3x3 orthogonal matrix input operands.
/// @param [out] mats_out Array of 3x3 orthgonal matrix outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvertOtg33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Orthogonal Matrix Inversion Routine.
/// Calculates array of orthogonal matrix inversions with provided parameters.
/// @param [in] mats_in Array of 4x4 orthogonal matrix input operands.
/// @param [out] mats_out Array of 4x4 orthgonal matrix outputs of inversions.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatInvertOtg44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Addition *****

/// 3x3 Matrix Addition Routine.
/// Calculates pair-wise matrix addition with provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] mat_rhs 3x3 matrix rhs operand.
/// @param [out] mat_out 3x3 matrix output of addition.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatAdd33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out);

/// 4x4 Matrix Addition Routine.
/// Calculates pair-wise matrix addition with provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] mat_rhs 4x4 matrix rhs operand.
/// @param [out] mat_out 4x4 matrix output of addition.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatAdd44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Addition Routine.
/// Calculates array of pair-wise matrix additions with provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] mats_rhs Array of 3x3 matrix rhs operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of additions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatAdd33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Addition Routine.
/// Calculates array of pair-wise matrix additions with provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] mats_rhs Array of 4x4 matrix rhs operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of additions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatAdd44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Pair-Wise Subtraction *****

/// 3x3 Matrix Subtraction Routine.
/// Calculates pair-wise matrix subtraction with provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] mat_rhs 3x3 matrix rhs operand.
/// @param [out] mat_out 3x3 matrix output of subtraction.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatSubtract33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out);

/// 4x4 Matrix Subtraction Routine.
/// Calculates pair-wise matrix subtraction with provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] mat_rhs 4x4 matrix rhs operand.
/// @param [out] mat_out 4x4 matrix output of subtraction.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatSubtract44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Subtraction Routine.
/// Calculates array of pair-wise matrix subtractions with provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] mats_rhs Array of 3x3 matrix rhs operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of subtractions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatSubtract33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Subtraction Routine.
/// Calculates array of pair-wise matrix subtractions with provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] mats_rhs Array of 4x4 matrix rhs operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of subtractions.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatSubtract44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: **** Matrix Multiplication *****

/// 3x3 Matrix Multiplication Routine.
/// Calculates matrix multiply with provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] mat_rhs 3x3 matrix rhs operand.
/// @param [out] mat_out 3x3 matrix output of multiply.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatMultiply33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out);

/// 4x4 Matrix Multiplication Routine.
/// Calculates matrix multiply with provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] mat_rhs 4x4 matrix rhs operand.
/// @param [out] mat_out 4x4 matrix output of multiply.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatMultiply44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out);

/// Arrayed 3x3 Matrix Multiplication Routine.
/// Calculates array of matrix multiplies with provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] mats_rhs Array of 3x3 matrix rhs operands.
/// @param [out] mats_out Array of 3x3 matrix outputs of multiplies.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatMultiply33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix Multiplication Routine.
/// Calculates array of matrix multiplies with provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] mats_rhs Array of 4x4 matrix rhs operands.
/// @param [out] mats_out Array of 4x4 matrix outputs of multiplies.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatMultiply44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: **** Matrix Multiplication of Homogeneous *****

/// 3x3 Homogeneous Matrix Multiplication Routine.
/// Calculates homogeneous matrix multiply with provided parameters.
/// @param [in] mat_lhs 3x3 homogeneous matrix lhs operand.
/// @param [in] mat_rhs 3x3 homogeneoues matrix rhs operand.
/// @param [out] mat_out 3x3 homogeneoues matrix output of multiply.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatMultiplyHmg33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out);

/// 4x4 Homogeneous Matrix Multiplication Routine.
/// Calculates homogeneous matrix multiply with provided parameters.
/// @param [in] mat_lhs 4x4 homogeneous matrix lhs operand.
/// @param [in] mat_rhs 4x4 homogeneoues matrix rhs operand.
/// @param [out] mat_out 4x4 homogeneoues matrix output of multiply.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatMultiplyHmg44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out);

/// Arrayed 3x3 Homogeneous Matrix Multiplication Routine.
/// Calculates array of homogeneous matrix multiplies with provided parameters.
/// @param [in] mats_lhs Array of 3x3 homogeneous matrix lhs operands.
/// @param [in] mats_rhs Array of 3x3 homogeneous matrix rhs operands.
/// @param [out] mats_out Array of 3x3 homogeneous matrix outputs of multiplies.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatMultiplyHmg33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Homogeneous Matrix Multiplication Routine.
/// Calculates array of homogeneous matrix multiplies with provided parameters.
/// @param [in] mats_lhs Array of 4x4 homogeneous matrix lhs operands.
/// @param [in] mats_rhs Array of 4x4 homogeneous matrix rhs operands.
/// @param [out] mats_out Array of 4x4 homogeneous matrix outputs of multiplies.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwMatMultiplyHmg44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);


// !!!: ***** Rotate *****

/// 3x3 Matrix Euler Rotation Routine.
/// Applies an Euler rotation about the LCS origin with the provided parameters.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] angle_r Angle of rotation (radians).
/// @param [out] mat_out 3x3 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatRotateEuler33f(const egwMatrix33f* mat_in, const EGWsingle angle_r, egwMatrix33f* mat_out);

/// 4x4 Matrix Euler Rotation Routine.
/// Applies an Euler rotation about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] angles_r LCS axes angles of rotation (radians) about respective axis.
/// @param [in] order Rotation axes ordering setting (EGW_EULERROT_ORDER_*).
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateEuler44f(const egwMatrix44f* mat_in, const egwVector3f* angles_r, const EGWint order, egwMatrix44f* mat_out);

/// 4x4 Matrix Euler Rotation Routine.
/// Applies an Euler rotation about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] angleX_r Angle of rotation (radians) about LCS X-axis.
/// @param [in] angleY_r Angle of rotation (radians) about LCS Y-axis.
/// @param [in] angleZ_r Angle of rotation (radians) about LCS Z-axis.
/// @param [in] order Rotation axes ordering setting (EGW_EULERROT_ORDER_*).
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateEuler44fs(const egwMatrix44f* mat_in, const EGWsingle angleX_r, const EGWsingle angleY_r, const EGWsingle angleZ_r, const EGWint order, egwMatrix44f* mat_out);

/// 4x4 Matrix Axis Rotation Routine.
/// Applies an axis rotation (with magnitude as angle (radians)) about the provided LCS origin axis with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] axis LCS axis of rotation.
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateAxis44f(const egwMatrix44f* mat_in, const egwVector3f* axis, egwMatrix44f* mat_out);

/// 4x4 Matrix Axis-Angle Rotation Routine.
/// Applies an axis rotation (with magnitude as angle (radians)) about the provided LCS origin axis with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] axisX LCS unit-axis of rotation X-coordinate.
/// @param [in] axisY LCS unit-axis of rotation Y-coordinate.
/// @param [in] axisZ LCS unit-axis of rotation Z-coordinate.
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateAxis44fs(const egwMatrix44f* mat_in, const EGWsingle axisX, const EGWsingle axisY, const EGWsingle axisZ, egwMatrix44f* mat_out);

/// 4x4 Matrix Axis-Angle Rotation Routine.
/// Applies an axis-angle rotation about the provided LCS origin axis with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] axis_u LCS unit-axis of rotation.
/// @param [in] angle_r Angle of rotation (radians).
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateAxisAngle44f(const egwMatrix44f* mat_in, const egwVector3f* axis_u, const EGWsingle angle_r, egwMatrix44f* mat_out);

/// 4x4 Matrix Axis-Angle Rotation Routine.
/// Applies an axis-angle rotation about the provided LCS origin axis with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] axisX_u LCS unit-axis of rotation X-coordinate.
/// @param [in] axisY_u LCS unit-axis of rotation Y-coordinate.
/// @param [in] axisZ_u LCS unit-axis of rotation Z-coordinate.
/// @param [in] angle_r Angle of rotation (radians).
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateAxisAngle44fs(const egwMatrix44f* mat_in, const EGWsingle axisX_u, const EGWsingle axisY_u, const EGWsingle axisZ_u, const EGWsingle angle_r, egwMatrix44f* mat_out);

/// 3x3 Matrix Vector-Vector Rotation Routine.
/// Applies an Euler rotation about the LCS origin from the provided parameters (calculated cross product).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] vec_fr 2-D vector from operand.
/// @param [in] vec_to 2-D vector to operand.
/// @param [out] mat_out 3x3 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatRotateVecVec33f(const egwMatrix33f* mat_in, const egwVector2f* vec_fr, const egwVector2f* vec_to, egwMatrix33f* mat_out);

/// 4x4 Matrix Vector-Vector Rotation Routine.
/// Applies an axis-angle rotation about the calculated LCS origin axis from the provided parameters (calculated cross product and magnitude).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] vec_fr 3-D vector from operand.
/// @param [in] vec_to 3-D vector to operand.
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateVecVec44f(const egwMatrix44f* mat_in, const egwVector3f* vec_fr, const egwVector3f* vec_to, egwMatrix44f* mat_out);

/// 3x3 Matrix Vector-Vector Rotation Routine.
/// Applies an Euler rotation about the LCS origin from the provided parameters (calculated cross product).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] vecX_fr 2-D vector X-coordinate from operand.
/// @param [in] vecY_fr 2-D vector Y-coordinate from operand.
/// @param [in] vecX_to 2-D vector X-coordinate to operand.
/// @param [in] vecY_to 2-D vector Y-coordinate to operand.
/// @param [out] mat_out 3x3 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatRotateVecVec33fs(const egwMatrix33f* mat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, egwMatrix33f* mat_out);

/// 4x4 Matrix Vector-Vector Rotation Routine.
/// Applies an axis-angle rotation about the calculated LCS origin axis from the provided parameters (calculated cross product and magnitude).
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] vecX_fr 3-D vector X-coordinate from operand.
/// @param [in] vecY_fr 3-D vector Y-coordinate from operand.
/// @param [in] vecZ_fr 3-D vector Z-coordinate from operand.
/// @param [in] vecX_to 3-D vector X-coordinate to operand.
/// @param [in] vecY_to 3-D vector Y-coordinate to operand.
/// @param [in] vecZ_to 3-D vector Z-coordinate to operand.
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateVecVec44fs(const egwMatrix44f* mat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecZ_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, const EGWsingle vecZ_to, egwMatrix44f* mat_out);

/// 4x4 Matrix Quaternion Rotation Routine.
/// Applies a quaternion rotation from the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] quat_in 4-D quaternion input operand.
/// @param [out] mat_out 4x4 matrix output of rotation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatRotateQuaternion44f(const egwMatrix44f* mat_in, const egwQuaternion4f* quat_in, egwMatrix44f* mat_out);


// !!!: ***** Translate *****

/// 3x3 Matrix Translation Routine.
/// Applies a translation about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] pos LCS position vector operand.
/// @param [out] mat_out 3x3 matrix output of translation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatTranslate33f(const egwMatrix33f* mat_in, const egwVector2f* pos, egwMatrix33f* mat_out);

/// 4x4 Matrix Translation Routine.
/// Applies a translation about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] pos LCS position vector operand.
/// @param [out] mat_out 4x4 matrix output of translation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatTranslate44f(const egwMatrix44f* mat_in, const egwVector3f* pos, egwMatrix44f* mat_out);

/// 3x3 Matrix Translation Routine.
/// Applies a translation about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] posX LCS position vector X-coordinate operand.
/// @param [in] posY LCS position vector Y-coordinate operand.
/// @param [out] mat_out 3x3 matrix output of translation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatTranslate33fs(const egwMatrix33f* mat_in, const EGWsingle posX, const EGWsingle posY, egwMatrix33f* mat_out);

/// 4x4 Matrix Translation Routine.
/// Applies a translation about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] posX LCS position vector X-coordinate operand.
/// @param [in] posY LCS position vector Y-coordinate operand.
/// @param [in] posZ LCS position vector Y-coordinate operand.
/// @param [out] mat_out 4x4 matrix output of translation of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatTranslate44fs(const egwMatrix44f* mat_in, const EGWsingle posX, const EGWsingle posY, const EGWsingle posZ, egwMatrix44f* mat_out);


// !!!: ***** Scale *****

/// 3x3 Matrix Scaling Routine.
/// Applies a scaling about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] scale LCS scaling vector operand.
/// @param [out] mat_out 3x3 matrix output of scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatScale33f(const egwMatrix33f* mat_in, const egwVector2f* scale, egwMatrix33f* mat_out);

/// 4x4 Matrix Scaling Routine.
/// Applies a scaling about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] scale LCS scaling vector operand.
/// @param [out] mat_out 4x4 matrix output of scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatScale44f(const egwMatrix44f* mat_in, const egwVector3f* scale, egwMatrix44f* mat_out);

/// 3x3 Matrix Scaling Routine.
/// Applies a scaling about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] scaleX LCS scaling vector X-coordinate operand.
/// @param [in] scaleY LCS scaling vector Y-coordinate operand.
/// @param [out] mat_out 3x3 matrix output of scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatScale33fs(const egwMatrix33f* mat_in, const EGWsingle scaleX, const EGWsingle scaleY, egwMatrix33f* mat_out);

/// 4x4 Matrix Scaling Routine.
/// Applies a scaling about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] scaleX LCS scaling vector X-coordinate operand.
/// @param [in] scaleY LCS scaling vector Y-coordinate operand.
/// @param [in] scaleZ LCS scaling vector Z-coordinate operand.
/// @param [out] mat_out 4x4 matrix output of scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatScale44fs(const egwMatrix44f* mat_in, const EGWsingle scaleX, const EGWsingle scaleY, const EGWsingle scaleZ, egwMatrix44f* mat_out);

/// 3x3 Matrix Universal Scaling Routine.
/// Applies an universal scaling about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] scaleU LCS universal scaling scalar operand.
/// @param [out] mat_out 3x3 matrix output of universal scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatUScale33f(const egwMatrix33f* mat_in, const EGWsingle scaleU, egwMatrix33f* mat_out);

/// 4x4 Matrix Universal Scaling Routine.
/// Applies an universal scaling about the LCS origin axes with the provided parameters.
/// @note This routine is provided for simplicity, layering operands for another routine call.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] scaleU LCS universal scaling scalar operand.
/// @param [out] mat_out 4x4 matrix output of universal scaling of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatUScale44f(const egwMatrix44f* mat_in, const EGWsingle scaleU, egwMatrix44f* mat_out);


// !!!: ***** Shear *****

/// 3x3 Matrix Shearing Routine.
/// Applies a shearing about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 3x3 matrix input operand. May be NULL (for identity).
/// @param [in] shear LCS shearing scalar operand.
/// @param [in] type Shearing type setting (EGW_MATRIX_SHEAR_TYPE_*).
/// @param [out] mat_out 3x3 matrix output of shearing of input operand.
/// @return @a mat_out (for nesting).
egwMatrix33f* egwMatShear33f(const egwMatrix33f* mat_in, const EGWsingle shear, const EGWint type, egwMatrix33f* mat_out);

/// 4x4 Matrix Shearing Routine.
/// Applies a shearing about the LCS origin axes with the provided parameters.
/// @param [in] mat_in 4x4 matrix input operand. May be NULL (for identity).
/// @param [in] shear LCS shearing scalar operand.
/// @param [in] type Shearing type setting (EGW_MATRIX_SHEAR_TYPE_*).
/// @param [out] mat_out 4x4 matrix output of shearing of input operand.
/// @return @a mat_out (for nesting).
egwMatrix44f* egwMatShear44f(const egwMatrix44f* mat_in, const EGWsingle shear, const EGWint type, egwMatrix44f* mat_out);


// !!!: ***** Vector Transform *****

/// 3x3 Matrix 2-D Vector Transform Routine.
/// Calculates vector transform with the provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] vec_rhs 2-D vector rhs operand.
/// @param [in] w_in Vector W-coordinate input operand.
/// @param [out] vec_out 2-D vector output of transforming.
/// @return @a vec_out (for nesting).
egwVector2f* egwVecTransform332f(const egwMatrix33f* mat_lhs, const egwVector2f* vec_rhs, const EGWsingle w_in, egwVector2f* vec_out);

/// 3x3 Matrix 3-D Vector Transform Routine.
/// Calculates vector transform with the provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [out] vec_out 3-D vector output of transforming.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecTransform333f(const egwMatrix33f* mat_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out);

/// 4x4 Matrix 3-D Vector Transform Routine.
/// Calculates vector transform with the provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] vec_rhs 3-D vector rhs operand.
/// @param [in] w_in Vector W-coordinate input operand.
/// @param [out] vec_out 3-D vector output of transforming.
/// @return @a vec_out (for nesting).
egwVector3f* egwVecTransform443f(const egwMatrix44f* mat_lhs, const egwVector3f* vec_rhs, const EGWsingle w_in, egwVector3f* vec_out);

/// 4x4 Matrix 4-D Vector Transform Routine.
/// Calculates vector transform with the provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] vec_rhs 4-D vector rhs operand.
/// @param [out] vec_out 4-D vector output of transforming.
/// @return @a vec_out (for nesting).
egwVector4f* egwVecTransform444f(const egwMatrix44f* mat_lhs, const egwVector4f* vec_rhs, egwVector4f* vec_out);

/// Arrayed 3x3 Matrix 2-D Vector Transform Routine.
/// Calculates array of vector transforms with the provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] vecs_rhs Array of 2-D vector rhs operands.
/// @param [in] ws_in Array of vector W-coordinate input operands.
/// @param [out] vecs_out Array of 2-D vector outputs of transformings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecTransform332fv(const egwMatrix33f* mats_lhs, const egwVector2f* vecs_rhs, const EGWsingle* ws_in, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 3x3 Matrix 3-D Vector Transform Routine.
/// Calculates array of vector transforms with the provided parameters.
/// @param [in] mats_lhs Array of 3x3 matrix lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [out] vecs_out Array of 3-D vector outputs of transformings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecTransform333fv(const egwMatrix33f* mats_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix 3-D Vector Transform Routine.
/// Calculates array of vector transforms with the provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] vecs_rhs Array of 3-D vector rhs operands.
/// @param [in] ws_in Array of vector W-coordinate input operands.
/// @param [out] vecs_out Array of 3-D vector outputs of transformings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecTransform443fv(const egwMatrix44f* mats_lhs, const egwVector3f* vecs_rhs, const EGWsingle* ws_in, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed 4x4 Matrix 4-D Vector Transform Routine.
/// Calculates array of vector transforms with the provided parameters.
/// @param [in] mats_lhs Array of 4x4 matrix lhs operands.
/// @param [in] vecs_rhs Array of 4-D vector rhs operands.
/// @param [out] vecs_out Array of 4-D vector outputs of transformings.
/// @param [in] strideB_lhs Array advancing skip bytes on lhs operands.
/// @param [in] strideB_rhs Array advancing skip bytes on rhs operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwVecTransform444fv(const egwMatrix44f* mats_lhs, const egwVector4f* vecs_rhs, egwVector4f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count);

/// @}

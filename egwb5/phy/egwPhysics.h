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

/// @defgroup geWizES_phy_physics egwPhysics
/// @ingroup geWizES_phy
/// Base Physics.
/// @{

/// @file egwMath.h
/// Base Physics Interface.

#import <math.h>
#import "egwPhyTypes.h"
#import "../math/egwMathTypes.h"
#import "../geo/egwGeoTypes.h"


// !!!: ***** Interpolation *****

/// Interpolation Routine Routine.
/// Determines the correct interpolation routine to utilize given the provided paramters.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] polationMode_in Polation mode (EGW_POLATION_*).
/// @return Interpolation routine address, otherwise NULL (if routine unavailable).
EGWiepofuncfp egwIpoRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in);

/// Interpolation Create Extended Frame Data Routine Routine.
/// Determines the correct create interpolation extra frame data routine to utilize given the provided parameters.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] polationMode_in Polation mode (EGW_POLATION_*).
/// @return Create interpolation extra frame data routine address.
EGWcefdfuncfp egwIpoCreateExtFrmDatRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in);

/// Interpolation Frame Data Frame Pitch Routine.
/// Calculates the correct frame pitch size given the provided parameters.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] chnCount_in Number of key channels.
/// @param [in] cmpCount_in Number of key channel components.
/// @param [in] polationMode_in Polation mode (EGW_POLATION_*).
/// @return Frame data pitch size (bytes).
EGWuint egwIpoExtFrmDatFrmPitch(EGWuint chnFormat_in, EGWuint chnCount_in, EGWuint cmpCount_in, EGWuint32 polationMode_in);

/// Interpolation Frame Data Component Pitch Routine.
/// Calculates the correct component pitch size given the provided parameters.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] chnCount_in Number of key channels.
/// @param [in] polationMode_in Polation mode (EGW_POLATION_*).
/// @return Component data pitch size (bytes).
EGWuint egwIpoExtFrmDatCmpPitch(EGWuint chnFormat_in, EGWuint chnCount_in, EGWuint32 polationMode_in);

/// Stepped Interpolation (INT8).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedi8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out);

/// Stepped Interpolation (UINT8).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out);

/// Stepped Interpolation (INT16).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedi16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out);

/// Stepped Interpolation (UINT16).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out);

/// Stepped Interpolation (INT32).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedi32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out);

/// Stepped Interpolation (UINT32).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out);

/// Stepped Interpolation (FLT).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Stepped Interpolation (DBL).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Stepped Interpolation (TRP).
/// Calculates the resulting stepped interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSteppedt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);

/// Linear Interpolation (INT8).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLineari8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out);

/// Linear Interpolation (UINT8).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLinearui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out);

/// Linear Interpolation (INT16).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLineari16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out);

/// Linear Interpolation (UINT16).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLinearui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out);

/// Linear Interpolation (INT32).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLineari32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out);

/// Linear Interpolation (UINT32).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLinearui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out);

/// Linear Interpolation (FLT).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLinearf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Linear Interpolation (DBL).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLineard(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Linear Interpolation (TRP).
/// Calculates the resulting linear interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoLineart(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);

/// Spherical Linear Interpolation Create Extra Frame Data Routine (FLT).
/// Calculates the extra frame data required to process spherical linear interpolation based interpolations along a knot track line.
/// @param [in] keyData_in Raw key frame data buffer input.
/// @param [out] extraData_out Raw extra frame data buffer output.
/// @param [in] cmpntPitch_in Component data pitch size for raw data buffer input (bytes).
/// @param [in] framePitch_in Frame data pitch size for raw data buffer input (bytes).
/// @param [in] exDatCmpntPitch_out Extra frame data component data pitch size for raw data buffer output (bytes).
/// @param [in] exDatFramePitch_out Extra frame data frame data pitch size for raw data buffer output (bytes).
/// @param [in] frameCount Number of key channel frames.
/// @param [in] cmpCount Number of component key channels.
/// @param [in] chnCount Number of key channels.
void egwIpoSlerpCreateExtFrmDatf(const EGWsingle* keyData_in, EGWsingle* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount);

/// Spherical Linear Interpolation Create Extra Frame Data Routine (DBL).
/// Calculates the extra frame data required to process spherical linear interpolation based interpolations along a knot track line.
/// @param [in] keyData_in Raw key frame data buffer input.
/// @param [out] extraData_out Raw extra frame data buffer output.
/// @param [in] cmpntPitch_in Component data pitch size for raw data buffer input (bytes).
/// @param [in] framePitch_in Frame data pitch size for raw data buffer input (bytes).
/// @param [in] exDatCmpntPitch_out Extra frame data component data pitch size for raw data buffer output (bytes).
/// @param [in] exDatFramePitch_out Extra frame data frame data pitch size for raw data buffer output (bytes).
/// @param [in] frameCount Number of key channel frames.
/// @param [in] cmpCount Number of component key channels.
/// @param [in] chnCount Number of key channels.
void egwIpoSlerpCreateExtFrmDatd(const EGWdouble* keyData_in, EGWdouble* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount);

/// Spherical Linear Interpolation Create Extra Frame Data Routine (TRP).
/// Calculates the extra frame data required to process spherical linear interpolation based interpolations along a knot track line.
/// @param [in] keyData_in Raw key frame data buffer input.
/// @param [out] extraData_out Raw extra frame data buffer output.
/// @param [in] cmpntPitch_in Component data pitch size for raw data buffer input (bytes).
/// @param [in] framePitch_in Frame data pitch size for raw data buffer input (bytes).
/// @param [in] exDatCmpntPitch_out Extra frame data component data pitch size for raw data buffer output (bytes).
/// @param [in] exDatFramePitch_out Extra frame data frame data pitch size for raw data buffer output (bytes).
/// @param [in] frameCount Number of key channel frames.
/// @param [in] cmpCount Number of component key channels.
/// @param [in] chnCount Number of key channels.
void egwIpoSlerpCreateExtFrmDatt(const EGWtriple* keyData_in, EGWtriple* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount);

/// Spherical Linear Interpolation (FLT).
/// Calculates the resulting spherical linear interpolation along a knot track line using the provided parameters.
/// @note The extra frame data section of the track line should be valid.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSlerpf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Spherical Linear Interpolation (DBL).
/// Calculates the resulting spherical linear interpolation along a knot track line using the provided parameters.
/// @note The extra frame data section of the track line should be valid.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSlerpd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Spherical Linear Interpolation (TRP).
/// Calculates the resulting spherical linear interpolation along a knot track line using the provided parameters.
/// @note The extra frame data section of the track line should be valid.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoSlerpt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);

/// Catmull-Rom Cubic Interpolation (FLT).
/// Calculates the resulting catmull-rom cubic interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoCubicCRf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Catmull-Rom Cubic Interpolation (DBL).
/// Calculates the resulting catmull-rom cubic interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoCubicCRd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Catmull-Rom Cubic Interpolation (TRP).
/// Calculates the resulting catmull-rom cubic interpolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwIpoCubicCRt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);


// !!!: ***** Extrapolation *****

/// Extrapolation Routine Routine.
/// Determines the correct extrapolation routine to utilize given the provided paramters.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] polationMode_in Polation mode (EGW_POLATION_*).
/// @return Extrapolation routine address, otherwise NULL (if routine unavailable).
EGWiepofuncfp egwEpoRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in);

/// Constant Extrapolation (INT8).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstanti8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out);

/// Constant Extrapolation (UINT8).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out);

/// Constant Extrapolation (INT16).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstanti16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out);

/// Constant Extrapolation (UINT16).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out);

/// Constant Extrapolation (INT32).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstanti32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out);

/// Constant Extrapolation (UINT32).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out);

/// Constant Extrapolation (FLT).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Constant Extrapolation (DBL).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Constant Extrapolation (TRP).
/// Calculates the resulting constant extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoConstantt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);

/// Linear Extrapolation (INT8).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLineari8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out);

/// Linear Extrapolation (UINT8).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLinearui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out);

/// Linear Extrapolation (INT16).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLineari16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out);

/// Linear Extrapolation (UINT16).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLinearui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out);

/// Linear Extrapolation (INT32).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLineari32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out);

/// Linear Extrapolation (UINT32).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLinearui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out);

/// Linear Extrapolation (FLT).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLinearf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out);

/// Linear Extrapolation (DBL).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLineard(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out);

/// Linear Extrapolation (TRP).
/// Calculates the resulting linear extrapolation along a knot track line using the provided parameters.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoLineart(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out);

/// No Operation Extrapolation.
/// Acts as an addressable but non-operable extrapolation routine when no extrapolation is to be done.
/// @param [in] line_in Knot track line structure input.
/// @param [in] absT_in Absolute time index (seconds).
/// @param [out] result_out Raw data buffer output.
void egwEpoNoOp(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWbyte* result_out);


// !!!: ***** Force/Torque Conversions *****

/// Force To Acceleration Conversion Routine.
/// Calculates the linear acceleration vector given a linear force vector and a mass.
/// @param [in] force_in Linear force vector (N).
/// @param [in] massInv_in Invesed mass (1/kg).
/// @param [out] accel_out Acceleration force vector (m/s^2).
void egwForceToAcceleration(const egwVector3f* force_in, const EGWsingle massInv_in, egwVector3f* accel_out);

/// Force To Torque Conversion Routine.
/// Calculates the rotational torquing force vector given a liner force vector and offset.
/// @param [in] force_in Linear force vector (N).
/// @param [in] offset_in Linear force vector offset from center.
/// @param [out] torque_out Rotational torquing force (N).
void egwForceToTorque(const egwVector3f* force_in, const egwVector3f* offset_in, egwVector3f* torque_out);

/// Torque To Acceleration Conversion Routine.
/// Calculates the rotational acceleration vector given a rotational torquing force vector and inertia tensor.
/// @param [in] torque_in Rotational torquing force (N).
/// @param [in] inertiaInv_in Inversed inertia tensor (1/kg).
/// @param [in] accel_out Rotational acceleration vector (m/s^2).
void egwTorqueToAcceleration(const egwVector3f* torque_in, const egwMatrix44f* inertiaInv_in, egwVector3f* accel_out);

/// Linear And Rotational Position To Matrix Conversion Routine.
/// Calculates the resultant orientation matrix given a linear and rotational position.
/// @param [in] linearPos_in Linear position vector.
/// @param [in] angularPos_in Angular position vector.
/// @param [out] matrix_out Orientation matrix.
void egwPositionsToMatrix(const egwVector3f* linearPos_in, const egwVector3f* angularPos_in, egwMatrix44f* matrix_out);


// !!!: ***** Update Integrations *****

/// Linear Update Integration.
/// Calculates the linear position update integration using the provided parameters.
/// @param [in] rate_in Rate vector input.
/// @param [in] damping_in Damping coefficient (use 1.0f for no damping).
/// @param [in] deltaT_in Delta time offset (seconds).
/// @param [in,out] vector_inout Vector input/output.
void egwIntegrateLinear(const egwVector3f* rate_in, const EGWsingle damping_in, const EGWtime deltaT_in, egwVector3f* vector_inout);

/// Linear Average Update Integration.
/// Calculates the linear average position update integration using the provided parameters.
/// @param [in] prevRate_in Previous rate vector input.
/// @param [in] nextRate_in Next rate vector input.
/// @param [in] damping_in Damping coefficient (use 1.0f for no damping).
/// @param [in] deltaT_in Delta time offset (seconds).
/// @param [in,out] vector_inout Vector input/output.
void egwIntegrateLinAvg(const egwVector3f* prevRate_in, const egwVector3f* nextRate_in, const EGWsingle damping_in, const EGWtime deltaT_in, egwVector3f* vector_inout);


// !!!: ***** Inertia Tensor Primitives *****

/// Solid Sphere Inertia Tensor Primitive Routine.
/// Calulates a solid sphere inertia tensor primitive using the provided parameters.
/// @param [in] sphere_in Sphere dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorSolidSphere(const egwSphere4f* sphere_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Hollow Sphere Inertia Tensor Primitive Routine.
/// Calulates a hollow sphere inertia tensor primitive using the provided parameters.
/// @param [in] sphere_in Sphere dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorHollowSphere(const egwSphere4f* sphere_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Solid Box Inertia Tensor Primitive Routine.
/// Calulates a solid box inertia tensor primitive using the provided parameters.
/// @param [in] box_in Box dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorSolidBox(const egwBox4f* box_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Hollow Box Inertia Tensor Primitive Routine.
/// Calulates a hollow box inertia tensor primitive using the provided parameters.
/// @param [in] box_in Box dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorHollowBox(const egwBox4f* box_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Solid Cone Inertia Tensor Primitive Routine.
/// Calulates a solid cone inertia tensor primitive using the provided parameters.
/// @param [in] cone_in Cone dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorSolidCone(const egwCone4f* cone_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Hollow Cone Inertia Tensor Primitive Routine.
/// Calulates a hollow cone inertia tensor primitive using the provided parameters.
/// @param [in] cone_in Cone dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorHollowCone(const egwCone4f* cone_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Solid Cylinder Inertia Tensor Primitive Routine.
/// Calulates a solid cylinder inertia tensor primitive using the provided parameters.
/// @param [in] cylinder_in Cylinder dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorSolidCylinder(const egwCylinder4f* cylinder_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Hollow Cylinder Inertia Tensor Primitive Routine.
/// Calulates a hollow cylinder inertia tensor primitive using the provided parameters.
/// @param [in] cylinder_in Cylinder dimensions input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorHollowCylinder(const egwCylinder4f* cylinder_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Centered Rod Inertia Tensor Primitive Routine.
/// Calulates a centered rod inertia tensor primitive using the provided parameters.
/// @param [in] rodLenX_in Rod length input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorCenteredRod(const EGWsingle rodLenX_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);

/// Extended Rod Inertia Tensor Primitive Routine.
/// Calulates a extended rod inertia tensor primitive using the provided parameters.
/// @param [in] rodLenX_in Rod length input (m).
/// @param [in] mass_in Mass of object (kg).
/// @param [out] inertia_out Inertia tensor matrix output.
void egwInertiaTensorExtendedRod(const EGWsingle rodLenX_in, const EGWsingle mass_in, egwMatrix44f* inertia_out);


// !!!: ***** Key Frame Operations *****

/// Key Frames Allocation Routine.
/// Allocates key frame data with provided parameters.
/// @param [out] kyfrm_out Key frames output of allocation.
/// @param [in] chnFormat_in Key channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] channelC_in Channel count.
/// @param [in] componentC_in Component count.
/// @param [in] frameC_in Frame count.
/// @return @a kyfrm_out (for nesting), otherwise NULL if failure allocating.
egwKeyFrame* egwKeyFrmAlloc(egwKeyFrame* kyfrm_out, EGWuint16 chnFormat_in, EGWuint16 channelC_in, EGWuint16 componentC_in, EGWuint16 frameC_in);

/// Orientation Key Frames Allocation Routine.
/// Allocates orientation key frame data with provided parameters.
/// @param [out] orkyfrm_out Orientation key frames output of allocation.
/// @param [in] posFrameC_in Position frames count (may be 0 for none).
/// @param [in] rotFrameC_in Rotation frames count (may be 0 for none).
/// @param [in] sclFrameC_in Scaling frames count (may be 0 for none).
/// @return @a orkyfrm_out (for nesting), otherwise NULL if failure allocating.
egwOrientKeyFrame4f* egwOrtKeyFrmAllocf(egwOrientKeyFrame4f* orkyfrm_out, EGWuint16 posFrameC_in, EGWuint16 rotFrameC_in, EGWuint16 sclFrameC_in);

/// Key Frames Free Routine.
/// Frees the contents of the key frames.
/// @param [in,out] kyfrm_inout Key frames input/output structure.
/// @return @a kyfrm_inout (for nesting).
egwKeyFrame* egwKeyFrmFree(egwKeyFrame* kyfrm_inout);

/// Orientation Key Frames Free Routine.
/// Frees the contents of the orientation key frames.
/// @param [in,out] orkyfrm_inout Orientation key frames input/output structure.
/// @return @a orkyfrm_inout (for nesting).
egwOrientKeyFrame4f* egwOrtKeyFrmFree(egwOrientKeyFrame4f* orkyfrm_inout);

/// @}

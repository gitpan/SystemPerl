// $Id: Sp.cpp 11992 2006-01-16 18:59:58Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2006 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//=============================================================================
///
/// \file
/// \brief Includes All SystemPerl Modules
///
/// AUTHOR:  Wilson Snyder
///
/// This includes all SystemPerl modules into one CPP file.
///
/// Thus users can simply compile this one file and get all SystemPerl stuff,
/// at a much better compile time then each separately.
//=============================================================================

#include "SpTraceVcd.cpp"
#include "SpTraceVcdC.cpp"
#include "SpCoverage.cpp"
#include "SpFunctor.cpp"
#include "sp_log.cpp"

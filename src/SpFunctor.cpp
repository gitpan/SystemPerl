// $Id: SpFunctor.cpp 37619 2007-04-30 13:20:11Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2007 by Wilson Snyder.  This program is free software;
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
/// \brief SystemPerl Functors
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <map>
#include "SpFunctor.h"

//=============================================================================
// SpFunctorNamedImp
///  Implementation of SpFunctorNamed

class SpFunctorNamedImp {	
public:
    typedef multimap<string, SpFunctor*>  FtMap;	///< Map typedef
    static FtMap	s_map;	///< Multimap of all functors for each name
};

SpFunctorNamedImp::FtMap SpFunctorNamedImp::s_map;

//=============================================================================
// SpFunctorNamed

void SpFunctorNamed::add(const char* funcName, SpFunctor* ftor) {
    SpFunctorNamedImp::s_map.insert(std::make_pair((string)funcName,ftor));
}

void SpFunctorNamed::call(const char* funcName, void* userdata) {
    for (SpFunctorNamedImp::FtMap::iterator iter=SpFunctorNamedImp::s_map.find(funcName);
	 iter!=SpFunctorNamedImp::s_map.end(); ++iter) {
	const string& fname = iter->first;
	SpFunctor* ftor = iter->second;
	if (fname != funcName) return;
	if (ftor) {
	    ftor->call(userdata);
	}
    }
}

// $Revision: #6 $$Date: 2004/01/27 $$Author: wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2004 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//=============================================================================
//
// AUTHOR:  Wilson Snyder
//
// DESCRIPTION: SystemPerl Functors
//
//=============================================================================
//
// This allows you to declare a named function and later invoke that function.
// Multiple functions may have the same name, all will be called when that
// name is invoked.  This is like hooks in Emacs.
//
// For example:
//	 class x {
//	     void myfunc ();
//	     ...
//	     x() { // constructor
//	        SpFunctorNamed::add("do_it", &myfunc);
//
// Then you can invoke
//		SpFunctorNamed::call("do_it");
//
// Which will call x_this->myfunc()
//
//=============================================================================

#ifndef _VLFUNCTOR_H_
#define _VLFUNCTOR_H_ 1

#include <sys/types.h>	// uint32_t
#include <stdint.h>	// uint32_t

//=============================================================================
// SpFunctor

class SpFunctor {
  public:
    SpFunctor() {};
    virtual void call(void* userdata) = 0;
};
template <class T> class SpFunctorSpec : public SpFunctor {
    void (T::*m_cb)(void* userdata);	// Pointer to method function
    T*	m_obj;		// Module object to invoke on
  public:
    typedef void (T::*Func)(void*);
    SpFunctorSpec(T* obj, void (T::*cb)(void*)) : m_cb(cb), m_obj(obj) {}
    virtual void call(void* userdata) { (*m_obj.*m_cb)(userdata); } 
};

//=============================================================================
// SpFunctorNamed

class SpFunctorNamed {
public:
    // CREATORS:
  template <class T>
    static void add(const char* funcName, void (T::*cb)(void* userdata), T* that) {
      add(funcName, new SpFunctorSpec<T>(that,cb));
    }
    //template <class T>	// Doesn't work yet
    //static void add(const char* funcName, void (T::*cb)(), T* that) {
    //add(funcName, new SpFunctorSpec<T>(that,cb));
    //}
    static void add(const char* funcName, SpFunctor* ftor);
    // INVOCATION:
    static void call(const char* funcName) {call(funcName,NULL);}
    static void call(const char* funcName, void* userdata);
};

#endif // guard

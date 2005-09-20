// $Id: ExEnum.sp 6159 2005-09-13 20:36:56Z wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <fstream>

#define FUNC0() 7
#define FUNC1(a) a
#define FUNC4(a,b,c,d) 1+d

class MyENumClass {
public:
    static const unsigned SIX_DEF = 6;
    enum en {
	IDLE = 0,
	ONE, TWO, THREE, FOUR,
	SIX = SIX_DEF,
	SEVEN = FUNC0(),
	EIGHT = FUNC1(FUNC4(1,2,3,FUNC0()))
    };
    /*AUTOENUM_CLASS(MyENumClass.en)*/
};
/*AUTOENUM_GLOBAL(MyENumClass.en)*/

#sp implementation


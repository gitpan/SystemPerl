// $Revision: #6 $$Date: 2003/09/22 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2003 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <fstream>

class MyENumClass {
public:
    static const unsigned SIX_DEF = 6;
    enum en {
	IDLE = 0,
	ONE, TWO, THREE, FOUR, FIVE,
	SIX = SIX_DEF
    };
    /*AUTOENUM_CLASS(MyENumClass.en)*/
};
/*AUTOENUM_GLOBAL(MyENumClass.en)*/

#sp implementation


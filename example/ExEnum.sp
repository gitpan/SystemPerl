// $Revision: #4 $$Date: 2003/03/11 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
#include <ostream.h>

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


// $Revision: #5 $$Date: 2003/08/12 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module

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


// $Revision: #3 $$Date: 2002/07/16 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
#include <ostream.h>

class MyENumClass {
public:
    enum en {
	IDLE = 0,
	ONE, TWO, THREE, FOUR, FIVE
    };
    /*AUTOENUM_CLASS(MyENumClass.en)*/
};
/*AUTOENUM_GLOBAL(MyENumClass.en)*/

#sp implementation


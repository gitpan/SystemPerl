// $Id: ExEnum.sp,v 1.2 2001/08/31 14:56:15 wsnyder Exp $
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


// $Id: ex_enum.sp,v 1.1 2001/04/13 16:36:23 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

#sp interface

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


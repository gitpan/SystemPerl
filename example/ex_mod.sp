// $Id: ex_mod.sp,v 1.1 2001/04/03 14:49:34 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

//error test:
///*AUTOSIGNAL*/

#sp interface

#include "ex_mod_sub.h"

SC_MODULE (__MODULE__) {

    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

    /*AUTOSUBCELLS*/

    //error test:
    //sc_signal<bool> in;

    /*AUTOSIGNAL*/

    SC_CTOR(__MODULE__) {
	//====
	SP_CELL (sub0, ex_mod_sub);
	 SP_PIN  (sub0, out, cross);
	 /*AUTOINST*/	

	 //Error test:
	 //SP_PIN  (sub0, nonexisting_error, cross);

	//====
	SP_CELL (sub1, ex_mod_sub);
	 SP_PIN  (sub1, in, cross);
	 /*AUTOINST*/

    };
};

// $Id: ex_mod.sp,v 1.3 2001/04/24 14:20:21 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

//error test:
///*AUTOSIGNAL*/

#sp interface

#include "ex_mod_sub.h"

SC_MODULE (__MODULE__) {

    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

    SP_CELL_DECL (ex_mod_sub, sub[1]);
    /*AUTOSUBCELLS*/

    //error test:
    //sc_signal<bool> in;

    /*AUTOSIGNAL*/

    SC_CTOR(__MODULE__) {
	//====
	SP_CELL (sub[0], ex_mod_sub);
	 SP_PIN  (sub[0], out, cross);
	 /*AUTOINST*/	

	 //Error test:
	 //SP_PIN  (sub0, nonexisting_error, cross);

	//====
	SP_CELL (suba, ex_mod_sub);
	 SP_PIN  (suba, in, cross);
	 /*AUTOINST*/

    };
};

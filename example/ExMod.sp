// $Id: ExMod.sp,v 1.4 2001/09/26 14:51:02 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

//error test:
///*AUTOSIGNAL*/

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    static const int ARRAYSIZE = 3;

    sc_in_clk		clk;		/* System Clock */
    sc_in<bool>		in;		// Input from bench to   ExMod
    sc_out<bool>	out;		// Output to  bench from ExMod
    sc_signal<uint32_t> out_array[ARRAYSIZE];

    SP_CELL_DECL (ExModSub, sub[1]);

    /*AUTOSUBCELLS*/
    /*AUTOSIGNAL*/
  public:
    /*AUTOMETHODS*/

    //error test:
    //sc_signal<bool> in;
};

#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
    //====
    SP_CELL (sub[0], ExModSub);
    SP_PIN  (sub[0], out, cross);
    /*AUTOINST*/	

    //Error test:
    //SP_PIN  (sub0, nonexisting_error, cross);
    
    //====
    SP_CELL (suba, ExModSub);
    SP_PIN  (suba, in, cross);
    /*AUTOINST*/

    for (int i=0; i<ARRAYSIZE; i++) out_array[i].write(i);
}

/*AUTOTRACE(__MODULE__)*/

// $Revision: #9 $$Date: 2002/07/16 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module

//error test:
///*AUTOSIGNAL*/

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    static const int MOD_CELLS = 3;

    sc_in_clk		clk;		/* System Clock */
    sc_in<bool>		in;		// Input from bench to   ExMod
    sc_out<bool>	out;		// Output to  bench from ExMod

  private:
    sc_signal<bool>	out_array[MOD_CELLS];

    SP_CELL_DECL (ExModSub, sub[MOD_CELLS]);

    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/

    //error test:
    //sc_signal<bool> in;
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
    //====
    SP_CELL (sub[0], ExModSub);
    SP_PIN  (sub[0], out, out_array[0]);
    /*AUTOINST*/	

    SP_CELL (sub[1], ExModSub);
    SP_PIN  (sub[1], out, out_array[1]);
    /*AUTOINST*/	

    //Error test:
    //SP_PIN  (sub0, nonexisting_error, cross);
    
    //====
    SP_CELL (suba, ExModSub);
    SP_PIN  (suba, in, out_array[0]);
    /*AUTOINST*/

    for (int i=0; i<MOD_CELLS; i++) out_array[i].write(i);
#ifdef NEVER
    out.write(0);
#endif
}

/*AUTOTRACE(__MODULE__,recurse)*/

// $Id: ex_mod.sp,v 1.6 2001/06/27 13:10:53 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

//error test:
///*AUTOSIGNAL*/

#sp interface
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {

    sc_in_clk		clk;		/* System Clock */
    sc_in<bool>		in;		// Input from bench to   ex_mod
    sc_out<bool>	out;		// Output to  bench from ex_mod

    SP_CELL_DECL (ex_mod_sub, sub[1]);

    /*AUTOSUBCELLS*/
    /*AUTODECLS*/
    /*AUTOSIGNAL*/

    //error test:
    //sc_signal<bool> in;

    SC_CTOR(__MODULE__);
};

#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
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
}

/*AUTOTRACE(__MODULE__)*/

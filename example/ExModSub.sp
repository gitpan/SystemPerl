// $Revision: #10 $$Date: 2003/09/22 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2003 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/
    void clock (void);

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) {
    SP_AUTO_CTOR;

    SC_METHOD(clock);
    sensitive_pos(clk);
}

void __MODULE__::clock (void) {
    SP_AUTO_COVER1("clocking");
    out.write(in.read());
    SP_AUTO_COVER();
}

/*AUTOTRACE(__MODULE__)*/

// $Revision: #12 $$Date: 2004/07/19 $$Author: ws150726 $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2004 by Wilson Snyder.  This program is free software;
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

    SP_AUTO_COVER(); // only once
}

void __MODULE__::clock (void) {
    SP_AUTO_COVER1("clocking");  // not in line report
    out.write(in.read());
    SP_AUTO_COVER();
}

/*AUTOTRACE(__MODULE__)*/

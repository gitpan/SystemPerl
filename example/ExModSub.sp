// $Id: ExModSub.sp 6132 2005-09-13 15:10:41Z wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <systemperl.h>
#include <iostream>
/*AUTOSUBCELL_CLASS*/

class MySigStruct {
public:
    SP_TRACED bool	m_in;
    SP_TRACED bool	m_out;
    sc_bv<72>		m_outbx;	// You can trace this, but a SC patch is required
    MySigStruct() {}
    MySigStruct(bool i, bool o, bool ob) : m_in(i), m_out(o), m_outbx(ob) {}
};
inline bool operator== (const MySigStruct &lhs, const MySigStruct &rhs) {
    return 0==memcmp(&lhs, &rhs, sizeof(lhs)); };
inline ostream& operator<< (ostream& lhs, const MySigStruct& rhs) {
    return lhs;}

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;
    sc_out<bool>	outbx;

    sc_signal<MySigStruct>  m_sigstr1;
    SP_TRACED MySigStruct   m_sigstr2;

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

SP_CTOR_IMP(__MODULE__) /*AUTOCTOR*/ {
    SP_AUTO_CTOR;

    SC_METHOD(clock);
    sensitive_pos(clk);

    SP_AUTO_COVER(); // only once

    // Other coverage scheme
    for (int i=0; i<3; i++) {
	static uint32_t coverValue = 100;
	SP_COVER_INSERT(&coverValue, "comment","Hello World",  "instance",i);
    }
}

void __MODULE__::clock (void) {
    SP_AUTO_COVER1("clocking");  // not in line report
    out.write(in.read());
    outbx.write(in.read());
    m_sigstr1.write(MySigStruct(in,out,outbx));
    m_sigstr2 = MySigStruct(in,out,outbx);
    SP_AUTO_COVER();
}

/*AUTOTRACE(__MODULE__)*/

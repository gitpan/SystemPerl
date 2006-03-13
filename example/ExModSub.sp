// $Id: ExModSub.sp 13576 2006-02-08 17:52:22Z wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2006 by Wilson Snyder.  This program is free software;
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
    sc_out<sp_ui<0,0> >	out;
    sc_out<bool>	outbx;

    sc_signal<MySigStruct>	m_sigstr1;
    SP_TRACED MySigStruct	m_sigstr2;

    sc_signal<sp_ui<96,5> >	m_sigstr3;	// becomes sc_bv
    SP_TRACED sp_ui<39,1>	m_sigstr4;	// becomes uint64_t
    SP_TRACED sp_ui<10,1>	m_sigstr5;	// becomes uint32_t

  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
    SP_AUTO_CTOR;

    SP_AUTO_COVER(); // only once

#sp ifdef NEVER
    // We ignore this
    SP_CELL(ignored,IGNORED_CELL);
    SP_PIN (ignored,ignore_pin,ignore_pin);
    /*AUTO_IGNORED_IF_OFF*/
# sp ifdef NEVER_ALSO
       SP_CELL(ignored2,IGNORED2_CELL);
# sp else
       SP_CELL(ignored3,IGNORED2_CELL);
# sp endif

#sp else

# sp ifdef NEVER_ALSO
    SP_CELL(ignored3,IGNORED3_CELL);
# sp else
    SP_AUTO_COVER();
# sp endif
#sp endif

#sp ifndef NEVER
    SP_AUTO_COVER();
#sp else
    SP_CELL(ifdefoff,IGNORED_CELL);
#sp endif

    // Other coverage scheme
    SP_AUTO_COVER_CMT("Commentary");
    if (0) SP_AUTO_COVER_CMT("Never_Occurs");
    if (0) SP_AUTO_COVER_CMT_IF("Not_Possible",0);
    SP_AUTO_COVER_CMT_IF("Always_Occurs",1||1);  // If was just '1' SP would short-circuit the eval
    for (int i=0; i<3; i++) {
	static uint32_t coverValue = 100;
	SP_COVER_INSERT(&coverValue, "comment","Hello World",  "instance",i);
    }
}

void __MODULE__::clock() {
    // Below will declare the SC_METHOD and sensitivity to the clock
    SP_AUTO_METHOD(clock, clk.pos());

    SP_AUTO_COVER1("clocking");  // not in line report
    out.write(in.read());
    outbx.write(in.read());
    m_sigstr1.write(MySigStruct(in,out,outbx));
    m_sigstr2 = MySigStruct(in,out,outbx);
    SP_AUTO_COVER();
}

/*AUTOTRACE(__MODULE__)*/

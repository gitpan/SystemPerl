// $Revision: #1 $$Date: 2002/08/19 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module for parser testing
// This module used for parsing testing, and isn't a good generic example

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

struct InhLower : public sc_module {
};

struct InhModule : public InhLower {
};

struct __MODULE__ : public InhModule {
    sc_in_clk		clk;		/* System Clock */

    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) {
}

#ifdef NEVER_JUST_CHECKING_PARSER
struct C14SdsSdtAgent::Display : unary_function<pair<SessionId,SessionInfo*>,void> {
};
struct Mismatch : public unary_function<const Record,unsigned> {
}
#endif

// This module used for parsing testing, and isn't a good generic example

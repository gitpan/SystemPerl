// $Id: test.sp,v 1.6 2001/04/03 17:08:04 wsnyder Exp $ -*- SystemC -*-
//=============================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2000, 2001 Nauticus Networks Inc.
// All Rights Reserved.
//
// This computer program is the property of Nauticus Networks and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of Nauticus Networks.
//
//=============================================================================
//
// AUTHOR:  Dan Lussier
//
// DESCRIPTION: Simple Test Bench for TTE Behavioral
//
//=============================================================================

#sp interface
#include "tte_struct.h"
#include "tte.h"
#include "pos_struct.h"
#include "pos_tx_bfm.h"

SC_MODULE (__MODULE__) {
//  sc_in_clk 			clk;
//  sc_in_clk 			dmc_clk;
//  sc_in_clk 			rnp_clk;
//  sc_in_clk 			dle_clk;
//  sc_in_clk 			smm_clk;

  // ========================================================================
  // Vectored Nets
  // ========================================================================

  sc_signal<bool>		rnpi_pad_clav[C14_POS_NUM_PRTS];	//  TTE can accept chunk for each PosQ.
  sc_signal<bool>		rnpo_pad_clav[C14_POS_NUM_PRTS];  	//  TTE has a chunk to send to RNP.
  sc_signal<bool>		dlei_pad_clav[C14_POS_NUM_PRTS];	//  TTE can accept chunk to PosQ[n].
  sc_signal<bool>		dleo_pad_clav[C14_POS_NUM_PRTS];  	//  TTE has a chunk from PosQ[n] to send to DLE.
  sc_signal<bool>		smmi_pad_clav[C14_POS_NUM_PRTS];	//  TTE can accept chunk to PosQ[n].
  sc_signal<bool>		smmo_pad_clav[C14_POS_NUM_PRTS];  	//  TTE has a chunk from PosQ[n] to send to SMM.

  // ========================================================================
  // Clocks
  // ========================================================================
  
  sc_clock 			clk;
  sc_clock 			dmc_clk;
  sc_clock 			rnp_clk;
  sc_clock 			dle_clk;
  sc_clock 			smm_clk;


  /*AUTOSUBCELLS*/
  
  /*AUTOSIGNAL*/


  // ========================================================================
  // Instantiate Components.
  // ========================================================================

    SC_CTOR(__MODULE__) {
	SP_CELL (tte0, tte);
	 for (int i=0;i<C14_POS_NUM_PRTS;i++) {
	     SP_PIN(tte0, rnpi_pad_clav[i], rnpi_pad_clav[i]);	
	     SP_PIN(tte0, rnpo_pad_clav[i], rnpo_pad_clav[i]);	
	     SP_PIN(tte0, dlei_pad_clav[i], dlei_pad_clav[i]);	
	     SP_PIN(tte0, dleo_pad_clav[i], dlei_pad_clav[i]);	
	     SP_PIN(tte0, smmi_pad_clav[i], smmi_pad_clav[i]);	
	     SP_PIN(tte0, smmo_pad_clav[i], smmi_pad_clav[i]);	
	 }
	 /*AUTOINST*/

	 SP_CELL (tx_bfm, pos_tx_bfm);
	  for (int i=0;i<C14_POS_NUM_PRTS;i++) {
	      SP_PIN(tx_bfm, pos_clav_in[i], rnpi_pad_clav[i]);	
	  }
	  SP_PIN(tx_bfm, pos_clk, rnp_clk);
	  SP_PIN(tx_bfm, pos_master, POS_SLAVE);		 		
	  SP_PIN(tx_bfm, pos_bus_width, POS_WIDTH_32BIT);		 	
	  SP_PIN(tx_bfm, pos_out, pad_rnpi_pos);	  
	  SP_PIN(tx_bfm, pos_out_strb, pad_rnpi_strb);
	  /*AUTOINST*/


	  // ========================================================================
	  // Define the Clocks
	  // ========================================================================
	  
	  clk = sc_clock("clk",1000/C14_CORE_CLK_FREQ);
	  dmc_clk = sc_clock("dmc_clk",1000/C14_SDDR_CLK_FREQ);
	  
	  // Generate each of the pos-phy clocks out of phase with one another
	  
	  rnp_clk = sc_clock("rnp_clk",1000/C14_POSPHY_CLK_FREQ, 0.5, 2, true);
	  dle_clk = sc_clock("dle_clk",1000/C14_POSPHY_CLK_FREQ, 0.5, 3, false);
	  smm_clk = sc_clock ("smm_clk",1000/C14_POSPHY_CLK_FREQ, 0.5, 5, true);
    }
};

#sp implementation


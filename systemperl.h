/* $Id: systemperl.h,v 1.2 2001/04/03 14:49:31 wsnyder Exp $
 ************************************************************************
 *
 * THIS MODULE IS PUBLICLY LICENSED
 *
 * This module contains free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this module; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 **********************************************************************
 * DESCRIPTION: SystemPerl: Overall header file
 **********************************************************************
 */

#ifndef _SYSTEMPERL_H
#define _SYSTEMPERL_H

/* Necessary includes */
#include <systemc.h>

/**********************************************************************/
/* Macros */

#define SP_CELL(instname,type) (instname = new type (# instname))
#define SP_PIN(instname,port,net) (instname->port(net))

/**********************************************************************/
/**********************************************************************/

#endif /*_SYSTEMPERL_H*/

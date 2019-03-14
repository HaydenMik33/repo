
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: anp.tcl,v 1.3 2000/08/08 19:27:29 karl Exp $
# $Log: anp.tcl,v $
# Revision 1.3  2000/08/08 19:27:29  karl
# Added global grab error windows.
#
# Revision 1.2  1999/08/23  23:02:50  karl
# Changed to accept more than one command-line parm.
#
# Revision 1.1  1998/12/11  20:59:41  karl
# Initial revision
#

#option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
#option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
#option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]
source $env(ASTK_DIR)/antkdialog.tcl


source $env(ASTK_DIR)/np.tcl
if {[llength $argv]>0} {
	eval open_note_pad . $argv
} else {
	open_note_pad . ""
}

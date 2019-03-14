
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: srve.tcl,v 1.5 2000/08/08 19:30:19 karl Exp $
# $Log: srve.tcl,v $
# Revision 1.5  2000/08/08 19:30:19  karl
# Added global grab error windows.
#
# Revision 1.4  2000/07/07  22:04:27  karl
# Added load of .aimcmds to handle CM checkout if necessary.
# Fixed bug caused by failure to open a file for editing.
#
# Revision 1.3  1999/02/22  20:03:51  karl
# Fixed to handle infile DV correctly with tcltksrv.
#
# Revision 1.2  1999/01/25  23:48:03  karl
# Fixed 'can't read "Log"' type error.
#
# Revision 1.1  1998/12/11  21:02:12  karl
# Initial revision
#

wm withdraw .
set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]
source $env(ASTK_DIR)/antkdialog.tcl
set options(appledit) graphical
set options(vibindings) 0

bind Text <Control-Key-x> "[bind Text <<Cut>>]"
bind Text <Control-Key-c> "[bind Text <<Copy>>]"
bind Text <Control-Key-v> "[bind Text <<Paste>>]"
bind Entry <Control-Key-x> "[bind Entry <<Cut>>]"
bind Entry <Control-Key-c> "[bind Entry <<Copy>>]"
bind Entry <Control-Key-v> "[bind Entry <<Paste>>]"

option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

if {[dv_get infile]!=""} {
        set infile [dv_get infile]
}

global env tcl_platform aci_comm_type
if {[info exists tcl_platform] && $tcl_platform(platform) == "windows"} {
    set aci_comm_type ACI
} else {
	# This is safe because on Unix platforms the build script adds it.
	if {$env(ACI_COMM_TYPE) == "ACI" } { 
    	set aci_comm_type ACI
	} else {
   		set aci_comm_type IPC
	}
}

ccm_load_menu_config .aimcmds ""

if {[info exists infile] && $infile!=""} {
	set osid  [open_server $infile]
} else {
	set osid  [open_server ""]
}
if {$osid!=""} {
	tkwait window .edit_suf$osid
}
exit

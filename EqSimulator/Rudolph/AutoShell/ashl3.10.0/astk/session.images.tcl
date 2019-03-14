
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: session.images.tcl,v 1.4 1999/06/02 17:37:21 karl Exp $
# $Log: session.images.tcl,v $
# Revision 1.4  1999/06/02 17:37:21  karl
# Added aim_struct
#
# Revision 1.3  1998/12/11  21:18:48  karl
# Added aim_erasers icon.
#
# Revision 1.2  1998/09/01  19:08:09  karl
# Added images for aim_shell, aim_strex, aim_eraser.
#
# Revision 1.1  1998/07/16  15:30:28  karl
# Initial revision
#
global env
image create photo aim_do -file $env(ASTK_DIR)/images/do.gif
image create photo aim_nodo -file $env(ASTK_DIR)/images/nodo.gif
image create photo aim_nofrtodo -file $env(ASTK_DIR)/images/nofrtodo.gif
image create photo aim_repeat -file $env(ASTK_DIR)/images/repeat.gif
image create photo aim_editrepeat -file $env(ASTK_DIR)/images/editrepeat.gif
image create photo aim_cmds2 -file $env(ASTK_DIR)/images/cmds2.gif
image create photo aim_cmds3 -file $env(ASTK_DIR)/images/cmds3.gif
image create photo aim_sfc -file $env(ASTK_DIR)/images/sfc.gif
image create photo aim_eqb -file $env(ASTK_DIR)/images/eqb.gif
image create photo aim_shell -file $env(ASTK_DIR)/images/shell.gif
image create photo aim_strex -file $env(ASTK_DIR)/images/strex.gif
image create photo aim_eraser -file $env(ASTK_DIR)/images/eraser.gif
image create photo aim_erasers -file $env(ASTK_DIR)/images/erasers.gif
image create photo aim_struct -file $env(ASTK_DIR)/images/struct.gif
image create photo aim_logs -file $env(ASTK_DIR)/images/logs.gif
image create photo aim_dvs -file $env(ASTK_DIR)/images/dvs.gif
image create photo aim_cmds -file $env(ASTK_DIR)/images/cmds.gif



# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: aim.images.tcl,v 1.7 1999/08/23 22:56:04 karl Exp $
# $Log: aim.images.tcl,v $
# Revision 1.7  1999/08/23 22:56:04  karl
# Added asjackt transparent gif.
#
# Revision 1.6  1999/06/02  17:34:02  karl
# Added icons aim_struct, aim_logs, aim_dvs, aim_cmds.
#
# Revision 1.5  1999/03/31  22:48:01  karl
# Added scrdicon.gif
#
# Revision 1.4  1998/12/18  17:08:53  karl
# Added easter egg images
#
# Revision 1.3  1998/12/11  19:15:31  karl
# Added config button icon.
#
# Revision 1.2  1998/09/01  18:48:17  karl
# Added images for aim_srvinfo, aim_quesinfo, aim_spectcl, aim_wb
#
# Revision 1.1  1998/07/16  15:31:39  karl
# Initial revision
#
global env
image create photo session -file $env(ASTK_DIR)/images/session.gif
image create photo refresh -file $env(ASTK_DIR)/images/refresh.gif
image create photo aim_sfc -file $env(ASTK_DIR)/images/sfc.gif
image create photo aim_eqb -file $env(ASTK_DIR)/images/eqb.gif
image create photo aim_text -file $env(ASTK_DIR)/images/text.gif
image create photo aim_srv -file $env(ASTK_DIR)/images/srv.gif
image create photo aim_asjacki -file $env(ASTK_DIR)/images/asjacki.gif
image create photo aim_srve -file $env(ASTK_DIR)/images/srve.gif
image create photo aim_nosrv -file $env(ASTK_DIR)/images/nosrv.gif
image create photo aim_killsrv -file $env(ASTK_DIR)/images/killsrv.gif
image create photo aim_queueinf -file $env(ASTK_DIR)/images/queueinf.gif
image create photo aim_noqueue -file $env(ASTK_DIR)/images/noqueue.gif
image create photo aim_procinfo -file $env(ASTK_DIR)/images/procinfo.gif
image create photo aim_queflush -file $env(ASTK_DIR)/images/queflush.gif
image create photo aim_srvinfo -file $env(ASTK_DIR)/images/srvinfo.gif
image create photo aim_quesinfo -file $env(ASTK_DIR)/images/quesinfo.gif
image create photo aim_spectcl -file $env(ASTK_DIR)/images/spectcl.gif
image create photo aim_wb -file $env(ASTK_DIR)/images/wb.gif
image create photo aim_scrd -file $env(ASTK_DIR)/images/scrdicon.gif
image create photo aim_listen -file $env(ASTK_DIR)/images/listen.gif
image create photo aim_acitest -file $env(ASTK_DIR)/images/acitest.gif
image create photo aimcfg -file $env(ASTK_DIR)/images/aimcfg.gif
image create photo asjackt -file $env(ASTK_DIR)/images/asjackt.gif
image create photo sfcsmi1 -file $env(ASTK_DIR)/images/sfcsmi1.gif
image create photo sfcsmi2 -file $env(ASTK_DIR)/images/sfcsmi2.gif
image create photo sfcsmi3 -file $env(ASTK_DIR)/images/sfcsmi3.gif
image create photo sfcsmi4 -file $env(ASTK_DIR)/images/sfcsmi4.gif
image create photo sfcsmi5 -file $env(ASTK_DIR)/images/sfcsmi5.gif
image create photo sfcsmi6 -file $env(ASTK_DIR)/images/sfcsmi6.gif
image create photo sfcsmi7 -file $env(ASTK_DIR)/images/sfcsmi7.gif
image create photo aim_struct -file $env(ASTK_DIR)/images/struct.gif
image create photo aim_logs -file $env(ASTK_DIR)/images/logs.gif
image create photo aim_dvs -file $env(ASTK_DIR)/images/dvs.gif
image create photo aim_cmds -file $env(ASTK_DIR)/images/cmds.gif
image create photo mq_step -file $env(ASTK_DIR)/images/mqhist_step.gif
image create photo dveditor -file $env(ASTK_DIR)/images/dveditor.gif

# $Id: mqtrace.tcl.in,v 1.1 2002/02/18 18:29:53 xsphcamp Exp $
# $Log: mqtrace.tcl.in,v $
# Revision 1.1  2002/02/18 18:29:53  xsphcamp
# Where appropriate: added auto-generation of version.tcl and tclIndex, and
# replacement of 3.3.1. This required the addition of
# build_tools/build_tclIndex.tcl. All the TK dev tools should now at least put up
# a window.
#
# I hereby declare this version 1.1.2 and suitable for personal use.
#
# Revision 1.2  2000/08/08 19:28:13  karl
# Added global grab error windows.
#
# Revision 1.1  1999/09/24  21:11:01  karl
# Initial revision
#

###########
#  MQTRACE 
# 
#  Author : Justin Tervooren
#  Date   : 08-1999
#     	
#  DESCRIPTION:
#	This program is for tracing Mqhist logs.
###########

###########
#  proc setupGUI
# 
#  VARIABLES:
#     	   env - Global Unix Env Var
#	    mq - Global MqTrace Data
#
#  DESCRIPTION:
#	Initial GUI, setup 
#
#	--------------------------
#       -		    -	 -	
#	-	   	    -	 -	
#	-	.f1	    - .f3-	
#	-	            -	 - 
#	-		    - 	 -
#	-                   -	 -
#	-		    - 	 -
#	--------------------------
#	-	   .f2		 -
#	-			 -
#	--------------------------
#
###########


set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]
source $env(ASTK_DIR)/antkdialog.tcl
source $env(ASTK_DIR)/version.tcl
source $env(ASTK_DIR)/ashlSupportEmail.tcl

#file delete jack

proc setupGUI {} {
   global env mq

   if {$mq(DEBUG)=="on"} {
      puts " in setupGUI\n"
   }


#   option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
#   option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
#  option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

   image create photo step -file $env(ASTK_DIR)/images/mqhist_step.gif
   image create photo server -file $env(ASTK_DIR)/images/mqt_server.gif
   image create photo srvbkpoint -file $env(ASTK_DIR)/images/mqt_bkpt.gif
   image create photo runsrvstop -file $env(ASTK_DIR)/images/mqt_stopsrv.gif
   image create photo splitscr -file $env(ASTK_DIR)/images/mqt_split.gif
   image create photo find -file $env(ASTK_DIR)/images/mqt_find.gif
   image create photo play -file $env(ASTK_DIR)/images/mqt_play.gif
   image create photo back -file $env(ASTK_DIR)/images/mqt_back.gif
   image create photo fwd -file $env(ASTK_DIR)/images/mqt_fwd.gif
   image create photo scanrng -file $env(ASTK_DIR)/images/mqt_scan.gif
   image create photo smfwd -file $env(ASTK_DIR)/images/mqt_smfwd.gif
   image create photo smbak -file $env(ASTK_DIR)/images/mqt_smbkwd.gif   
   image create photo opt -file $env(ASTK_DIR)/images/mqt_opt.gif
   image create photo rtime -file $env(ASTK_DIR)/images/mqt_realt.gif
   image create photo tail1 -file $env(ASTK_DIR)/images/mqt_tail.gif

   	
   wm title . "MQTrace"
#  wm minsize . 300 225
#  wm minsize . 470 355
   wm minsize . 470 355

   frame .main      
   frame .mbar     -relief raised -bd 2
   frame .f1       -relief raised -bd 5
   frame .f2       
   frame .f3
   frame .f3.direc

   menubutton .mbar.file -text File -underline 0 -menu .mbar.file.m 

   menu .mbar.file.m -tearoff 0

   .mbar.file.m   add command -label "Open MqHist File" -underline 0 \
                              -command {
					 global scrinfo
					 open_mqfile
				       }

   .mbar.file.m   add command -label "Close MqHist File"   -underline 0 \
                              -command close_mqfile -state disabled
   .mbar.file.m add separator

   .mbar.file.m   add command -label "Options"   -underline 0 \
                              -command mqt_options

   .mbar.file.m add separator 

   .mbar.file.m   add command -label "Exit"    -underline 1 \
                              -command "exit"

   menubutton .mbar.edit -text Edit -underline 0 -menu .mbar.edit.m 
   menu .mbar.edit.m -tearoff 0

   .mbar.edit.m add command -label "Step" -underline 0 \
                            -state disabled -command process_one_msg

   .mbar.edit.m add command -label "Run To Breakpoint" -underline 0 \
                            -state disabled -command  run_to_bkpt 

   .mbar.edit.m add command -label "Scan Log" -underline 0 \
                            -state disabled -command {     
							     global mq
  						             if {$mq(scanned)==0} {
								make_msg_list 
							     }	
							  }

   .mbar.edit.m add separator 

   .mbar.edit.m add command -label "Auto-Play" -underline 0 \
                            -state disabled -command {
							global mq
							set mq(auto) 1 
							auto_step
							
							 }

   .mbar.edit.m add command -label "Stop Auto-Play" -underline 0 \
                            -state disabled -command {
							global mq
							set mq(auto) 0
						       }

   .mbar.edit.m add command -label "Text/Graphical Mode" -underline 0 \
                            -state disabled 	-command { switch_mode }

   .mbar.edit.m add separator

   menubutton .mbar.srch -text "Find" -underline 0 -menu .mbar.srch.m 
   menu .mbar.srch.m -tearoff 0

   .mbar.srch.m add command -label "Find 1" -underline 0 

   menubutton .mbar.help -text Help  -underline 0 -menu .mbar.help.m 
   menu .mbar.help.m -tearoff 0
   .mbar.help.m   add command -label "About" -command aboutDLG

   canvas .f1.mcanvas1 -height 320 -width 400 -background white -closeenough 3.0

   scale .f1.scale1 -from 1 -to [expr $mq(msgtotal) +1] -showvalue 0 -variable mq(nextmsgnum) \
	-command {update_scale }

   if {$mq(msgtotal)>1} {
       .f1.scale1 configure -to $mq(msgtotal)
   }
 
   if {$mq(bottext)== 1} {
     text .f2.txt -width 80 -height 10
     scrollbar .f2.scroll1  -command ".f2.txt yview"
     .f2.txt configure -yscrollcommand ".f2.scroll1 set"

   }

   button .f3.direc.btn1a -text "Switch Trace Direction" -image smfwd -command { 
			   			  switch_direction
					  }

   button .f3.direc.btn1b -text "Switch Trace Direction" -image smbak -command { 
			   			  switch_direction
					  }



   button .f3.btn2 -text "Single Step" -image step -state disabled -command { 
		 					      process_one_msg
						            }

   button .f3.btn3 -text "Run To BreakPoint/Set BreakPoint" -state disabled -image srvbkpoint -command {
							      run_to_bkpt 
                                                            }	

   button .f3.btn4 -text "Auto-Play" -image play -state disabled -command {
							global mq
							set mq(auto) 1 
							auto_step
							
							 }

   button .f3.btn5 -text "Stop Auto-Play" -image runsrvstop -state disabled -command {
							global mq
							set mq(auto) 0
						       }

   button .f3.btn6 -text "Text Mode/Trace Mode" -state disabled -image splitscr -command { switch_mode }

   button .f3.btn7 -text "Find Text" -image find -state disabled -command { showFindDLG} 

   button .f3.btn8 -text "Scan Ring" -image scanrng -state disabled -command {     
							     global mq
  						             if {$mq(scanned)==0} {
								make_msg_list 
							     }	
							  }

   button .f3.btn9 -text "Hide Text Window" -image find  -command {
										   global mq
										   # puts "current=$mq(currentfiletext)"
										 }

   button .f3.btn10 -text "MqTrace Options" -image opt  -command { mqt_options }

   button .f3.btn11 -text "Real Time" -image rtime -state disabled  -command { global mq
							      	set xyval [winfo pointerxy .] 
                                				show_mode_menu $xyval
#							      start_mq_tail $mq(filename)
 							     }  

   entry .f3.currnum -width 3 -text  ## -textvariable mq(nextmsgnum) -justify center

   label .f3.of -text of 

   label .f3.totalnum -text ## -textvariable mq(msgtotal)

   menubutton .mbar.tools -text Tools -underline 0 -menu .mbar.tools.t

   menu .mbar.tools.t -tearoff 0

   .mbar.tools.t add command -label "Resend msgs" -underline 0 \
            		 		 -command { mqt_resend_select
                   			          }

   .mbar.tools.t add command -label "Stop resend msgs" -underline 0 \
          	 -state disabled \
			 -command { global mq
                set mq(resend) 0
                set mq(resendto) ""
                set mq(resendfr) ""
                .mbar.tools.t entryconfigure "Resend msgs" -state active
                .mbar.tools.t entryconfigure "Stop resend msgs" -state disabled
                }

   pack .mbar.file   -side left
   pack .mbar.edit   -side left
   pack .mbar.help   -side right
   pack .mbar.tools  -side left
   pack .mbar        -fill x
   pack .f1.mcanvas1 -side left -expand 1 -fill both
   pack .f1.scale1 -side left -fill y

   pack .f3.direc.btn1b -side left -padx 0
   pack .f3.direc.btn1a -side left -padx 0
   pack .f3.direc -side top 
   pack .f3.btn2 -side top
   pack .f3.btn3 -side top 
   pack .f3.btn8 -side top
   pack .f3.btn4 -side top
   pack .f3.btn5 -side top
#   pack .f3.btn9 -side top
   pack .f3.btn6 -side top
   pack .f3.btn11 -side top
   pack .f3.btn7 -side top
   pack .f3.btn10 -side top
   pack .f3.currnum -side top
#   pack .f3.of -side top
#   pack .f3.totalnum -side top

   pack .f1 -side left -in .main -expand 1 -fill both
   pack .f3 -side left -in .main -fill y

   pack .main -expand 1 -fill both
   if {$mq(bottext)==1} {
     pack .f2.txt -side left -in .f2 -expand 1 -fill both
     pack .f2.scroll1 -side left -in .f2 -fill y
     pack .f2 -expand 1 -fill both
   }

   bind .f1.mcanvas1 <Configure> "display_servers; 
				  set mq(centersrv) \"\"
				 "		
   bind .f3.btn3 <3> {
				set xyval [winfo pointerxy .] 
				show_bkpt_menu $xyval
			    }

   bind .f3.currnum <Return> {
				draw_line 1
				draw_line -1						 						 
				focus .f1.mcanvas1
			     }	

   bind . <Return> { process_one_msg }
}

###########
#  proc open_mqfile
# 
#  VARIABLES:
#     	
#  DESCRIPTION:
#	Opens file for tracing
###########
proc open_mqfile {} {
	global env mq

	if {$mq(DEBUG)=="on"} {
	  puts " in open_mqfile \n"
	}

#	newfileselect open -patt {{{Script File} *.log}}

	set filename [newfileselect . open -patt {{{Log File} *.*}}]
        
# 	Exit if use presses cancel
        if {$filename==""} {
           return
        }

        set mq(filename) $filename

        wm title . "MQTrace - $filename"

        .mbar.file.m entryconfigure "Open MqHist File" -state disabled
        .mbar.file.m entryconfigure "Close MqHist File" -state active

	.mbar.edit.m entryconfigure "Step" -state normal
        .mbar.edit.m entryconfigure "Run To Breakpoint" -state normal
        .mbar.edit.m entryconfigure "Scan Log" -state normal
        .mbar.edit.m entryconfigure "Auto-Play" -state normal
        .mbar.edit.m entryconfigure "Stop Auto-Play" -state normal
        .mbar.edit.m entryconfigure "Text/Graphical Mode" -state normal

        .f3.btn2 configure -state normal
        .f3.btn3 configure -state normal
        .f3.btn4 configure -state normal
        .f3.btn5 configure -state normal
        .f3.btn6 configure -state normal
        .f3.btn8 configure -state normal
#       .f3.btn9 configure -state normal
	.f3.btn11 configure -state normal

 
#	set FILE [open $filename]
#        set filetext [read $FILE]
#       set mq(filetext) $filetext
#        set mq(currentfiletext) $filetext
	set mq(auto) 0
	set x [start_mq_tail $filename]
        while {[gets $mq(filep) linebuf]> -1 } {
                  set linebuf [append linebuf "\n"]
                  set mq(currentfiletext) [append mq(currentfiletext) $linebuf]
         }
        set mq(filetext) $mq(currentfiletext)

	mq_tailfile_stop $filename $mq(filep) 
	set mq(auto) 0
	set mq(tail) 0

# Initilize scanned variable
        set mq(scanned) 0
        .f3.direc.btn1a configure -state disabled
        .f3.direc.btn1b configure -state active
        set mq(direction) 1
        process_one_msg
}

proc close_mqfile {} {
	global env mq

        if {$mq(DEBUG)=="on"} {
          puts " in close_mqfile\n"
        }
# Make sure we are in graphical mode
        if {$mq(viewmode)=="text"} {
 		switch_mode
	}

	mq_tailfile_stop $mq(filename) $mq(filep) 

	set filename ""

        wm title . "MQTrace"

        .mbar.file.m entryconfigure "Open MqHist File" -state active
        .mbar.file.m entryconfigure "Close MqHist File" -state disabled

	.mbar.edit.m entryconfigure "Step" -state disabled
        .mbar.edit.m entryconfigure "Run To Breakpoint" -state disabled
        .mbar.edit.m entryconfigure "Scan Log" -state disabled
        .mbar.edit.m entryconfigure "Auto-Play" -state disabled
        .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
        .mbar.edit.m entryconfigure "Text/Graphical Mode" -state disabled

        .f3.btn2 configure -state disabled
        .f3.btn3 configure -state disabled
        .f3.btn4 configure -state disabled
        .f3.btn5 configure -state disabled
        .f3.btn6 configure -state disabled
        .f3.btn8 configure -state disabled
#        .f3.btn9 configure -state disabled
	.f3.btn11 configure -state disabled
        set mq(filetext) ""
        set mq(currentfiletext) ""

        set mq(scanned) 0
        set ct -1

        while {$ct<$mq(msgtotal)} {
   	  set mq(msg,$ct) ""
	  set ct [expr $ct + 1]
        }
          
	set mq(msgtotal) 0
	set mq(bkpt,nonzero) 0
	set mq(bkpt,sender) 0
	set mq(bkpt,receive) 0
 	set mq(bkpt,user) 0
	set mq(srvlist) [list]
	set mq(centersrv) ""						
	set mq(centersrvnew) ""						
	set mq(nextmsgnum) 0
	set mq(msg,0) ""

        catch {
	        .f2.txt delete 0.0 end
	      }	

 	.f3.direc.btn1a configure -state disabled
 	.f3.direc.btn1b configure -state active
        set mq(direction) 1
        .f1.mcanvas1 delete all
        .f1.scale1 configure -to [expr $mq(msgtotal) + 1] -from 1
	close $mq(filep) 

   
}


###########
#  proc display_servers
# 
#  VARIABLES:
#     	
#  DESCRIPTION:
#	Displays Server Names found in log
###########
proc display_servers {} {
	global mq    
        if {$mq(DEBUG)=="on"} {
          puts " in display_servers\n"
        }

	
        set mq(locdata) [list]
	# Clear canvas before drawing/redrawing servers
        .f1.mcanvas1 delete all
        set canvx [winfo width  .f1.mcanvas1]
        set canvy [winfo height .f1.mcanvas1]

	set xo [expr $canvx / 2]
	set yo [expr $canvy / 2]

	set rad [expr $canvy * .35]
	set rad [expr round($rad)]
	set innerrad [expr $rad - 20]

        set ct 0

 catch {
        set maxsrv [llength $mq(srvlist)] 
        set deg [expr 360 / $maxsrv]
       
	foreach server $mq(srvlist) {

	  if {[info exist mq(ovalcolor,$server)]==0} {
            set mq(ovalcolor,$server) grey95
          }

          set coor [expr $deg * $ct]
	  set coor [expr $coor + 270]

          set coor [expr $coor * 3.14159]
	  set coor [expr $coor / 180]

          set y [expr sin($coor)] 
          set x [expr cos($coor)] 

          set y [expr $y * $rad] 
          set x [expr $x * $rad] 
#####
##### TEST INNER CIRCLE CONCEPT
          set y2 [expr sin($coor)] 
          set x2 [expr cos($coor)] 

          set y2 [expr $y2 * $innerrad] 
          set x2 [expr $x2 * $innerrad] 
          set y2 [expr $y2 + $yo] 
          set x2 [expr $x2 + $xo] 
####

          set y [expr $y + $yo] 
          set x [expr $x + $xo] 

 	  set ovaltag [.f1.mcanvas1 create oval [expr $x - 20] [expr $y - 15] [expr $x + 20] [expr $y + 15] -outline white -fill grey95]
# 	  set imgtag [.f1.mcanvas1 create image $x $y -image server -anchor center]
 	  set imgtag [.f1.mcanvas1 create image $x [expr $y +13] -image server -anchor center]
#	  set labeltag [.f1.mcanvas1 create text [expr $x - 3] [expr $y - 20] -text $server -justify center -font "-*-Courier-Medium-R-Normal--*-100-*-*-*-*-*-*"]
	  set labeltag [.f1.mcanvas1 create text $x [expr $y - 0] -text $server -justify center -font "-*-Courier-Medium-R-Normal--*-100-*-*-*-*-*-*"]
 
          set tmplist [list $server $x $y $imgtag $labeltag $ovaltag $x2 $y2]
#         set tmplist [list $server $x $y 99 $labeltag]
          set mq(locdata) [lappend mq(locdata) $tmplist]
           
          set ct [expr $ct + 1]
 	  .f1.mcanvas1 bind $ovaltag <Double-Button-1> "talk_session $server" 
 	  .f1.mcanvas1 bind $imgtag <Double-Button-1> "talk_session $server" 
 	  .f1.mcanvas1 bind $labeltag <Double-Button-1> "talk_session $server" 
	  .f1.mcanvas1 bind $ovaltag <Double-Button-3> " 
							set mq(centersrvnew) \"$tmplist\";
							center_server;
 						        draw_line -1;
  	 						draw_line 1

						       "
	  .f1.mcanvas1 bind $imgtag <Double-Button-3> " 
							set mq(centersrvnew) \"$tmplist\";
							center_server;
 						        draw_line -1;
  	 						draw_line 1

						       "
	  .f1.mcanvas1 bind $labeltag <Double-Button-3> " 
							set mq(centersrvnew) \"$tmplist\";
							center_server;
 						        draw_line -1;
  	 						draw_line 1

						       "


	  
#          set mq(ovalcolor,$server) white
	}
      }
	update idletasks
        catch { draw_line 1 }  	
}

proc center_server {} {
        global mq 

        if {$mq(DEBUG)=="on"} {
          puts " in centerserver\n"
        }

        if {$mq(centersrv)=="" && $mq(centersrvnew)!=""	} {
	  set taglist $mq(centersrvnew)	
          set canvx [winfo width  .f1.mcanvas1]
          set canvy [winfo height .f1.mcanvas1]

  	  set xo [expr $canvx / 2]
	  set yo [expr $canvy / 2]
      
          set ovaltag [.f1.mcanvas1 create oval [expr $xo - 20] [expr $yo - 15] [expr $xo + 20] [expr $yo + 15] -outline white -fill grey95]
          set imgtag [.f1.mcanvas1 create image $xo [expr $yo +13] -image server -anchor center]
          set labeltag [.f1.mcanvas1 create text $xo [expr $yo - 0] -text [lindex $taglist 0] -justify center -font "-*-Courier-Medium-R-Normal--*-100-*-*-*-*-*-*"]
          set tmplist [list [lindex $taglist 0] $xo $yo $imgtag $labeltag $ovaltag]
          set CT 0 
          set repmark -1

          foreach item $mq(locdata) {
	    if {[lindex $item 0]==[lindex $taglist 0]} {
               set repmark $CT
            }
            set CT [expr $CT +1]
          }      
	
          if {$repmark!=-1} {

            set mq(centersrv) $tmplist
            set mq(centersrvold) [lindex $mq(locdata) $repmark]

	    .f1.mcanvas1 delete [lindex $mq(centersrvold) 3]          
	    .f1.mcanvas1 delete [lindex $mq(centersrvold) 4]	 
	    .f1.mcanvas1 delete [lindex $mq(centersrvold) 5]
            .f1.mcanvas1 delete $mq(currlinetag)
            catch {
#  		    display_servers
		    draw_line -1
		    draw_line 1

                  } 

            set mq(locdata) [lreplace $mq(locdata) $repmark $repmark $tmplist]

   	    .f1.mcanvas1 bind $ovaltag <Double-Button-1> "talk_session [lindex $taglist 0]" 
 	    .f1.mcanvas1 bind $imgtag <Double-Button-1> "talk_session [lindex $taglist 0]" 
 	    .f1.mcanvas1 bind $labeltag <Double-Button-1> "talk_session [lindex $taglist 0]" 

  	    .f1.mcanvas1 bind $ovaltag <Double-Button-3> {
  	  						set mq(centersrv) ""
							set mq(centersrvnew) ""
							display_servers
						        draw_line -1
						       }          
        
  	    .f1.mcanvas1 bind $labeltag <Double-Button-3> {
							set mq(centersrv) ""
							set mq(centersrvnew) ""
							display_servers
						        draw_line -1
						       }  

  	    .f1.mcanvas1 bind $imgtag <Double-Button-3> {
							set mq(centersrv) ""
							set mq(centersrvnew) ""
							display_servers
						        draw_line -1
						       }          
	}   

     }       
}

proc draw_line {ctchange} {
	global mq sml_msg tcl_platform
        if {$mq(DEBUG)=="on"} {
          puts " in draw_line\n"
        }
	#   Clear Text box and remove any previous lines....Catch if non existant
        catch {
	        .f2.txt delete 0.0 end
	      }	
        catch {
		.f1.mcanvas1 delete $mq(currlinetag)
		.f1.mcanvas1 delete $mq(currlinetag,arrow)
	}
        catch {
		.f1.mcanvas1 delete $mq(commtag)
	}


	# Get from and to tags to know what servers to draw the line to 
        set mq(nextmsgnum) [expr $mq(nextmsgnum) + $ctchange]

        set messagetmp $mq(msg,$mq(nextmsgnum))
	set message $mq(msg,$mq(nextmsgnum))

	set secs_msg 0
	if {[string first "0x0000:" $message]!=-1} {
	 	catch {	
          		#.f2.txt insert end $sml_msg
			.f2.txt insert end $mq(secs,$mq(nextmsgnum))
		}
		set secs_msg 1
		set filetext $message
		set line [string range $filetext 0 [string first "\n"  $filetext]]	
		while {$line!=""} {
			#next line
			set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
			set line [string range $filetext 0 [string first "\n"  $filetext]]
			#nks
			if { [string range $line 0 9] == "     FROM:"} {
				regexp {     FROM: +(\S+)} $line var1 var2
				if { [string range $var2 0 4] == "ashl."} {
					set var2 [string range $var2 5 [string length $var2] ]	
				}
				set firstwd $var2
			}
			if { [string range $line 0 9] == "       TO:"} {
				regexp {       TO: +(\S+)} $line var1 var2
				if { [string range $var2 0 4] == "ashl."} {
					set var2 [string range $var2 5 [string length $var2] ]	
				}
				set secondwd $var2
			}
		}
			
	} else {
					#set fileId [open jack a+ 0666]
                                        #puts $fileId draw_line_line=$message
                                        #close $fileId

		if {([string first "hexdump=" $message] >= 0) } {
			catch {
                        	#.f2.txt insert end $sml_msg
                        	.f2.txt insert end $mq(secs,$mq(nextmsgnum))
			}
			set secs_msg 1
                }

   		if {[string first "fr=" $messagetmp]==-1} {
         	# added jmt 9/24/99
			return 	
  	         	set ct [expr $mq(nextmsgnum) + $ctchange]
                 	if {$ct>$mq(msgtotal)} {
		   		process_one_msg
	 	 	}             
	         	draw_line $ctchange 
		 	return
        	}
		set line  [string range $messagetmp 0 [expr [string first "\n" $messagetmp] +1]]
		while {[string first "fr=" $line]==-1 && $line!=""} {
          		set messagetmp [string range $messagetmp [expr [string first "\n" $messagetmp] +1] end]
	  		set line  [string range $messagetmp 0 [expr [string first "\n" $messagetmp] +1]]
		}
        	set firstwd [string range $messagetmp 0 [expr [string first " " $messagetmp] -1] ] 
        	set messagetmp [string range $messagetmp [expr [string first " " $messagetmp]+1] end]
        	set secondwd [string range $messagetmp 0 [expr [string first " " $messagetmp] -1] ] 
        	set firstwd [string trim $firstwd]    
        	set firstwd [string range $firstwd 3 end]
        	set secondwd [string range $secondwd 3 end] 
	}
        foreach item $mq(locdata) {   
		
	   if {[string compare [lindex $item 0] $firstwd]==0} {
#               set frx [lindex $item 1]
#               set fry [lindex $item 2]
                set frx [lindex $item 6]
                set fry [lindex $item 7]
                set frxorg [lindex $item 1]
                set fryorg [lindex $item 2]

               set frname [lindex $item 5]
               set frsrvname [lindex $item 0]
            } 
        	 
            if {[string compare [lindex $item 0] $secondwd]==0} {
#               set tox [lindex $item 1]
#               set toy [lindex $item 2]
                set tox [lindex $item 6]
                set toy [lindex $item 7]
                set toxorg [lindex $item 1]
                set toyorg [lindex $item 2]

               set toname [lindex $item 5]
               set tosrvname [lindex $item 0]
    	    }   
            .f1.mcanvas1 itemconfigure [lindex $item  5] -fill grey95
        }


	
        # Check for Internal command      
        if {$frname==$toname} {
			
           set mq(currlinetag)  [.f1.mcanvas1 create oval [expr $frxorg - 25] [expr $fryorg - 20] [expr $frxorg + 25] [expr $fryorg + 20] -outline black -width 2.0]
           set mq(currlinetag,arrow) [.f1.mcanvas1 create line [expr $frxorg +5 ] [expr $fryorg - 20] [expr $frxorg +6] [expr $fryorg - 20] -arrow last -width 2.0 -arrowshape {8 10 5} -fill black]
 	    set msgtemp $message	    
 	    set msgtemp [string range $msgtemp [string first "command=" $msgtemp] end]
 	    set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    set smallpmpt $msgtemp
        } else {
			
  	  set x [expr $frx - $tox]
	  set y [expr $fry - $toy]

	  set x1 [expr $x * $x]
	  set y1 [expr $y * $y]
	  set xy1 [expr  $x1 + $y1 ]
	  set z [expr sqrt($xy1)]
 
          set A [expr asin([expr $x / $z])] 

          set finalx1 [expr [expr $z-18]/[expr sin($A)]]
	
	  set finaly2 [expr [expr [expr $z- 20] * [expr $z-20]] - [expr $finalx1 * $finalx1]]
	  set finaly2 [expr sqrt([expr abs($finaly2)])]
	  set finaly2 [expr $finaly2 * -1]
#  	  set toy [expr $toy - $finaly2]
#	  set tox [expr $tox - $finalx1]
          set z1 [expr $z -18]
          set z2 [expr $z -18]
	  set LINE 0  
  	  # SET ERROR MESSAGES COLOR RED
          if {[string first "reply=" $message]!=-1 && $LINE==0} {
            set replymsg [string range $message [string first "reply=" $message] end]
            set replymsg [string range $replymsg 0 [expr [string first " " $replymsg] -1 ] ]
 	    set replymsg [string range $replymsg 6 end]        
	    if {$replymsg!=0} {
              set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill red]
	      set LINE 1
	    }
 	    set msgtemp $message	    
 	    set msgtemp [string range $msgtemp [string first "reply=" $msgtemp] end]
 	    set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    set smallpmpt $msgtemp
          }


 	  # SET ALL COMMAND MESSAGES COLOR BLUE
          if {[string first "do=" $message]!=-1 && $LINE==0} {
            set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill blue ]
            set mq(ovalcolor,$tosrvname) lightgreen
            set mq(ovalcolor,$frsrvname) cyan
            set LINE 1
 	    set msgtemp $message	    
 	    set msgtemp [string range $msgtemp [string first "do=" $msgtemp] end]
 	    set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    set smallpmpt $msgtemp
          } 

  	 # SET ALL REPLY MESSAGES COLOR GREEN
         if {[string first "reply=" $message]!=-1 && $LINE==0} {
            set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill darkgreen]
            set LINE 1
 	    set msgtemp $message	    
 	    set msgtemp [string range $msgtemp [string first "command=" $msgtemp] end]
 	    set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    set smallpmpt $msgtemp

         } 
	#SET all secs message to Orange
	 if {$secs_msg==1} {
            set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill orange ]
            set mq(ovalcolor,$tosrvname)  pink
	    set mq(ovalcolor,$frsrvname) cyan
            set LINE 1
 	    set msgtemp $message

	    if { $tcl_platform(platform) != "windows"} {
	    	regexp {fr=\S+} $msgtemp smallpmpt
    	    } else {		
 	    	set msgtemp [string range $msgtemp [string first "do=" $msgtemp] end]
 	    	set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    	set smallpmpt $msgtemp
	    }
          } 
	
	 
	  # SET ALL DATA MESSAGES COLOR YELLOW
          if {$LINE==0} {
            set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill yellow]
            set LINE 1
            set msgtemp $message	    
 	    set msgtemp [string range $msgtemp [string first "command=" $msgtemp] end]
 	    set msgtemp [string range $msgtemp 0  [string first " " $msgtemp]]
	    set smallpmpt $msgtemp
	  } 

          .f1.mcanvas1 itemconfigure $frname -fill $mq(ovalcolor,$frsrvname)
          .f1.mcanvas1 itemconfigure $toname -fill $mq(ovalcolor,$tosrvname)
#         set mq(currlinetag) [.f1.mcanvas1 create line $frx $fry $tox $toy -arrow last -width 2.0 -arrowshape {8 10 5} -fill black]


        if { [array get mq resend]!="" && $mq(resend)==1} {
            resend $message
        }

        }  


### Label Test

 	   set cany [expr [winfo height .f1.mcanvas1] - 23]

          set canx [winfo width .f1.mcanvas1]
          set canx [expr $canx / 2]
	
#          set midx [expr [expr $frx + $tox] / 2 ]
#          set midy [expr [expr $fry + $toy] / 2 ]
#  	  puts "midx=$midx midy=$midy"
  	if {$mq(canvcommand)==1} {
	  set mq(commtag) [.f1.mcanvas1 create text $canx $cany -text $smallpmpt  -justify left -font "-*-Courier-Medium-R-Normal--*-100"]
        }
##
# Catch if textbox is turned off
#
        catch {
          .f2.txt insert end $message
 	}
	set esc_message $message
        # Escape all escapes
        regsub -all {\\} $esc_message "\\\\" esc_message
        # Escape all embedded quotes.
        regsub -all {\"} $esc_message "\\\"" esc_message
        regsub -all {\$} $esc_message "\$" esc_message
        # Catch 
	catch {
	   .f1.mcanvas1 bind $mq(currlinetag) <Enter> "balloon_pend \"$esc_message\" $mq(currlinetag)" 
	}


	.f1.mcanvas1 bind $mq(currlinetag) <Leave> "balloon_cancel"

        set mq(currentsrvs) [list $frname $toname]	
}

proc process_one_msg {} {

      global mq sml_msg tcl_platform
      	set sml_msg ""

        if {$mq(DEBUG)=="on"} {
          puts " in process_one_msg\n"
        }


      if {$mq(nextmsgnum)<$mq(msgtotal) ||  $mq(direction)==-1} {

	if  {$mq(nextmsgnum)==$mq(msgtotal) && $mq(direction)==-1} {
	     draw_line -1
        return	
	}

        if {$mq(nextmsgnum)>=1 && $mq(nextmsgnum)<$mq(msgtotal)} {
 	     if {$mq(direction)!=-1 &&  $mq(nextmsgnum)>1} {
	       draw_line $mq(direction)
	     } else {
	       draw_line $mq(direction)
  	     }						
        }
      } else { 

#       if {$mq(nextmsgnum)>=$mq(msgtotal) && $mq(scanned)==0} {}
       if {$mq(nextmsgnum)>=$mq(msgtotal)} {
 
	set srvlist $mq(srvlist)
        set filetext $mq(currentfiletext) 
        set line [string range $filetext 0 [string first "\n"  $filetext]]
        set message ""
	set first10 ""
	set first3 ""
	if { $tcl_platform(platform) == "windows" } {
		set prev $line	
        	set line [string range $filetext 0 [string first "\n"  $filetext]]
        	set first10 [string range $line 0 9]
	} else {
		if { ([string first "---------" $line ] == -1) && ([string first "========" $line] == -1) } {
			set prev $line
		} else {
        		set prev ""
	}
       	set line [string range $filetext 0 [string first "\n"  $filetext]]
	set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
       	set first3 [string range $line 0 2]
      	}	
 	set FLAG 0
	set secsmsg 0
        while {$line!="" && $FLAG!=1} {
           
 	  if {([string first "non-AutoNet"  $prev]!=-1) && ($tcl_platform(platform) == "windows")}  {           
             set line [string range $filetext 0 [string first "\n"  $filetext]]
 	     set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
          }
           
          
          if {($first3=="fr=" ) || ($first10=="----------")} {
 	    set message $prev
	    set FLAG 0	
	    while {$FLAG!=1} {
 	           set message [append message $line]
	   	   if {$tcl_platform(platform) == "windows" } {
	           	set line [string range $filetext 0 [string first "\n"  $filetext]]
	           	set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
 	           	set first10 [string range $line 0 9]
		   }
		   set frto [string first "fr=" $line]
			
		   # if a server comm line get srv values to check......
		   if {$frto!=-1} {	
		     set frtag [string range $line [string first "fr=" $line] end]
		     set firstwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set frtag [string range $frtag [expr [string first " " $frtag] +1] end]
		     set secondwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set firstwd [string range $firstwd 3 end]
		     set secondwd [string range $secondwd 3 end]
			
	             if {[lsearch $srvlist $firstwd]==-1} {
 	 	            set srvlist [lappend srvlist $firstwd]
		     }

          	     if {[lsearch $srvlist $secondwd]==-1} {
              		    set srvlist [lappend srvlist $secondwd]
		     }	
			if { ([string first "hexdump=" $line] != -1) } {
				set secsmsg [string range $line [expr [string first "hexdump=" $line] + 8] end]
			}	
			

           	   }
		   if {$tcl_platform(platform) != "windows" } {
		   	set line [string range $filetext 0 [string first "\n"  $filetext]]
                   	set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]

                   	set first10 [string range $line 0 9]
		   }
		   if {($first10=="----------") || ($first10=="==========")}  {
 	             set message [append message $line]
		     set FLAG 1    			     				 			
		     set mq(msgtotal) [expr $mq(msgtotal) +1]
		     set mq(msg,$mq(msgtotal)) $message
		     break
		   }
	    }	
 
          } 
		
      	  
	  set first8 [string range $line 0 7]
	  if {$tcl_platform(platform) != "windows"} {
	  	set first10 [string range $line 0 9]
    	  }
  			
      	  if {($first8==" SENDING") || ($first10==" RECEIVING") } {
	  #if {$first10=="=========="} {}
  	    set message $prev	
 	    if {[string first "non-AutoNet"  $prev]!=-1} {           
             set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
             set line [string range $filetext 0 [string first "\n"  $filetext]]
 	     set mq(currentfiletext) $filetext
             process_one_msg 	     
	     return
            }


	    set FLAG 0	
	    set secsmsg 0
	    set secsflag 0
	    while {$FLAG!=1} {


 	           set message [append message $line]
	   		#nks
	   			
	   		if { [string compare -length 10 $line "   0x0000:"] == 0} {
				set temp_line $line
				set temp_line [string range $temp_line 11 58]
				set temp_line "$temp_line\n"
	       			set secsmsg $temp_line
				set secsflag 1	

				
			} elseif {$secsflag == 1} {
				set temp_line $line
				set temp_line [string range $temp_line 11 58]
				set secsmsg [append secsmsg $temp_line]

			}
		       			
	   		
	           set line [string range $filetext 0 [string first "\n"  $filetext]]
		 
	           set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
 	           set first10 [string range $line 0 9]
		   set frto [string first "fr=" $line]
		
		   #nks secs msg to add to srvlist
	   	   if { [string range $line 0 9] == "     FROM:"} {
				regexp {     FROM: +(\S+)} $line var1 var2
				if {[string range $var2 0 4] == "ashl."} {
					set var2 [string range $var2 5 [string length $var2] ]		
				}
			       	if {[lsearch $srvlist $var2]==-1} {
 	 	            		set srvlist [lappend srvlist $var2]
		     		}
		   }
		   if { [string range $line 0 9] == "       TO:"} {
				regexp {       TO: +(\S+)} $line var1 var2
				if {[string range $var2 0 4] == "ashl."} {
					set var2 [string range $var2 5 [string length $var2] ]	
				}
				if {[lsearch $srvlist $var2]==-1} {
 	 	            		set srvlist [lappend srvlist $var2]
		     		}
		   }
				
  		   # if a server comm line get srv values to check......
		   if {$frto!=-1} {	
		     set frtag [string range $line [string first "fr=" $line] end]
                     set firstwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set frtag [string range $frtag [expr [string first " " $frtag] +1] end]
                     set secondwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set firstwd [string range $firstwd 3 end]
		     set secondwd [string range $secondwd 3 end]
	             if {[lsearch $srvlist $firstwd]==-1} {
 	 	            set srvlist [lappend srvlist $firstwd]
		     }

          	     if {[lsearch $srvlist $secondwd]==-1} {
              		    set srvlist [lappend srvlist $secondwd]
		     }	
           	   }

		   if {$first10=="=========="} {
 	             set message [append message $line]
		     set FLAG 1 
		     set mq(msgtotal) [expr $mq(msgtotal) +1]
		     set mq(msg,$mq(msgtotal)) $message
		     break
		   }
	    }	
 
          } 
        # Move on to next Line
        set prev $line	
  	  if {$FLAG!=1} {    	
            set line [string range $filetext 0 [string first "\n"  $filetext]]
            set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
	    if {$tcl_platform(platform) == "windows" } {
		set first10 [string range $line 0 9] 
    	    } else {
            	set first3 [string range $line 0 2]
	    }
	  }	
        }
        set mq(currentfiletext) $filetext

	#parse the secsmsg
	if {$secsmsg != 0} {
		#strip new line and carriage returns
		regsub {[\n\r]} $secsmsg {} secsmsg

		if {$tcl_platform(platform) == "windows" } {
			#strip blank spaces at the end 
			regsub {\s*$} $secsmsg {} secsmsg
			set secs_header [string range $secsmsg 0 28]
       			set secs_body [string range $secsmsg 30 end]
			set secs_stream [string range $secs_header 6 7] 
		} else {
			set secs_header [string range $secsmsg 0 19]
       			set secs_body [string range $secsmsg 20 end]
			set secs_stream [string range $secs_header 4 5]
	        }	
		#convert to binary
		set secs_stream [val2Bin 0x$secs_stream]
		#strip the left bit
		set secs_stream [string range $secs_stream 1 end]
		set secs_stream [bin2dec $secs_stream]	
		if {$tcl_platform(platform) == "windows"} {
			set secs_function [string range $secs_header 9 10]
		} else {
			set secs_function [string range $secs_header 6 7]
		}
		scan $secs_function %x secs_function
		set secs_function

		set secs_sxid [string range $secs_header 0 4]
		regsub {[ ]} $secs_sxid {} secs_sxid
		
		#convert to binary
		set secs_sxid [val2Bin 0x[string range $secs_sxid 0 1 ]][val2Bin 0x[string range $secs_sxid 2 3]]
		#strip the left most bit
		set secs_sxid [string range $secs_sxid 1 end]
		if {[string compare $secs_sxid "000000000000000"] == 0} {
			set secs_sxid 0
		} else {
			#convert to dec
			set secs_sxid [bin2dec $secs_sxid]
		}

		set parsed_data  ""
		#parse the secs_body
		if { $secs_body != ""} {
			regsub -all { } $secs_body {} secs_body 
			while {$secs_body != ""} {
				#convert hex to bin
				set block_bin [val2Bin 0x[string range $secs_body 0 1] ]
				set secs_body [string range $secs_body 2 end]

				set type [find_type [string range $block_bin 0 5] ]
				set length [string range $block_bin 6 7]
					
				set length [bin2dec $length]
				if { $type == "LIST" } {
					set block [string range $secs_body 0 1 ]
					set secs_body [string range $secs_body 2 end]
					#convert hex to dec.
					scan $block %x secs_length
					set secs_length
					lappend parsed_data "LIST $secs_length" 
					
				} elseif { $type == "ASC"} {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec.
					scan $block %x secs_length
					set secs_length
					set ascii_str ""
					set asc_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					#set temp [binary format H* [string range $asc_str 0 1] ]
					
					while { $asc_str != ""} {
						set block [string range $asc_str 0 [expr (2*$length)-1] ]
						set asc_str [string range $asc_str [expr 2*$length] end]
						#convert hex to ascii
						set block [binary format H* $block]
						set ascii_str $ascii_str$block
					}
					lappend parsed_data "ASC  \"$ascii_str\""

				} elseif { $type == "BOOL" } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec.
					scan $block %x secs_length
					set secs_length

					set bool_str  [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
				
					set ascii_str ""
					while { $bool_str != "" } {
						set block [string range $bool_str 0 1 ]
						set bool_str [string range $bool_str 2 end]
						
						if { $ascii_str == "" } {
							set ascii_str $block 
						} else  {
							set ascii_str {$ascii $block}
						}
						
					}
					lappend parsed_data "BOOL $ascii_str"
				} elseif { $type == "BIN"} {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					scan $block %x secs_length
					set secs_length

					set bin_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
			
					lappend parsed_data "BIN  $bin_str"
				} elseif { ($type == "SI1") || ($type == "UI1") } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set int_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $int_str != ""} {
						set block [string range $int_str 0 1]
						set int_str [string range $int_str 2 end]
							
						if {$type == "UI1"} {		
							set block [format %u 0x$block]
						} else {
							set block [format %d 0x$block]
						}
						set ascii_str "$ascii_str $block"
					}
					if {$type == "UI1"} {
						lappend parsed_data "UI1 $ascii_str"
					} else {
						lappend parsed_data "SI1 $ascii_str"	
					}	
				} elseif { ($type == "SI2") || ($type == "UI2") } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set int_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $int_str != ""} {
						set block [string range $int_str 0 3 ]
						set int_str [string range $int_str 4 end]
							
						if {$type == "UI2"} {		
							set block [format %u 0x$block]
						} else {
							set block [format %d 0x$block]
						}
						set ascii_str "$ascii_str $block"
					}
					if {$type == "UI2"} {
						lappend parsed_data "UI2 $ascii_str"
					} else {
						lappend parsed_data "SI2 $ascii_str"	
					}		
				} elseif { ($type == "SI4") || ($type == "UI4") } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set int_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $int_str != ""} {
						set block [string range $int_str 0 7]
						set int_str [string range $int_str 8 end]
							
						if {$type == "UI4"} {		
							set block [format %u 0x$block]
						} else {
							set block [format %d 0x$block]
						}
						set ascii_str "$ascii_str $block"
					}
					if {$type == "UI4"} {
						lappend parsed_data "UI4 $ascii_str"
					} else {
						lappend parsed_data "SI4 $ascii_str"	
					}		
				} elseif { ($type == "SI8") || ($type == "UI8") } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set int_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $int_str != ""} {
						set block [string range $int_str 0 15]
						set int_str [string range $int_str 16 end]
							
						if {$type == "UI8"} {		
							set block [format %u 0x$block]
						} else {
							set block [format %d 0x$block]
						}
						set ascii_str "$ascii_str $block"
					}
					if {$type == "UI8"} {
						lappend parsed_data "UI8 $ascii_str"
					} else {
						lappend parsed_data "SI8 $ascii_str"	
					}		
				} elseif { ($type == "FP4")} {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set fp_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $fp_str != ""} {
						set block [string range $fp_str 0 7]
						set fp_str [string range $fp_str 8 end]
						#convert hex to ascii
						set block [binary format H* $block]
						#convert IEEE float to decmial string
						set block [IEEE2float $block 0]
						set block [format %.7f $block]
						
						set ascii_str "$ascii_str $block"
					}
					lappend parsed_data "FP4 $ascii_str"	
				} elseif { $type == "FP8" } {
					set block [string range $secs_body 0 [expr (2*$length)-1] ]
					set secs_body [string range $secs_body [expr 2*$length] end]
					#convert hex to dec
					scan $block %x secs_length
					set secs_length	
						
					set fp_str [string range $secs_body 0 [expr (2*$secs_length)-1] ]
					set secs_body [string range $secs_body [expr 2*$secs_length] end]
					set ascii_str ""	
					while { $fp_str != ""} {
						set block [string range $fp_str 0 15]
						set fp_str [string range $fp_str 16 end]
						#convert hex to ascii
						set block [binary format H* $block]
						#convert IEEE float to decmial string
						set block [IEEE2double $block 0]
						set block [format %.17f $block]
						
						set ascii_str "$ascii_str $block"
					}
					lappend parsed_data "FP8 $ascii_str"	
				}
			}

		}
		#travse the parsed data to build the output
		set sml_str ""
		set list_level 0
		array set level_limit {}
		array set level_counter {}
		set level_limit(0) 1
		set level_counter(0) 0
		foreach item $parsed_data {
			if { [lindex $item 0] == "LIST"} {
				for {set thing 0} {$thing < $list_level} {incr thing} {
					set sml_str "$sml_str\t"
				}
				if {([info exist level_counter($list_level)]) } {
					set level_counter($list_level) [incr level_counter($list_level) 1]
				}
					
				set list_level [incr list_level]
				set level_limit($list_level) [lindex $item 1]
				
				set level_counter($list_level) 0
					
				
				set sml_str "$sml_str$item\n"
			} else {
				for {set thing 0} {$thing < $list_level} {incr thing} {
					set sml_str "$sml_str\t"
				}	
				set level_counter($list_level) [incr level_counter($list_level) ]

				
				if { $level_counter($list_level) >= $level_limit($list_level) } {
					if { $list_level >= 0} {
						unset level_counter($list_level) 
						unset level_limit($list_level)
						if {$list_level >= 1} {
							set list_level [incr list_level -1]
						}
						#look back up the array 
						for {set counter $list_level} {$counter > 0} {incr counter -1} {
		
							if { $level_counter($counter) >= $level_limit($counter) } {
								unset level_counter($counter) 
								unset level_limit($counter) 
								if {$counter >= 1} {
									set list_level [incr list_level -1]
								}
								
							} else {
								break
							}
						}
					}
				}
				set sml_str "$sml_str$item\n"
			}
			

		}
		set sml_str "$sml_str*********************************************************\n"
		set sml_msg "S$secs_stream F$secs_function"
		set sml_msg "$sml_msg sxid=$secs_sxid\n$sml_str"
		#nks
		set mq(secs,$mq(msgtotal)) $sml_msg
	}

	.f1.scale1 configure -to $mq(msgtotal)	
	set mq(srvlist) $srvlist
	set mq(nextmsgnum) $mq(msgtotal)  	
        display_servers
	center_server
      }
     }

}

######################################################################

proc val2Bin val {
     set binRep [binary format c $val]
     binary scan $binRep B* binStr
     return $binStr
 }


proc IEEE2float {data byteorder} {
    if {$byteorder == 0} {
        set code [binary scan $data cccc se1 e2f1 f2 f3]
    } else {
        set code [binary scan $data cccc f3 f2 e2f1 se1]
    }

    set se1  [expr {($se1 + 0x100) % 0x100}]
    set e2f1 [expr {($e2f1 + 0x100) % 0x100}]
    set f2   [expr {($f2 + 0x100) % 0x100}]
    set f3   [expr {($f3 + 0x100) % 0x100}]

    set sign [expr {$se1 >> 7}]
    set exponent [expr {(($se1 & 0x7f) << 1 | ($e2f1 >> 7))}]
    set f1 [expr {$e2f1 & 0x7f}]

    set fraction [expr {double($f1)*0.0078125 + \
            double($f2)*3.0517578125e-05 + \
            double($f3)*1.19209289550781e-07}]

    set res [expr {($sign ? -1. : 1.) * \
            pow(2.,double($exponent-127)) * \
            (1. + $fraction)}]
    return $res
}

proc IEEE2double {data byteorder} {
    if {$byteorder == 0} {
        set code [binary scan $data cccccccc se1 e2f1 f2 f3 f4 f5 f6 f7]
    } else {
        set code [binary scan $data cccccccc f7 f6 f5 f4 f3 f2 e2f1 se1]
    }

    set se1  [expr {($se1 + 0x100) % 0x100}]
    set e2f1 [expr {($e2f1 + 0x100) % 0x100}]
    set f2   [expr {($f2 + 0x100) % 0x100}]
    set f3   [expr {($f3 + 0x100) % 0x100}]
    set f4   [expr {($f4 + 0x100) % 0x100}]
    set f5   [expr {($f5 + 0x100) % 0x100}]
    set f6   [expr {($f6 + 0x100) % 0x100}]
    set f7   [expr {($f7 + 0x100) % 0x100}]

    set sign [expr {$se1 >> 7}]
    set exponent [expr {(($se1 & 0x7f) << 4 | ($e2f1 >> 4))}]
    set f1 [expr {$e2f1 & 0x0f}]

    if {$exponent == 0} {
        set res 0.0
    } else {
        set fraction [expr {double($f1)*0.0625 + \
                                double($f2)*0.000244140625 + \
                                double($f3)*9.5367431640625e-07 + \
                                double($f4)*3.7252902984619141e-09 + \
                                double($f5)*1.4551915228366852e-11 + \
                                double($f6)*5.6843418860808015e-14 + \
                                double($f7)*2.2204460492503131e-16}]

        set res [expr {($sign ? -1. : 1.) * \
                           pow(2.,double($exponent-1023)) * \
                           (1. + $fraction)}]
    }

    return $res

} 



proc bin2dec {num} {
    set num h[string map {1 i 0 o} $num]
    while {[regexp {[io]} $num]} {
       set num\
         [string map {0o 0 0i 1 1o 2 1i 3 2o 4 2i 5 3o 6 3i 7 4o 8 4i 9 ho h hi h1}\
           [string map {0 o0 1 o1 2 o2 3 o3 4 o4 5 i0 6 i1 7 i2 8 i3 9 i4} $num]]
    }
    return [string range $num 1 end]
 }

 #find the secs data type in-> binary of the data  out->type (UI1, ASC ...)
proc find_type indata {
	if {[string compare $indata "000000"] == 0} {
		set type LIST
	} elseif {[string compare $indata "001000"] == 0} {
		set type BIN
	} elseif {[string compare $indata "001001"] == 0} {
		set type BOOL
	} elseif {[string compare $indata "010000"] == 0} {	
		set type ASC
	} elseif {[string compare $indata "011001"] == 0} {
 		set type SI1
	} elseif {[string compare $indata "011010"] == 0} {
		set type SI2
	} elseif {[string compare $indata "011100"] == 0} {
		set type SI4
	} elseif {[string compare $indata "011000"] == 0} {
		set type SI8
	} elseif {[string compare $indata "100000"] == 0} {
		set type FP8
	} elseif {[string compare $indata "100100"] == 0} {
		set type FP4
	} elseif {[string compare $indata "101000"] == 0} {
		set type UI8
	} elseif {[string compare $indata "101001"] == 0} {
		set type UI1
	} elseif {[string compare $indata "101010"] == 0} {
		set type UI2
	} elseif {[string compare $indata "101100"] == 0} {
		set type UI4
	} else {
		set type $indata
	}
	return $type
}	


proc make_msg_list {} {

	global mq 
        if {$mq(DEBUG)=="on"} {
          puts " in make_msg_list\n"
        }

#        set mq(scanned) 1
	set srvlist  $mq(srvlist)
        set filetext $mq(currentfiletext)  
        set line [string range $filetext 0 [string first "\n"  $filetext]]
        set message ""
        set prev $line	
        set line [string range $filetext 0 [string first "\n"  $filetext]]
        set first10 [string range $line 0 9] 
 
        while {$filetext!=""} {
          
          if {$first10=="----------"} {
 	    set message $prev	
	    set FLAG 0	
	    while {$FLAG!=1} {
 	           set message [append message $line]
	           set line [string range $filetext 0 [string first "\n"  $filetext]]
	           set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
 	           set first10 [string range $line 0 9]
		   set frto [string first "fr=" $line]

		   # if a server comm line get srv values to check......
		   if {$frto!=-1} {	
		     set frtag [string range $line [string first "fr=" $line] end]
		     set firstwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set frtag [string range $frtag [expr [string first " " $frtag] +1] end]
		     set secondwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set firstwd [string range $firstwd 3 end]
		     set secondwd [string range $secondwd 3 end]
			
	             if {[lsearch $srvlist $firstwd]==-1} {
 	 	            set srvlist [lappend srvlist $firstwd]
		     }

          	     if {[lsearch $srvlist $secondwd]==-1} {
              		    set srvlist [lappend srvlist $secondwd]
		     }	
           	   }
 	
		   if {$first10=="----------"} {
 	             set message [append message $line]
		     set FLAG 1    			     				 			
		     set mq(msgtotal) [expr $mq(msgtotal) +1]
		     set mq(msg,$mq(msgtotal)) $message
		   }
	    }	
 
          } 


          if {$first10=="=========="} {
          set FLAG 0	
          set message $prev	


## 	  added justin	9/24/99

  	     if {[string first "non-AutoNet"  $prev]!=-1} {           
               set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
               set line [string range $filetext 0 [string first "\n"  $filetext]]
 	       set mq(currentfiletext) $filetext
  	       set FLAG 1    			     				 			
  	       set mq(msgtotal) [expr $mq(msgtotal) +1]
  	       set mq(msg,$mq(msgtotal)) $message  	       
            }

	    while {$FLAG!=1} {
 	           set message [append message $line]
	           set line [string range $filetext 0 [string first "\n"  $filetext]]
	           set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
 	           set first10 [string range $line 0 9]
		   set frto [string first "fr=" $line]
		   

  		   # if a server comm line get srv values to check......
		   if {$frto!=-1} {	
		     set frtag [string range $line [string first "fr=" $line] end]
                     set firstwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set frtag [string range $frtag [expr [string first " " $frtag] +1] end]
                     set secondwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
		     set firstwd [string range $firstwd 3 end]
		     set secondwd [string range $secondwd 3 end]
	             if {[lsearch $srvlist $firstwd]==-1} {
 	 	            set srvlist [lappend srvlist $firstwd]
		     }

          	     if {[lsearch $srvlist $secondwd]==-1} {
              		    set srvlist [lappend srvlist $secondwd]
		     }	
           	   }

		   if {$first10=="=========="} {
 	             set message [append message $line]
		     set FLAG 1    			     				 			
		     set mq(msgtotal) [expr $mq(msgtotal) +1]
		     set mq(msg,$mq(msgtotal)) $message

		   }

	    }	
 
          } 
        # Move on to next Line
        set prev $line	
        set line [string range $filetext 0 [string first "\n"  $filetext]]
        set filetext [string range $filetext [expr [string first "\n" $filetext]+1] end]
        set first10 [string range $line 0 9] 
        }
#######
	set mq(currentfiletext) ""
#######
	.f1.scale1 configure -to $mq(msgtotal)	
	set mq(srvlist) $srvlist
	display_servers
	

}

proc run_to_bkpt {} {

	global mq 	
        if {$mq(DEBUG)=="on"} {
          puts " in run_to_bkpt\n"
        }


	   set previousmsg $mq(nextmsgnum)					
	   set FLAG 0	
           set CTR 0
	   while {($FLAG==0 && $mq(nextmsgnum)<[expr $mq(msgtotal)-1]) && $mq(nextmsgnum)>0 && $CTR<2} {
  		   if {$mq(nextmsgnum)==1} {
                       set CTR [expr $CTR + 1]
                   }
  		   set mq(nextmsgnum)	[expr $mq(nextmsgnum) + $mq(direction)]
                   
		   set message $mq(msg,$mq(nextmsgnum))		

		   # IF RUN UNTIL REPLY = NON ZERO CHECK REPLYMSG
	 		     if {$mq(bkpt,nonzero)==1} {
		     	       set message $mq(msg,$mq(nextmsgnum))		
			       set replymsg ""
  			       if {[string first "reply=" $message]!=-1}  {
		                 set replymsg [string range $message [string first "reply=" $message] end]
			         set replymsg [string range $replymsg 0 [expr [string first " " $replymsg] -1 ] ]
			         set replymsg [string range $replymsg 6 end]        
			       }			
	  	  	       if {$replymsg!=0 && $replymsg!=""} {
			         set FLAG 1
	 		       } 	
			     }  		

		   # IF RUNNING UNTIL SENDING SERVER
		             if {$mq(bkpt,sender)==1} {
  	         	       set message $mq(msg,$mq(nextmsgnum))		
  			       if {[string first "fr=" $message]!=-1}  {
		                 set tomsg [string range $message [string first "fr=" $message] end]
			         set tomsg [string range $tomsg 0 [expr [string first " " $tomsg] -1 ] ]
			         set tomsg [string range $tomsg 3 end]        
			       }			
	  	  	       if {$tomsg==$mq(bkpt,sender,data) && $mq(bkpt,sender,data)!="" } {
			         set FLAG 1
	 		       } 	
			     }  		

		   # IF RUNNING UNTIL Receiving SERVER
		             if {$mq(bkpt,receive)==1} {
  	         	       set message $mq(msg,$mq(nextmsgnum))		
  			       if {[string first "to=" $message]!=-1}  {
		                 set frmsg [string range $message [string first "to=" $message] end]
			         set frmsg [string range $frmsg 0 [expr [string first " " $frmsg] -1 ] ]
			         set frmsg [string range $frmsg 3 end]        
			       }	
			       set zz [string first "to=" $message]
	  	  	       if {$frmsg==$mq(bkpt,receive,data) && $mq(bkpt,receive,data)!="" } {
			         set FLAG 1
	 		       } 	
			     }  		

		   # IF RUNNING UNTIL user defined string
		             if {$mq(bkpt,user)==1} {
  	         	       set message $mq(msg,$mq(nextmsgnum))		
	  	  	       if {[string first $mq(bkpt,user,data) $message]!=-1} {
			         set FLAG 1
	 		       } 	
			     }  		

	   }	
		  if {$FLAG==1} {
						     draw_line -1
						     draw_line 1
						   } else {
                                                     set mq(nextmsgnum) $previousmsg	
						   }				 

}

proc prompt_usr_window {msg type} {
   global btn mq
   if {$mq(DEBUG)=="on"} {
       puts " in prompt_usr_window\n"
   }

   toplevel .userin
   wm resizable .userin false false

   frame .userin.f0
   frame .userin.f1
   frame .userin.f2

   label .userin.f0.label -text ">"
   entry .userin.f0.entry -width 30

   bind .userin.f0.entry <Return> {
      set btn ok
     }
   
   label .userin.f1.label -text $msg

   button .userin.f2.btnOK     -text "Ok"     -width 6 -command "event generate .userin <Return>"
   button .userin.f2.btnCancel -text "Cancel" -width 6 -command "set btn cancel"

   pack .userin.f0.label -side left -anchor w
   pack .userin.f0.entry
   pack .userin.f0
   pack .userin.f1.label
   pack .userin.f1 -pady 5
   pack .userin.f2.btnOK -side left
   pack .userin.f2.btnCancel
   pack .userin.f2 -pady 5
 
   bind .userin <Escape> { set btn cancel }

   # wait for button or key bindings
   grab .userin
   focus .userin.f0.entry
   wm geometry .userin +[expr [winfo rootx .]+130]+[expr [winfo rooty .] + 50]
 
   tkwait variable btn
    
  if {$btn=="ok"} {
        set mq(bkpt,$type,data)  [.userin.f0.entry get]
  }
  
   # destroy this dialog and return focus to previous window
   destroy .userin
}

proc switch_mode  {} {
	global mq
        if {$mq(DEBUG)=="on"} {
          puts " in switch_mode\n"
        }

       if {$mq(viewmode)=="graphical"} {
 
        catch {
	        .f2.txt delete 0.0 end
	      }	
        set h [winfo height .f1.mcanvas1]
	set w [winfo width .f1.mcanvas1]

        destroy .f1.mcanvas1 
        destroy .f1.scale1 

	set mq(viewmode) "text"
 
        text .f1.txt -height 24	-width 50
        scrollbar .f1.scroll1  -command ".f1.txt yview"
        .f1.txt configure -yscrollcommand ".f1.scroll1 set"

        pack .f1.txt -side left -in .f1 -expand 1 -fill both
        pack .f1.scroll1 -side left -in .f1 -fill y
        pack .f1 -expand 1 -fill both
       .f1.txt insert end $mq(filetext)

	set msg $mq(msg,$mq(nextmsgnum))
	
	set location [string first $msg  $mq(filetext) ]
	set location [expr $location / 1.0 ]

	set total [string length $mq(filetext)]
         
	set txtpos [expr $location / $total]
#	set txtpos [expr 10.0 / 20.0]

	.mbar.edit.m entryconfigure "Step" -state disabled
        .mbar.edit.m entryconfigure "Run To Breakpoint" -state disabled
        .mbar.edit.m entryconfigure "Scan Log" -state disabled
        .mbar.edit.m entryconfigure "Auto-Play" -state disabled
        .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
        .mbar.edit.m entryconfigure "Text/Graphical Mode" -state normal
        .f3.btn2 configure -state disabled
        .f3.btn3 configure -state disabled
        .f3.btn4 configure -state disabled
        .f3.btn5 configure -state disabled
        .f3.btn8 configure -state disabled
#        .f3.btn9 configure -state disabled
        .f3.btn7 configure -state active
        update	
	
	.f1.txt yview moveto $txtpos
        
	} else {  

          if {$mq(viewmode)=="text"} {

           destroy .mbar
 	   destroy .f3
	   destroy .bkpt_menu
  	   destroy .f2
	   destroy .f1
  	   destroy .main
  	   setupGUI
 	   set mq(viewmode) "graphical"
           .mbar.edit.m entryconfigure "Step" -state normal
           .mbar.edit.m entryconfigure "Run To Breakpoint" -state normal
           .mbar.edit.m entryconfigure "Scan Log" -state normal
           .mbar.edit.m entryconfigure "Auto-Play" -state normal
           .mbar.edit.m entryconfigure "Stop Auto-Play" -state normal
           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state normal
   
           .f3.btn2 configure -state normal
           .f3.btn3 configure -state normal
           .f3.btn4 configure -state normal
           .f3.btn5 configure -state normal
           .f3.btn6 configure -state normal
           .f3.btn7 configure -state disabled
           .f3.btn8 configure -state normal
           .f3.btn11 configure -state active

           .mbar.file.m entryconfigure "Close MqHist File" -state normal
#           .f3.btn9 configure -state normal
           catch {draw_line -1}

	  }   
	}

}
proc show_bkpt_menu  {xyval} {
	global mq
        if {$mq(DEBUG)=="on"} {
          puts " in show_bkpt_menu\n"
        }
	
	after 50
	bind . <1> "catch {	
 			    .bkpt_menu.breakpoints.m unpost
			  }
	             catch {	
 			    destroy .bkptmenu
		           }"	

 if {[winfo exists .bkptmenu]} {
       raise .bkptmenu 
   } else {

     toplevel .bkptmenu -relief raised -bd 2 
     frame .bkptmenu.f1 -relief sunken -bd 1
     frame .bkptmenu.f2 -relief sunken -bd 1
     frame .bkptmenu.f3 -relief sunken -bd 1
     frame .bkptmenu.f4 -relief sunken -bd 1

     checkbutton .bkptmenu.f1.nz -text "Non-Zero Replies" \
                              -command "" -variable mq(bkpt,nonzero)

     checkbutton .bkptmenu.f2.send -text "Sender"   \
                              -command "" -variable mq(bkpt,sender) -anchor w

     button .bkptmenu.f2.sname   -text "  Set Sender Name" \
			      -command "prompt_usr_window \"Enter Sending Server Name to Halt On\" sender"  
                              
     checkbutton .bkptmenu.f3.reci -text "Receiver"    \
                              -command "" -variable mq(bkpt,receive)

     button .bkptmenu.f3.recin -text "  Set Receiver Name"    \
                              -command "prompt_usr_window \"Enter Receiving Server Name to Halt On\" receive" 
	

     checkbutton .bkptmenu.f4.usr -text "User Defined String"   \
                              -command "" -variable mq(bkpt,user)

     button .bkptmenu.f4.usrdef -text "  Set User String"  \
                              -command "prompt_usr_window \"Enter String Halt On\" user"

      pack .bkptmenu.f1.nz -anchor w
      pack .bkptmenu.f1 -anchor w -expand 1 -fill both

      pack .bkptmenu.f2.send -anchor w
      pack .bkptmenu.f2.sname -anchor w 
      pack .bkptmenu.f2 -anchor w -expand 1 -fill both
      pack .bkptmenu.f3.reci -anchor w
      pack .bkptmenu.f3.recin -anchor w
      pack .bkptmenu.f3 -anchor w -expand 1 -fill both

      pack .bkptmenu.f4.usr -anchor w

      pack .bkptmenu.f4.usrdef -anchor w
      pack .bkptmenu.f4 -anchor w -expand 1 -fill both

      wm geometry .bkptmenu +[expr [lindex $xyval 0] - 150]+[expr 0 + [lindex $xyval 1]]

      wm overrideredirect .bkptmenu 1

      bind . <1> "catch {
		    destroy .bkptmenu
		  }"
    }
}


proc show_mode_menu  {xyval} {
	global mq
        if {$mq(DEBUG)=="on"} {
          puts " in show_mode_menu\n"
        }

	
	after 50
	bind . <1> "catch {	
 			    .mode_menu.mode.m unpost
			  }
	             catch {	
 			    destroy .modemenu
		           }"	

 if {[winfo exists .modemenu]} {
       raise .modemenu 
   } else {

     toplevel .modemenu -relief raised -bd 2 
     frame .modemenu.f1 -relief sunken -bd 1

     radiobutton .modemenu.f1.static -text "Static/SnapShot Mode" \
                               -value static -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state active
 								           set mq(direction) 1

								  	   .mbar.edit.m entryconfigure "Step" -state active
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state active
								           .mbar.edit.m entryconfigure "Scan Log" -state active
								           .mbar.edit.m entryconfigure "Auto-Play" -state active
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state active
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state active

								           .f3.btn2 configure -state active
								           .f3.btn3 configure -state active
								           .f3.btn4 configure -state active
								           .f3.btn5 configure -state active
								           .f3.btn6 configure -state active
								           .f3.btn8 configure -state active

									   global mq	
									   mq_tailfile_stop $mq(filename) $mq(filep)
									   set mq(update) 0			
  								           set mq(auto) 0
 									   set mq(tail) 0
									 }

     radiobutton .modemenu.f1.real -text "Realtime Mode" \
			      -value realtime -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state active
 								           set mq(direction) 1

									   .mbar.edit.m entryconfigure "Step" -state active
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state active
								           .mbar.edit.m entryconfigure "Scan Log" -state active
								           .mbar.edit.m entryconfigure "Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state disabled

								           .f3.btn2 configure -state active
								           .f3.btn3 configure -state active
								           .f3.btn8 configure -state active
								           .f3.btn4 configure -state disabled
								           .f3.btn5 configure -state disabled
								           .f3.btn6 configure -state disabled

									   global mq	
									   mq_tailfile_stop $mq(filename) $mq(filep)	    			
									   set mq(update) 1			
                   							   mq_tailfile_update $mq(filename) $mq(filep) $mq(inode)
       								           set mq(auto) 0										
    									   set mq(tail) 0
					                                  }

     radiobutton .modemenu.f1.follow -text "Realtime Follow Mode" \
               		      -value follow -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state disabled
 								           set mq(direction) 1

									   .mbar.edit.m entryconfigure "Step" -state disabled
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state disabled
								           .mbar.edit.m entryconfigure "Scan Log" -state disabled
								           .mbar.edit.m entryconfigure "Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state disabled

								           .f3.btn2 configure -state disabled
								           .f3.btn3 configure -state disabled
								           .f3.btn4 configure -state disabled
								           .f3.btn5 configure -state disabled
								           .f3.btn6 configure -state disabled
								           .f3.btn8 configure -state disabled

  									    global mq
 									    set mq(update) 1				
									    mq_tailfile_update $mq(filename) $mq(filep) $mq(inode)
 								            set mq(tail) 1	
										
							                }

      pack .modemenu.f1.static -anchor w
      pack .modemenu.f1.real   -anchor w
      pack .modemenu.f1.follow -anchor w
      pack .modemenu.f1

      wm geometry .modemenu +[expr [lindex $xyval 0] - 150]+[expr 0 + [lindex $xyval 1]]

      wm overrideredirect .modemenu 1

      bind . <1> "catch {
		    destroy .modemenu
		  }"
    }
}


###########
#  proc aboutDLG
# 
#  VARIABLES:
#      win  = current winvalue
#      mesg = window message
#
#  DESCRIPTION:
#	Typical ABOUT SCREEN
#
############
proc aboutDLG {} {
   global mq ashlSupportName ashlSupportEmail release_version copyright
   if {$mq(DEBUG)=="on"} {
      puts " in show_bkpt_menu\n"
   }

   toplevel .about
   wm title .about "About Mqhist Tracer"
   wm resizable .about false false
   label .about.name  -text "\nMqhist Tracer"
   label .about.ver   -text "Version $release_version"
   label .about.copyright  -text "\n$copyright"
   label .about.support -text "For support and maintence contact:"
   label .about.email -text "$ashlSupportEmail"
   label .about.auth  -text "\n\nOriginal author: Justin Tervooren\n"
   pack  .about.name
   pack  .about.ver
   pack  .about.copyright
   pack  .about.support
   pack  .about.email
   pack  .about.auth
   wm geometry .about +[expr [winfo rootx .]+130]+[expr [winfo rooty .] + 50]

   button .about.ok -text OK -command "destroy .about" -width 10
   pack .about.ok -side top -ipadx 3 -ipady 3 -padx 3 -pady 3
   catch {grab .about}
   tkwait window .about

}

proc auto_step {} {
	global mq
        if {$mq(DEBUG)=="on"} {
          puts " in auto_step\n"
        }

	update
	while {$mq(auto)!=0} {
	   if {$mq(auto)!=0} {
	    process_one_msg 	   
	    update
            if {[string trim $mq(currentfiletext)]==""} { 
	       set mq(auto) 0
               return       
            }
	    balloon_cancel
	    after $mq(delay)		
	    update
   	    if {$mq(auto)!=0} {
  	      auto_step
	    }	
	  }	
	  	  
	}

}

###########
#  proc showFindDLG
# 
#  DESCRIPTION:
#	Display Find Window
#
############
proc showFindDLG {} {
   global find_case find_whole find_search_string btn mq
   
   if {$mq(DEBUG)=="on"} {
      puts " in showFind\n"
   }

 if {[winfo exists .find]} {
     raise .find
     return
 } else {
   toplevel .find
   wm resizable .find false false
   wm title .find "Find a String"

   frame .find.f0
   frame .find.f0.f1
   frame .find.f0.f2
   frame .find.f3

   label .find.f0.f1.label -text "Find What:" -width 13
   entry .find.f0.f1.entry -width 20

   set find_whole 0
   set find_case  0
   if {[info exists find_search_string]} {
     .find.f0.f1.entry insert 0 $find_search_string
   }
   focus .find.f0.f1.entry

   checkbutton .find.f0.f2.check2 -text "Match Case" \
                                  -variable find_case

   button .find.f3.btn1 -text "Find Next" -command { set btn ok}
   button .find.f3.btn2 -text "Cancel   " -command { set btn cancel }

   pack .find.f0.f1.label -side left -anchor w
   pack .find.f0.f1.entry
   pack .find.f0.f1 -anchor w

   pack .find.f0.f2.check2 -anchor w
   pack .find.f0.f2 -anchor w

   pack .find.f0 -side left -padx 10

   pack .find.f3.btn1
   pack .find.f3.btn2
   pack .find.f3

   # make some key bindings
   bind .find  <Return> { set btn ok }
   bind .find  <Escape> { set btn cancel }
   wm geometry .find +[expr [winfo rootx .]+30]+[expr [winfo rooty .]+180]
   focus .find.f0.f1.entry

   # wait for button or key bindings
   tkwait variable btn
   grab .find
   focus .find.f0.f1.label
     
   if {$btn=="ok"} {
       grab .find
       focus .find.f0.f1.label
       startFind 
       destroy .find 
       showFindDLG
       
   } 
   if {$btn=="cancel"} {
       destroy .find       
   }

 } 
 return
}

###########
#  proc mqt_options
# 
#  DESCRIPTION:
#	
#
############
proc mqt_options {} {
   global btn mq

   if {$mq(DEBUG)=="on"} {
      puts " in mqt_options\n"
   }

   
 if {[winfo exists .options]} {
     raise .options
     return
 } else {
   toplevel .options
   wm title .options "MQTrace Options"
   frame .options.r1 -relief sunken -bd 3
   frame .options.r1.f1 -relief sunken -bd 1
   frame .options.r1.f2 -relief sunken -bd 1
   frame .options.r1.f2.sec1 -relief sunken -bd 1

   frame .options.r1.f2.sec1.pmpt 

   frame .options.r1.f1.f1 -relief sunken -bd 1
   frame .options.r1.f1.f2 -relief sunken -bd 1
   frame .options.r1.f1.f2.row
   frame .options.r1.f1.f3 -relief sunken -bd 1
   frame .options.r1.f1.f3.row
   frame .options.r1.f1.f4 -relief sunken -bd 1
   frame .options.r1.f1.f4.row

   frame .options.f2 -relief sunken -bd 3
   frame .options.f2.r1 -relief sunken -bd 1
   frame .options.f2.r1.f1 -relief sunken -bd 1

   frame .options.f3
   frame .options.f5

   label .options.title -text "MqTrace Options" 

   label .options.spacer -text " " 


   label .options.r1.f1.sectitle -text "Current BreakPoint Settings"  -foreground navy 

   checkbutton .options.r1.f1.nzreply -text "Non-Zero Reply" \
                               -variable mq(bkpt,nonzero)

   checkbutton .options.r1.f1.f2.sender -text "Sender" \
                               -variable mq(bkpt,sender)

   label .options.r1.f1.f2.row.pmpt -text "     > " 

   entry .options.r1.f1.f2.row.sdata -width 15 -text sdata -textvariable mq(bkpt,sender,data) -justify left


   checkbutton .options.r1.f1.f3.reciever -text "Receive" \
                               -variable mq(bkpt,receive)

   label .options.r1.f1.f3.row.pmpt -text "     > " 

   entry .options.r1.f1.f3.row.rdata -width 15 -text rdata -textvariable mq(bkpt,receive,data) -justify left

   checkbutton .options.r1.f1.f4.userdef -text "User Defined" \
                               -variable mq(bkpt,user)

   label .options.r1.f1.f4.row.pmpt -text "     > " 

   entry .options.r1.f1.f4.row.udata -width 15 -text udata -textvariable mq(bkpt,user,data) -justify left

   label .options.spacer2 -text " " 


   label .options.r1.f2.title -text "Viewing Mode" -foreground navy 


   radiobutton .options.r1.f2.static -text "Static/SnapShot Mode" \
                               -value static -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state active
 								           set mq(direction) 1

								  	   .mbar.edit.m entryconfigure "Step" -state active
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state active
								           .mbar.edit.m entryconfigure "Scan Log" -state active
								           .mbar.edit.m entryconfigure "Auto-Play" -state active
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state active
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state active

								           .f3.btn2 configure -state active
								           .f3.btn3 configure -state active
								           .f3.btn4 configure -state active
								           .f3.btn5 configure -state active
								           .f3.btn6 configure -state active
								           .f3.btn8 configure -state active

									   global mq	
									   mq_tailfile_stop $mq(filename) $mq(filep)
									   set mq(update) 0			
  								           set mq(auto) 0
 									   set mq(tail) 0
									 }

   radiobutton .options.r1.f2.real -text "Realtime Mode" \
			      -value realtime -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state active
 								           set mq(direction) 1

									   .mbar.edit.m entryconfigure "Step" -state active
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state active
								           .mbar.edit.m entryconfigure "Scan Log" -state active
								           .mbar.edit.m entryconfigure "Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state disabled

								           .f3.btn2 configure -state active
								           .f3.btn3 configure -state active
								           .f3.btn8 configure -state active
								           .f3.btn4 configure -state disabled
								           .f3.btn5 configure -state disabled
								           .f3.btn6 configure -state disabled

									   global mq	
									   mq_tailfile_stop $mq(filename) $mq(filep)	    			
									   set mq(update) 1			
                   							   mq_tailfile_update $mq(filename) $mq(filep) $mq(inode)
       								           set mq(auto) 0										
    									   set mq(tail) 0
					                                  }

   radiobutton .options.r1.f2.follow -text "Realtime Follow Mode" \
               		      -value follow -variable mq(mode) -command {
									   .f3.direc.btn1a configure -state disabled
 									   .f3.direc.btn1b configure -state disabled
 								           set mq(direction) 1

									   .mbar.edit.m entryconfigure "Step" -state disabled
								           .mbar.edit.m entryconfigure "Run To Breakpoint" -state disabled
								           .mbar.edit.m entryconfigure "Scan Log" -state disabled
								           .mbar.edit.m entryconfigure "Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Stop Auto-Play" -state disabled
								           .mbar.edit.m entryconfigure "Text/Graphical Mode" -state disabled

								           .f3.btn2 configure -state disabled
								           .f3.btn3 configure -state disabled
								           .f3.btn4 configure -state disabled
								           .f3.btn5 configure -state disabled
								           .f3.btn6 configure -state disabled
								           .f3.btn8 configure -state disabled

  									    global mq
 									    set mq(update) 1				
									    mq_tailfile_update $mq(filename) $mq(filep) $mq(inode)
 								            set mq(tail) 1	
										
							                }





   label .options.r1.f2.sec1.title2 -text "Step Delay Time" -foreground navy 

   label .options.r1.f2.sec1.pmpt.pmpttxt -text "  > " 

   entry .options.r1.f2.sec1.pmpt.pmptent -width 15 -text udata -textvariable mq(delay) -justify left


   label .options.f2.r1.title -text "Display Options" -foreground navy 

   checkbutton .options.f2.r1.f1.bottomtxt -text "Show Bottom Text Window" \
                               -variable mq(bottext) -command { 
								global mq
								if {$mq(bottext)==0} {
								   destroy .f2
#								   destroy .f2.txt 
#								   destroy .f2.scroll1
								}
								if {$mq(bottext)==1} {
								   frame .f2	
  						                   text .f2.txt -width 55 -height 5
								   scrollbar .f2.scroll1  -command ".f2.txt yview"
								   .f2.txt configure -yscrollcommand ".f2.scroll1 set"

								   pack .f2.txt -side left -in .f2 -expand 1 -fill both
								   pack .f2.scroll1 -side left -in .f2 -fill y
								   pack .f2 -expand 1 -fill both
								}	
							}

   checkbutton .options.f2.r1.f1.command -text "Show Command Tag" -variable mq(canvcommand)


  button .options.f5.ok -text "Ok" -command "set btn ok"
  button .options.f5.cancel -text "Cancel" -command "set btn cancel"


   pack .options.title -pady 8
   pack .options.r1.f1.sectitle -pady 5
   pack .options.r1.f1.nzreply -anchor w
   pack .options.r1.f1.f1 -anchor w -expand 1 -fill both

   pack .options.r1.f1.f2.sender -anchor w
   pack .options.r1.f1.f2.row.pmpt -side left
   pack .options.r1.f1.f2.row.sdata -side left
   pack .options.r1.f1.f2.row  -anchor w
   pack .options.r1.f1.f2 -anchor w -expand 1 -fill both

   pack .options.r1.f1.f3.reciever -anchor w
   pack .options.r1.f1.f3.row.pmpt -side left
   pack .options.r1.f1.f3.row.rdata -side left
   pack .options.r1.f1.f3.row  -anchor w
   pack .options.r1.f1.f3 -anchor w -expand 1 -fill both

   pack .options.r1.f1.f4.userdef -anchor w
   pack .options.r1.f1.f4.row.pmpt -side left
   pack .options.r1.f1.f4.row.udata -side left
   pack .options.r1.f1.f4.row  -anchor w
   pack .options.r1.f1.f4 -anchor w -expand 1 -fill both

   pack	.options.r1.f2.title -pady 8
   pack .options.r1.f2.static -anchor w
   pack .options.r1.f2.real -anchor w
   pack .options.r1.f2.follow -anchor w

   pack	.options.r1.f2.sec1.title2 -pady 5
   pack .options.r1.f2.sec1.pmpt.pmpttxt -anchor w -side left
   pack .options.r1.f2.sec1.pmpt.pmptent -anchor w -side left

   pack .options.r1.f2.sec1.pmpt -expand 1 -fill both -side left
   pack .options.r1.f2.sec1 -expand 1 -fill both 
   pack .options.r1.f1 -expand 1 -fill both -side left
   pack .options.r1.f2 -expand 1 -fill both -side left

   pack .options.r1 -expand 1 -fill both
   pack .options.spacer2

   pack .options.f2.r1.title -pady 7
   pack .options.f2.r1.f1.bottomtxt -anchor w -side left
   pack .options.f2.r1.f1.command -anchor w -side left -padx 20
   pack .options.f2.r1.f1 -anchor w 
   pack .options.f2.r1 -anchor w 
   pack .options.f2 -expand 1 -fill both

   pack .options.f5.ok -side left
   pack .options.f5.cancel -side left
   pack .options.f5 -pady 5
   

   bind .options  <Return> { set btn ok }
   bind .options  <Escape> { set btn cancel }
 
   wm geometry .options +[expr [winfo rootx .]+100]+[expr [winfo rooty .]+30]

   # wait for button or key bindings
   tkwait variable btn
   focus .options
     
   if {$btn=="ok"} {
       destroy .options
   } 
   if {$btn=="cancel"} {
       destroy .options
   }

 } 
 return
}



###########
#  proc findScript
# 
#  DESCRIPTION:
#	startFind is run when user clicks the find button on the main find window
#
#
############
proc startFind {} {
   global find_search_string btn mq
   if {$mq(DEBUG)=="on"} {
      puts " in startFind\n"
   }


   set find_search_string [.find.f0.f1.entry get]
   doFind
   return
}

###########
#  proc doFind
# 
#  VARIABLES:
#       win  = window name
#	loc  = location
#	   
#  DESCRIPTION:
#	search through the text widget and find the selection 
#
############
proc doFind {} {
   global find_case find_whole find_search_string btn mq
   if {$mq(DEBUG)=="on"} {
      puts " in doFind\n"
   }

   set win .f1.txt
   set search_string $find_search_string
   if {$find_search_string == ""} {
         return
   }
   if {$find_whole} {set search_string "\[ |\t\]$find_search_string\[ |\t|\n\]"}

   if {$find_case} {
      set loc [$win search -- $search_string {insert +1c}]
   } else {
      set loc [$win search -nocase -- $search_string {insert +1c}]
   }

   if {$loc != ""} {
      $win mark set insert $loc
      $win yview -pickplace insert
      catch {selection clear -displayof $win}
      $win tag add sel insert "insert +[string length $find_search_string]c"
   }
   return
}

###########
#  proc switch_direction
# 
#  VARIABLES:
#	   
#  DESCRIPTION:
#
############

proc switch_direction {} {
  	global mq env
        if {$mq(DEBUG)=="on"} {
          puts " in switch_direction\n"
        }

	image create photo back -file $env(ASTK_DIR)/images/mqt_smbkwd.gif
	image create photo fwd -file $env(ASTK_DIR)/images/mqt_smfwd.gif

	if {$mq(direction)==1} {
   	  .f3.direc.btn1a configure -state active
 	  .f3.direc.btn1b configure -state disabled

	  set mq(direction) -1
	} else {
  	  if {$mq(direction)==-1} {
 	  .f3.direc.btn1a configure -state disabled
 	  .f3.direc.btn1b configure -state active

 	    set mq(direction) 1
	  }
        }
	
}
	

proc update_scale {newval} {
		global mq
		if {$mq(DEBUG)=="on"} {
		    puts " in update_scale\n"
  		}
					
 			if {$newval==1} {
			  set $mq(nextmsgnum) 2				
		          catch {draw_line -1}
			  return 
			} else {
   			  if {$newval==$mq(msgtotal)} {
			    set $mq(nextmsgnum) [expr $mq(msgtotal) -1]
			    catch {draw_line 1}			
			    return 
			  }

			}

		        catch {draw_line 1}
		        catch {draw_line -1}
			focus .f1.mcanvas1
}




##############################################################


proc balloon_pend {message id} {
	global binfo options
	balloon_cancel
	set esc_message $message
        # Escape all escapes
        regsub -all {\\} $esc_message "\\\\" esc_message
        # Escape all embedded quotes.
       regsub -all {\"} $esc_message "\\\"" esc_message

	set binfo(pending) [after 800 "balloon_show \"$esc_message\" $id"]
}


proc balloon_show {message id} {
	global binfo

	set orglength [string length $message]
	set message [string range $message 0 300]
	if {$orglength>360} {
	  append message " . . . . . . . . . . . ."
	}

	set text $message

	if {[winfo exists .balloon]} {
		destroy .balloon
	}
toplevel .balloon -borderwidth 2 -borderwidth 1 -relief flat -background black
label .balloon.info -bg #FFFF99 -fg black -justify left -wraplength 350\
	-font -*-lucida-medium-r-normal-sans-*-100-* 
pack .balloon.info -fill both
wm overrideredirect .balloon 1
#wm withdraw .balloon
	.balloon.info configure -text $text
	set px [winfo pointerx .]
	set py [winfo pointery .]
	set rh [winfo reqheight .balloon.info]
	set rw [winfo reqwidth .balloon.info]
	if {[expr $px+$rw+10]>[winfo screenwidth .]} {
		set x [expr $px-$rw-10]
	} else {
		set x [expr $px+10]
	}
	if {[expr $py+$rh+10]>[winfo screenheight .]} {
		set y [expr $py-$rh-10]
	} else {
		set y [expr $py+10]
	}
	wm geometry .balloon +$x+$y
	#wm deiconify .balloon
	#update idletasks
	#raise .balloon
}


proc balloon_cancel {} {
	global binfo
	if {[info exists binfo(pending)]} {
		after cancel $binfo(pending)
		unset binfo(pending)
	}
	if {[winfo exists .balloon]} {
		wm withdraw .balloon
	}
}


proc talk_session {cs} {
        set cn $cs
	if {$cs!=""} {
                
        	#regsub -all {\.} $cn {=} cn 
		global sessnames sesscount sessids
		if {[info exists sessids($cn)] && [winfo exists $sessids($cn)]} {
			set winid $sessids($cn)
			raise $winid
			wm deiconify $winid
		} else {
			set winid .session$sesscount
			toplevel $winid
			set sessnames($winid) $cn
			set sessids($cn) $winid
                	session_ui $winid
			incr sesscount
		}
		focus $winid.commandentry
        }
}


#############################################################


proc follow_file {base} {
        global mq
	if {$mq(DEBUG)=="on"} {
	    puts " in follow_file\n"
	}

 	start_mq_tail $mq(filename)
}

proc start_mq_tail {fn} {
global env mq
	if {$mq(DEBUG)=="on"} {
	    puts " in start_mqtail\n"
	}

# Array of "follow" flags.
set tf_f(0) 0

#$base.txt delete 0.0 end

mq_tailfile $fn

}
proc mq_tailfile {filepath} {
      global  tf_f tf_p tf_searchstr tf_sd tf_sp mq
	if {$mq(DEBUG)=="on"} {
	    puts " in mq_tailfile\n"
	}


	if {[info exists tf_p($filepath)]} {
		return
	}
	set tf_p($filepath) 1
	# If file doesn't exist...
	if {[catch "open $filepath r" f]} {
		# Try to create it.
		if {[set f [ open $filepath w]]==""} {
			# Abort if can't create
			return 1
		}
		# If could create, close the file, then reopen for reading.
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 2
		}
	}
	if {![file exists $filepath]} {
		return 3
	}
	file stat $filepath finfo
	set inode $finfo(ino)
        set mq(inode) $inode
        set filepath2 $filepath
        set f2 $f
	set tf_searchstr ""
	set tf_sd +
	set tf_sp 1.0
	set tf_f(switch) 0
#	set tf_f(switch) 1
	set mq(filep) $f
        mq_tailfile_update $filepath $f $inode  
}

proc mq_tailfile_stop {filepath f} {
	global mq
	if {$mq(DEBUG)=="on"} {
	    puts " in mq_tailfile_stop\n"
	}

        catch { 
#		close $f
		global tf_p
		unset tf_p($filepath)
	      }	 	
}

proc mq_tailfile_update {filepath f inode} {
	global junkflag tf_f mq
	if {$mq(DEBUG)=="on"} {
	    puts " in mq_tailfile_update\n"
	}
        if {$mq(update)==1} {
	  if {$mq(tail)==1 && $mq(currentfiletext)!="" && $mq(auto)==0} {
	    set mq(auto) 1
   	    auto_step
          }   

        # If Follow mode has been set, then read rest of file and insert into
	#  text widget
	# The catch will handle delayed tailfile update calls once file has been eliminated
          if {[catch {
  	    while {[gets $f linebuf]> -1 } {
#		if {$mq(mode)!="static"} {	
#		  puts "modenot=static!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  set linebuf [append linebuf "\n"]
                  set mq(currentfiletext) [append mq(currentfiletext) $linebuf]
	          set mq(filetext)  [append mq(filetext) $linebuf]
#                }
	    }
          }]!=0} { 
            return
          }
	  if [catch {file stat $filepath finfo}] {
		tk_dialog .tmptf ERROR "File $filepath disappeared." error 0 OK
		close $mq(filep)
##################
	       set mq(auto) 0
	       set x [start_mq_tail $filepath]
               while {[gets $mq(filep) linebuf]> -1 } {
                  set linebuf [append linebuf "\n"]
                  set mq(currentfiletext) [append mq(currentfiletext) $linebuf]
               }
               set mq(filetext) $mq(currentfiletext)
 	       mq_tailfile_stop $filepath $mq(filep) 
 	       set mq(auto) 0
               set mq(tail) 0
#    Initilize scanned variable
               set mq(scanned) 0
               process_one_msg
               set mq(scanned) 0
               set mq(mode) "static"
  	       .f3.direc.btn1a configure -state disabled
  	       .f3.direc.btn1b configure -state active
               set mq(direction) 1
               .f3.btn2 configure -state active
               .f3.btn3 configure -state active
               .f3.btn4 configure -state active
               .f3.btn5 configure -state active
               .f3.btn6 configure -state active
               .f3.btn8 configure -state active
    	       set mq(update) 0			
 	       return

###################
	  }
	  if {![file exists $filepath]} {
		after 500 "mq_tailfile_update $filepath $f $inode "
	  }
	  if {$inode != $finfo(ino)} {
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 4
		} 
		file stat $filepath finfo
		set inode $finfo(ino)
	  }
	  after 500 "mq_tailfile_update $filepath $f $inode "
#	  set wh [lindex [$tfwin configure -height] 4]
	  # Check to see if follow mode has been set
        } 
	
	}



##############################################################

global env mq

#########

global sesscount

set sesscount 0

###############
set mq(filetext) ""
set mq(active) 0
set mq(auto) 0
set mq(scanned) 0
set mq(viewmode) graphical
set mq(msgtotal) 0
set mq(bkpt,nonzero) 0
set mq(bkpt,sender) 0
set mq(bkpt,receive) 0
set mq(bkpt,user) 0
set mq(srvlist) [list]
set mq(centersrv) ""						
set mq(centersrvnew) ""						
set mq(filename) ""
set mq(inode) ""
set mq(currentfiletext) ""
set mq(nextmsgnum) 0
set mq(direction) 1
set mq(msg,0) ""
set mq(bottext) 1
set mq(tail) 0
set mq(filep) ""
set mq(mode) "static"
set mq(update) 0
set mq(canvcommand) 1
set mq(secs,0) ""
set mq(DEBUG) "off"
set mq(delay) 800
setupGUI
#bind all <Enter> {
#  puts "Entering %W"
#}

#  .f1.mcanvas1 create image 150 125 -image server -anchor nw
#  pack .f1.mcanvas1 -side left -fill both -expand 1


set balloonwidget ""
set balloonid ""
set balloonhelp(msgtype) "Selects type of message to send to server."

bind all <Enter> { catch {
	#tkButtonEnter %W
	global balloonid balloonwidget

			#[focus]=="" || 
			#[winfo toplevel [focus]]!=[winfo toplevel %W]
	if {$balloonwidget=="%W" || [winfo toplevel %W]==".balloon"} {
		return
	}
	set tl [winfo toplevel %W]
	set focus [focus]
	if {$focus!=""} {
		set focus [winfo toplevel $focus]
	}
	set bh_image ""
	set bh_text ""
	if {[lsearch [%W configure] "-image *"]>=0} {
		set bh_image [%W cget -image]
	}
	if {[lsearch [%W configure] "-text *"]>=0} {
		set bh_text [%W cget -text]
	}
	if {$bh_image!="" && $bh_text!=""} {
		catch {after cancel $balloonid}
		set balloonid [after 1000 "show_balloon_help %W {$bh_text}"]
		set balloonwidget %W
	} elseif {[info exists balloonhelp([winfo name %W])]} {
		catch {after cancel $balloonid}
		set balloonid [after 1000 "show_balloon_help %W {$balloonhelp([winfo name %W])}"]
		set balloonwidget %W
	} else {
	}
	#break
}}

bind all <Leave> {
	#tkButtonLeave %W
	global balloonwidget balloonid
	catch {after cancel $balloonid}
	if {[winfo exists .balloon]} {
		destroy .balloon
	}
	#break
}

bind all <ButtonPress> {
	global balloonwidget balloonid
	catch {after cancel $balloonid}
	catch {destroy .balloon}
}

bind Text <Control-Key-x> "[bind Text <<Cut>>]"
bind Text <Control-Key-c> "[bind Text <<Copy>>]"
bind Text <Control-Key-v> "[bind Text <<Paste>>]"
bind Entry <Control-Key-x> "[bind Entry <<Cut>>]"
bind Entry <Control-Key-c> "[bind Entry <<Copy>>]"
bind Entry <Control-Key-v> "[bind Entry <<Paste>>]"

proc show_balloon_help {wn text} {
	global balloonwidget
	catch {destroy .balloon}
	toplevel .balloon 
	message .balloon.text -text $text -bg #FFFF99 -width 100
	pack .balloon.text
	set bw [winfo reqwidth .balloon.text]
	set bh [winfo reqheight .balloon.text]
	set xp [winfo rootx $wn]
	set yp [expr [winfo rooty $wn]+[winfo height $wn]]
	set sw [expr [winfo screenwidth $wn] - 55]
	set sh [expr [winfo screenheight $wn] - 55]
	if {[expr $xp+$bw]>$sw} {
		set xp [expr $sw-$bw]
	}
	if {[expr $yp+$bh]>$sh} {
		set yp [expr $sh-$bh]
	}
	wm geometry .balloon +$xp+$yp
	wm overrideredirect .balloon 1
	update idletasks
	raise .balloon
}





proc mqt_resend_select {} {
   global btn mq

   
 if {[winfo exists .resend]} {
     raise .resend
     return
 } else {
   	toplevel .resend
   	wm title .resend "MQTrace Resend"
   	label .resend.title -text "MQTrace Resend" 
   	label .resend.spacer -text " " 
   	frame .resend.r1 -relief sunken -bd 3

   	label .resend.r1.sectitle -text "Select server(s) names; blank to remove."  -foreground navy 
 	label .resend.r1.tolabel -text "Resend all log messages that are sent TO server:"
    	entry .resend.r1.toname -width 15 -text sdata -textvariable mq(resendto) -justify left

 	label .resend.r1.frlabel -text "Resend all log messages that are sent FROM server:"
    	entry .resend.r1.fromname -width 15 -text sdata -textvariable mq(resendfr) -justify left
   	label .resend.r1.spacer2 -text " " 

	frame .resend.f5
 	button .resend.f5.ok -text "Ok" -command "set btn ok"
  	button .resend.f5.cancel -text "Cancel" -command "set btn cancel"

   	pack .resend.title -pady 8
	pack .resend.r1 -expand 1 -fill both
 	pack .resend.spacer
	pack .resend.r1.sectitle -pady 5
	pack .resend.r1.tolabel -anchor w
   	pack .resend.r1.toname 
	pack .resend.r1.frlabel -anchor w
    	pack .resend.r1.fromname
	pack .resend.r1.spacer2 -anchor w -pady 5
 	pack .resend.f5.ok -side left
   	pack .resend.f5.cancel -side left
   	pack .resend.f5 
 

   	bind .resend  <Return> { set btn ok }
  	bind .resend  <Escape> { set btn cancel }
 
   	wm geometry .resend +[expr [winfo rootx .]+100]+[expr [winfo rooty .]+30]

   	# wait for button or key bindings
   	tkwait variable btn
   	focus .resend
	
     
   	if {$btn=="ok"} {
  
  		if {$mq(resendto)=="" && $mq(resendfr)==""} {
			set mq(resend) 0
            .mbar.tools.t entryconfigure "Resend msgs" -state active
            .mbar.tools.t entryconfigure "Stop resend msgs" -state disabled

		} else {
			set mq(resend) 1
            .mbar.tools.t entryconfigure "Stop resend msgs" -state active

		}
		
       		destroy .resend
   	} 
   	if {$btn=="cancel"} {
       		destroy .resend
   	}

 } 
 return

}




proc resend {message} {
	global mq

	if {[string first "fr=" $message] != -1 && \
	    [string first "to=" $message] != -1 } {

	#an_cmd lg name=[dv_get >name]_verb msg="Sending msg"
	set frtag [string range $message [string first "fr=" $message] end]
	set msgcontents $frtag
	set firstwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
	set frtag [string range $frtag [expr [string first " " $frtag] +1] end]
	set secondwd [string range $frtag 0 [expr [string first " " $frtag] -1] ] 
	set frserver [string range $firstwd 3 end]
	set toserver [string range $secondwd 3 end]

	#an_cmd lg name=[dv_get >name]_verb msg="frserver=$frserver toserver=$toserver"

	#Search for tag hexdump=.  If found, send this raw.  If not send the real message raw.
	#set hexdump [string first "hexdump=" $message]
	# Autonet message, just send it.

	if { ( $mq(resendto) != "" && $mq(resendto)==$toserver ) || \
	     ( $mq(resendfr) != "" && $mq(resendfr)==$frserver ) } {
	     
		an_cmd lg name=[dv_get >name]_verb msg="Resending message to: $toserver or fr: $frserver"

		set ishex [string first "hexdump=" $message]
		if {$ishex == -1} {
			#an_cmd lg name=[dv_get >name]_verb msg="Sending Autoshell"
			#an_cmd lg name=[dv_get >name]_verb msg="msg=$msgcontents"
			an_cmd msgsend route=$toserver msg="$msgcontents" raw
		} else {
			set hexstring [string range $message [expr $ishex + 8] end]
			#an_cmd lg name=[dv_get >name]_verb msg="Sending hex"
			#an_cmd lg name=[dv_get >name]_verb msg="hexstring=$hexstring"
			an_cmd msgsend route=$toserver raw mtype=1 hex=$hexstring
		}
	

	}
	
		
	}
	return

}





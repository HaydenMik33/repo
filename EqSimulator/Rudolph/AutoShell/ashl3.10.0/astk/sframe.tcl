
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

######
###### sframe.tcl
######
######   pure tcl/tk solution to implement a scrolled frame
######
######   may specify whether to have horizontal or vertical scrollbars
######   or any combination of the two
######
######   also may specify the height/width of the frame
######
######   returns a scrollable frame
######
######  bugs:  VFirstUnit/HFirstUnit should be made to be widget specific
######         ie., $win_VFirstUnit / $win_HFirstUnit
######
#set VFirstUnit 0
#set HFirstUnit 0

# This proc assumes that "win" is the name of the window in which you want
# the new scrollable frame packed.  Use the return of this proc as the 
# name of the scrolled frame.

proc sframe {win {dohor 1} {dover 1} {height 50} {width 50}} {
   global HFirstUnit VFirstUnit RHeight RWidth 
	set VFirstUnit($win) 0
	set HFirstUnit($win) 0
	set RHeight($win) $height
	set RWidth($win) $width

   # if they don't want either one, give them back a normal frame
   if {$dohor == 0 && $dover == 0} {
      return [frame $win.f1 -height $height -width $width ]
   }

   # need to create a frame if they passed in a toplevel instead of a frame
   if {"$win" == "."} {
      frame .foo
      pack .foo
      set win ".foo"
   }

   # setup a scrollbar to use for moving the clipping window
   if {$dohor} {
      scrollbar $win.hscb -orient horizontal -command "sfr_doScroll $win x"
      pack $win.hscb -fill x -side bottom
   }
   if {$dover} {
      scrollbar $win.vscb -orient vertical   -command "sfr_doScroll $win y"
      pack $win.vscb -fill y -side right
   }
 
   # This is the "window" through which part of the "real" frame is shown
   frame $win.clip -height $height -width $width 
   pack  $win.clip -fill both -expand 1
 
   # This is the real frame in which your stuff gets packed.  It slides
   # around behind the clipping frame to provide the "scrolling"
   frame $win.clip.tmp -height $height -width $width 
 
   # We have to reset the scrollbar whenever either the clipping window or
   # the scrolling window are resized.
   bind $win.clip.tmp <Configure> \
	"global HFirstUnit VFirstUnit
	 #puts {Configure state=%s win=%W}
	 sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
   bind $win.clip     <Configure> \
	"global HFirstUnit VFirstUnit
	 #puts {Configure state=%s win=%W}
	 sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
   bind $win.clip.tmp <Visibility> \
	"global HFirstUnit VFirstUnit
	 #puts {Visibility state=%s win=%W}
	 sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
   bind $win.clip     <Visibility> \
	"global HFirstUnit VFirstUnit
	 #puts {Visibility state=%s win=%W}
	 sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
#   bind $win.clip.tmp <Expose> \
#	"sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
#   bind $win.clip     <Expose> \
#	"sfr_doScroll $win \$HFirstUnit($win) \$VFirstUnit($win)"
   #pack  $win.clip.tmp -side left 

   return $win.clip.tmp
}

proc sfr_update {win} {
	global HFirstUnit VFirstUnit
	#puts {Update state=%s win=%W}
	sfr_doScroll $win $HFirstUnit($win) $VFirstUnit($win)
}

proc sfr_doScroll {win arg1 arg2} {
   global HFirstUnit VFirstUnit RHeight RWidth
		set RHeight($win) [winfo height $win.clip]
		set RWidth($win) [winfo width $win.clip]
   if {$arg1 == "x"} {sfr_doRealScroll $win $arg2 $VFirstUnit($win) ; return}
   if {$arg1 == "y"} {sfr_doRealScroll $win $HFirstUnit($win) $arg2 ; return}
   sfr_doRealScroll $win $arg1 $arg2
}

proc sfr_doRealScroll {win x y} {
   global VFirstUnit HFirstUnit RHeight RWidth

   # totalUnits is an integer proportional to the height of .clip.tmp
   set v_totalUnits [expr int([winfo reqheight $win.clip.tmp]/10)]
   set h_totalUnits [expr int([winfo reqwidth  $win.clip.tmp]/10)]
	#puts "v_totalUnits=$v_totalUnits h_totalUnits=$h_totalUnits"

   # windowUnits is an integer which is proportional to the amount of
   # .clip.tmp which is actual visible.  If totalUnits is, say, 100, and exactly
   # half of .clip.tmp is visible within .clip, then windowUnits will be 50.
   set v_windowUnits [expr int([winfo height $win.clip]/10)]
   set h_windowUnits [expr int([winfo width  $win.clip]/10)]
	#puts "v_windowUnits=$v_windowUnits h_windowUnits=$h_windowUnits"
 
   # Limit the range of y so that we don't scroll too far up or down.
   if {$y + $v_windowUnits > $v_totalUnits} {
     set y [expr {$v_totalUnits - $v_windowUnits}]
   }
   if {$y < 0} { set y 0 }
   set VFirstUnit($win) $y
 
   # Limit the range of x so that we don't scroll too far left or right.
   if {$x + $h_windowUnits > $h_totalUnits} {
     set x [expr {$h_totalUnits - $h_windowUnits}]
   }
   if {$x < 0} { set x 0 }
   set HFirstUnit($win) $x
 
   # Adjust the position of the scrollbar thumb
   if {[winfo exists $win.hscb]} {
      $win.hscb set $h_totalUnits $h_windowUnits $x [expr $x + $h_windowUnits]
   }
   if {[winfo exists $win.vscb]} {
      $win.vscb set $v_totalUnits $v_windowUnits $y [expr $y + $v_windowUnits]
   }
 
  # Adjust the position of .clip.tmp within the clipping window .clip
	#puts "placing $win.clip.tmp"
  place $win.clip.tmp -anchor nw -relheight 1 \
      -y [expr -10 * $y] \
      -x [expr -10 * $x] \
     -height [winfo reqheight $win.clip.tmp] \
     -width  [winfo reqwidth  $win.clip.tmp]
#	-height [expr $RHeight($win) + 50] \
#	-width  [expr $RWidth($win) + 50]

}

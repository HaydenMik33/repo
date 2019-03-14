
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

set VFirstUnit 0
set HFirstUnit 0

proc scrollframe {win args} {
   global HFirstUnit VFirstUnit

	set dohor 0
	set dover 0
	set height 50
	set width 50
	set numargs [llength $args]
	for {set i 0} {$i<$numargs} {incr i} {
		set option [lindex $args $i]
		if {[string index $option 0]=="-"} {
			set option [string range $option 1 end]
			switch $option {
				"horizontal" {
					set dohor 1
				}
				"vertical" {
					set dover 1
				}
				"height" {
					incr i
					set height [lindex $args $i]
				}
				"width" {
					incr i
					set width [lindex $args $i]
				}
			}

		}
	}
  
   # if they don't want either one, give them back a normal frame
   if {$dohor == 0 && $dover == 0} {
      return [frame $win -height $height -width $width]
   }

   frame $win -height $height -width $width
   # setup a scrollbar to use for moving the clipping window
   if {$dohor} {
      scrollbar $win.hscb -orient horizontal -command "scrollframe_doScroll $win x"
      pack $win.hscb -fill x -side bottom
   }
   if {$dover} {
      scrollbar $win.vscb -orient vertical   -command "scrollframe_doScroll $win y"
      pack $win.vscb -fill y -side right
   }
 
   # setup a clipping window
   frame $win.clip -height $height -width $width
   pack  $win.clip -fill both -expand 1
 
   frame $win.clip.tmp -height $height -width $width
   pack  $win.clip.tmp -side left
 
   # We have to reset the scrollbar whenever either the clipping window or
   # the scrolling window are resized.
   bind $win.clip.tmp <Configure> "scrollframe_doScroll $win \$HFirstUnit \$VFirstUnit"
   bind $win.clip     <Configure> "scrollframe_doScroll $win \$HFirstUnit \$VFirstUnit"

   return $win.clip.tmp
}

proc scrollframe_doScroll {win arg1 arg2} {
   global HFirstUnit VFirstUnit
   if {$arg1 == "x"} {scrollframe_doRealScroll $win $arg2 $VFirstUnit ; return}
   if {$arg1 == "y"} {scrollframe_doRealScroll $win $HFirstUnit $arg2 ; return}
   scrollframe_doRealScroll $win $arg1 $arg2
}

proc scrollframe_doRealScroll {win x y} {
   global VFirstUnit HFirstUnit

   # totalUnits is an integer proportional to the height of .clip.tmp
   set v_totalUnits [expr int([winfo reqheight $win.clip.tmp]/10)]
   set h_totalUnits [expr int([winfo reqwidth  $win.clip.tmp]/10)]

   # windowUnits is an integer which is proportional to the amount of
   # .clip.tmp which is actual visible.  If totalUnits is, say, 100, and exactly
   # half of .clip.tmp is visible within .clip, then windowUnits will be 50.
   set v_windowUnits [expr int([winfo height $win.clip]/10)]
   set h_windowUnits [expr int([winfo width  $win.clip]/10)]
 
   # Limit the range of y so that we don't scroll too far up or down.
   if {$y + $v_windowUnits > $v_totalUnits} {
     set y [expr {$v_totalUnits - $v_windowUnits}]
   }
   if {$y < 0} { set y 0 }
   set VFirstUnit $y
 
   # Limit the range of x so that we don't scroll too far left or right.
   if {$x + $h_windowUnits > $h_totalUnits} {
     set x [expr {$h_totalUnits - $h_windowUnits}]
   }
   if {$x < 0} { set x 0 }
   set HFirstUnit $x
 
   # Adjust the position of the scrollbar thumb
   if {[winfo exists $win.hscb]} {
      $win.hscb set $h_totalUnits $h_windowUnits $x [expr $x + $h_windowUnits]
   }
   if {[winfo exists $win.vscb]} {
      $win.vscb set $v_totalUnits $v_windowUnits $y [expr $y + $v_windowUnits]
   }
 
  # Adjust the position of .clip.tmp within the clipping window .clip
  place $win.clip.tmp -anchor nw -relheight 1 \
      -y [expr -10 * $y] \
      -x [expr -10 * $x] \
     -height [winfo reqheight $win.clip.tmp] \
     -width  [winfo reqwidth  $win.clip.tmp]
}

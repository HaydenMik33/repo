
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: see.tcl,v 1.3 1997/12/05 17:13:46 karl Exp $
# $Log: see.tcl,v $
# Revision 1.3  1997/12/05 17:13:46  karl
# Fixed caused by previous fix to force floating point math.
#
# Revision 1.2  1997/11/11  21:49:22  karl
# Added .0 to force floating point math at make_visible routine.  Something
# changed in TK 4.2 to make this necessary, I think.
#
# Revision 1.1  1996/08/27  16:17:22  karl
# Initial revision
#
#
#!/util/solaris/bin/wish4.0

proc make_visible {canvas x y halo} {
   # find out max sizes of scrollregion
   set scrollxmax [lindex [$canvas cget -scrollregion] 2]
   set scrollymax [lindex [$canvas cget -scrollregion] 3]

   # get the x and y position in scroll region
   set posx [expr $x / ($scrollxmax+0.0)]
   set posy [expr $y / ($scrollymax+0.0)]

   # figure out the halo boundaries for point
   set haloxmin [expr [expr $x - $halo].0 / $scrollxmax]
   set haloymin [expr [expr $y - $halo].0 / $scrollymax]
   set haloxmax [expr [expr $x + $halo].0 / $scrollxmax]
   set haloymax [expr [expr $y + $halo].0 / $scrollymax]

   # find out the current view boundaries
   set viewxmin [lindex [$canvas xview] 0]
   set viewymin [lindex [$canvas yview] 0]
   set viewxmax [lindex [$canvas xview] 1]
   set viewymax [lindex [$canvas yview] 1]
   set viewxmin [expr [expr round([expr $viewxmin * 100])].0 / 100]
   set viewymin [expr [expr round([expr $viewymin * 100])].0 / 100]
   set viewxmax [expr [expr round([expr $viewxmax * 100])].0 / 100]
   set viewymax [expr [expr round([expr $viewymax * 100])].0 / 100]

   # find out the size of the view
   set viewxsize [expr $viewxmax - $viewxmin]
   set viewysize [expr $viewymax - $viewymin]

   # if already displayed, return
   set displayed true
   if {$displayed == "true" && ($haloxmin <= $viewxmin)} { set displayed false }
   if {$displayed == "true" && ($haloymin <= $viewymin)} { set displayed false }
   if {$displayed == "true" && ($haloxmax >= $viewxmax)} { set displayed false }
   if {$displayed == "true" && ($haloymax >= $viewymax)} { set displayed false }
   if {$displayed == "true"} { return }
 
   # else center the position within the window
   $canvas xview moveto [expr $posx - [expr $viewxsize / 2]]
   $canvas yview moveto [expr $posy - [expr $viewysize / 2]]
}

proc ignore {} {
   canvas .canvas -width 300 -height 300 -relief raised -bd 2\
      -yscrollcommand ".scrolly set" -xscrollcommand ".scrollx set" \
      -scrollregion "0 0 600 600"
   scrollbar .scrollx -command ".canvas xview " -orient horizontal
   scrollbar .scrolly -command ".canvas yview " -orient vertical
   pack .scrolly -side right -fill y
   pack .scrollx -side bottom -fill x
   pack .canvas

   .canvas create rectangle 100 100 200 200 -fill green
   .canvas create rectangle 300 300 400 400 -fill blue
   .canvas create rectangle 500 500 580 580 -fill red

   bind . <1> {
      puts "making blue square visible"
      make_visible .canvas 300 300 10
   }
   bind . <2> {
      puts "making green square visible"
      make_visible .canvas 150 150 10
   }
   bind . <3> {
      puts "making red square visible"
      make_visible .canvas 540 540 10
   }
}
#ignore

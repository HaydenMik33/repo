
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: mlb.tcl,v 1.1 1996/08/27 16:15:30 karl Exp $
# $Log: mlb.tcl,v $
# Revision 1.1  1996/08/27 16:15:30  karl
# Initial revision
#
#!/opt/misc/bin/wish4.0
### 
### mlb.tcl
###
### A multi-column listbox widget.
###
### input  : object name, columns, optional args
### output : modeled like listbox widget
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -scrollable)
### scrollable - make the list box scrollablej
### mesg       - text message to show above box
### entries    - list of entries to put in the box initially
###              of the following form:
###              {{row 1 items} {row 2 items} {row 3 items} ...}
###
### example:
### multilistbox .mlb 2 -scrollable 
### .mlb configure -height 10
### .mlb configure -font 6x13 
### .mlb configure -mesg "hello there" 
### .mlb configure -entries {{a 2 3 b} {4 5 6 7} {1} {2}} 
### .mlb configure -selectmode multiple
### pack .mlb
### .mlb insert end {foo ""}
### .mlb insert end {bar ""}
### .mlb insert end [list "($ test)" ""]
### puts [.mlb size]
### puts [.mlb get 0 end]
### puts [lindex [lindex [.mlb get 0 end] 2] 0]
### puts [lindex [.mlb get 2 2] 0]
###
### Last edited:    04/30/96     09:15
###          by:    Guy M. Saenger
###
########
proc mlb_boxcount {w} \
{
   set boxcount [llength [winfo children $w.box]]
   if {[winfo exists $w.box.scroll]} { incr boxcount -1 }
   return $boxcount
}
########
proc mlb_scroll {w args} \
{
   for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
   { 
      eval "$w.box.list$i yview $args"
   }
}
########
proc mlb_bind {list} \
{
	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateCommand tkListboxBeginSelect
		tk::unsupported::ExposePrivateCommand tkListboxMotion
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   bind $list <1> \
   {+
      set w [winfo parent [winfo parent %W]]
      for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
      { 
         tkListboxBeginSelect $w.box.list$i [%W index @%x,%y] 
      }
      break
   }

   bind $list <B1-Motion> \
   {+
      set w [winfo parent [winfo parent %W]]
      for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
      {
         tkListboxMotion $w.box.list$i [%W index @%x,%y]
         set tkPriv(listboxPrev) -1
      }
      break
   }
}
########
proc mlb_handler {w args} \
{
   set args [lindex $args 0]
   case [lindex $args 0] \
   {
      configure { mlb_configure $w [lrange $args 1 end] }
      insert \
      {
         set index [lindex $args 1]
         set vals  [lindex $args 2]
         for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
         {
            set entry [lindex $vals $i]
            $w.box.list$i insert $index $entry
            if {[llength $entry] == 0 && $entry != ""} \
               { $w.box.list$i insert $index "" }
         }
         return ""
      }
      default \
      { 
         set boxlist ""
         for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
         {
            lappend boxlist [eval "$w.box.list$i $args"]
         }
         set retlist ""
         for {set idx 0} {$idx < [llength [lindex $boxlist 0]]} {incr idx} \
         {
            set linelist ""
            foreach list $boxlist { lappend linelist [lindex $list $idx] }
            lappend retlist $linelist
         }
         if {[llength $retlist] == 1} { return [lindex $retlist 0] }
         return $retlist
      }
   }
}
########
proc mlb_configure {w args} \
{
   set args [lindex $args 0]

   set idx [lsearch $args "-scrollable"]
   if {$idx != -1} \
   {
      scrollbar $w.box.scroll -command "mlb_scroll $w"
      pack $w.box.scroll -side left -fill y
      for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
      {
         $w.box.list$i configure -yscrollcommand "$w.box.scroll set"
      }
      set args [lreplace $args $idx $idx]
   }

   set idx [lsearch $args "-font"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -font $val
   }

   set idx [lsearch $args "-mesg"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -text $val
      pack $w.mesg.label
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   set idx [lsearch $args "-entries"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      foreach set $val { $w insert end $set }
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   set idx [lsearch $args "-justify"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -justify $val
      case $val \
      {
         left   { pack $w.mesg.label -anchor w }
         right  { pack $w.mesg.label -anchor e }
         center { pack $w.mesg.label -anchor c }
      }
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   for {set i 0} {$i < [mlb_boxcount $w]} {incr i} \
   {
      eval "$w.box.list$i configure $args"
   }
}
########
proc multilistbox {w cols args} \
{

   frame   $w
   frame   $w.mesg
   label   $w.mesg.label
   frame   $w.box

   for {set i 0} {$i < $cols} {incr i} \
   {
      listbox $w.box.list$i -exportselection false
      pack $w.box.list$i -side left
      mlb_bind $w.box.list$i
   }

   pack $w.mesg           -fill both
   pack $w.box

   rename $w $w.old
   proc $w {args} "mlb_handler $w \$args"

   eval "mlb_configure $w \$args"

}
########

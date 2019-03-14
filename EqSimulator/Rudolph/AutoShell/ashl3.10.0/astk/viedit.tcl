
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: viedit.tcl,v 1.13 1999/08/24 15:40:22 karl Exp $
# $Log: viedit.tcl,v $
# Revision 1.13  1999/08/24 15:40:22  karl
# Took out middlemouse button handling.  TK already does this.
#
# Revision 1.12  1999/03/31  14:59:05  jasonm
# fixed mouse button cut/paste for vi editing mode
# (again!)
#
# Revision 1.11  1999/02/18  15:26:37  jasonm
# fixed remaining bugs in mouse selection. non-vi mode now works
# correctly
#
# Revision 1.10  1998/12/16  19:54:35  jasonm
# fixed mouse bindings so that cut and paste behaves properly (i.e., does
# not move the cursor, inserts text at the cursor)
#
# Revision 1.9  1997/10/21  21:02:28  love
# Added check to see if tcl_platform exists i.e. version > 7.6
# for backward compatibility.
#
# Revision 1.8  1997/10/13  19:26:38  love
# Ported to Windows NT.  <grave> and <apostrophe> are <quoteleft> and
# <quoteright> respectively on NT.
#
# Revision 1.7  1997/04/10  20:38:38  karl
# Fixed bug where :wq in VI edit mode would lose line continuations.
#
# Revision 1.6  1996/11/01  21:03:24  jasonm
# fixed some problems with the button 2 insert X-selection stuff
#
# Revision 1.5  1996/11/01  19:06:45  jasonm
# fixed a problem where cancelling a window w/o vi bindings caused a stack trace
#
# Revision 1.4  1996/10/30  16:56:34  jasonm
# changed status widget from a label to an entry, so that it wouldn't
# dynamically change it's size, and consequently the size of the window
#
# Revision 1.3  1996/10/29  22:42:08  karl
# Fixed bug with non-vibinding use of viedit since last update.
#
# Revision 1.2  1996/10/16  19:50:59  jasonm
# fixed the bindings for the "r" command. previously, a shift or control
# would confuse it. also added error checking to :wq, if vi_save doesn't
# return, correctly, it won't quit.
#
# Revision 1.1  1996/08/27  16:22:04  karl
# Initial revision
#
########## viedit.tcl
##########
########## This file contains code to implement a text widget with
########## VI-like bindings.
##########
########## Last edited:    08/07/96     12:37
##########          By:    Jason Mechler
##########                 changed it so the widget name specified when
##########                 viedit is called can be used and acts upon
##########                 the internal text widget, i.e., 
##########                 pack [viedit .test]; .test insert end "testing" 
##########                 works
##########
########## Last edited:    05/24/96     12:40
##########          By:    Dewayne McNair
##########                 fixed global bindings to only affect current
##########                 text widget, not Text class
##########
########## Last edited:    04/09/96     16:07
##########          By:    Dewayne McNair
##########                 fixed repeat command on 'cw' to work correctly
##########
########## Last edited:    03/26/96     10:55
##########          By:    Dewayne McNair
##########                 -vibindings off makes it act like a regular text
##########                 widget (no status, fileops, etc)
##########
########## Last edited:    03/22/96     15:55
##########          By:    Dewayne McNair
##########                 added option to change behaviour of button-1
##########                 and button-2 via the '-vibindings [on|off]'
##########                 switch
##########
########## Last edited:    03/21/96     11:32
##########          By:    Dewayne McNair
##########                 changed /-search to turn the selection on the match
##########
########## Last edited:    03/20/96     15:56
##########          By:    Dewayne McNair
##########                 changed 'dw' to work more like vi
##########
########## Last edited:    01/25/96     15:25
##########          By:    Dewayne McNair
##########                 added code to source a file that contains a
##########                 bug fix for the Text widget.  code located
##########                 near the bindings for the Text widget
##########
########## Last edited:    12/18/95     10:00
##########          By:    Dewayne McNair
##########                 implemented handling of a 'readonly' tag around
##########                 text.  Involved rewriting backup/undo code
##########                 as well as adding various other checks in most
##########                 of the code that performed deletions
##########
########## Last edited:    12/06/95     10:00
##########          By:    Dewayne McNair
##########                 replaced all 'puts' statements with an error dialog
##########
########## Last edited:    11/20/95     14:48
##########          By:    Dewayne McNair
##########                 fixed problem in 'eval_colon' with not being able
##########                 to exit with ':q!'
##########
########## Last edited:    10/27/95     14:00
##########          By:    Dewayne McNair
##########                 see the notes at the end of this file for
##########                 features and bugs
##########
########## Last edited:    08/28/95     13:50
##########          By:    Jason Mechler
##########
##########


#########################
#########################
set viedit_Usage_Notes {

Command Line Arguments
======================

viedit is supposed to act like a regular Tk widget.  It has a few
command line arguments of it's own.  The rest are passed to the
internal text widget.

  -scroll
     Determines whether or not a scrollbar will be added to the
     window.  Its value can be [yes,1,true | no,0,false]
     The default is yes.

  -vibindings
     Determines whether or not to invoke the bindings that make the
     text widget act like vi.  Its value can be [yes,1,true | no,0,false].
     The default is yes.
     If the value if no, only the -scroll option has any effects.

  -status 
     determines whether or not a status bar will be added at the
     bottom of the window.  Its value can be [yes,1,true | no,0,false].
     The default is yes.

  -fileops
     Determines whether the widget can destroy itself, and write file.
     i.e.,  is it embedded in another window, or in it's own toplevel.
     Its value can be [yes,1,true | no,0,false].
     The default is yes.

  -savecommand
     The command used to save the text in the window.  Doesn't make
     sense if fileops is not true.

When fileops is not true, the user can access the internal text widget
directly to input and retrieve text.  It can be referenced as 

    myVIWidgetName.text
}

proc viedit { w args }  {
   global viInfo env

   frame $w

   set t [text $w.text -relief sunken -bd 1 -takefocus 1]

   set stat yes
   set scroll yes
   set fileops yes
   set vibindings yes
   set viInfo($t,status)        "Insert Mode"
   set viInfo($t,status_plus)   0
   set viInfo($t,num_repeat)    0
   set viInfo($t,linenum)       0
   set viInfo($t,modified)      0
   set viInfo($t,search_state)  0
   set viInfo($t,search_string) ""
   set viInfo($t,savecommand)   ""
   set viInfo($t,last_txt)      {}
   set viInfo($t,last_cmd)      insert
   set viInfo($t,backup_insert) ""
   set viInfo($t,backup_string) ""

   for {set i 0} {$i < [llength $args]} {incr i 2}  {
      set option [lindex $args $i]
      set value [lindex $args [expr $i+1]]
      if {$option == "-status"}  {
         set stat $value
      } elseif {$option == "-scroll"}  {
         set scroll $value
      } elseif {$option == "-fileops"}  {
         set fileops $value
      } elseif {$option == "-savecommand"}  {
         set viInfo($t,savecommand) $value
      } elseif {$option == "-vibindings"}  {
         set vibindings $value
      } else {
         $t configure $option $value
      }
   }

   if {($scroll == "yes") || ($scroll == "1") || ($scroll == "true")}  {
      scrollbar $w.scroll -command "$w.text yview"
      pack $w.scroll -side right -fill y
      $t configure -yscrollcommand "$w.scroll set"
   }

   if {($fileops == "yes") || ($fileops == "1") || ($fileops == "true")}  {
	   set viInfo($t,fileops) 1
   } else {
	   set viInfo($t,fileops) 0
   }
	
   # fix_text_button_behavior $t
   # fix_text_button2_release $t

   # if they don't want the vi bindings return now
   if {$vibindings == "no" || $vibindings == 0 || $vibindings == "false"}  {
	   pack $t -side right -fill both -expand yes 
	   update
   } else {

	   # additional bindings for the regular text mode
	   bind text_bindings   <Escape>        {chk_txt %W ; do_vi %W }
	   bind text_bindings   <KeyPress>      {text_put_char %W %A  ; break }
	   bind text_bindings   <BackSpace>     {text_put_char %W "\b"; break }
	   bind text_bindings   <Return>        {text_put_char %W "\n"; break }
	   bind text_bindings   <Control-j>     {text_put_char %W "\n"; break }
	   bind text_bindings   <Control-c>     {bell ; do_vi %W}
	   bind text_bindings   <Delete>        {
		   if {[%W tag nextrange sel 1.0 end] != ""} {
			   set range [%W tag ranges sel]
			   if {! [check_readonly_range %W $range]} {
				   %W delete sel.first sel.last
			   }
		   } else {
			   if {! [check_readonly %W]} {
				   %W delete insert
				   %W see insert
			   }
		   }
	   }
	   
	   #do_normal $t
	   do_vi $t
	   
	   # puts "$t"
	   
	   if {($stat == "yes") || ($stat == "1") || ($stat == "true")}  {
		   label .viedit_color
		   set mycolor [.viedit_color cget -bg]
		   destroy .viedit_color
		   entry $w.status -textvariable viInfo($t,status) -relief sunken \
			   -bd 1 -bg $mycolor
		   pack $w.status -side bottom -fill x
	   }
	   
	   pack $t -side right -fill both -expand yes 
	   update
   }
	
	bind $w <Destroy> "rename $w {}"
	
	rename $w ${w}old
	proc $w { args }  "return \[eval $t \$args\]"
	return $w
}

####################
#################### bindings for mouse selection
####################

# we don't want the mouse to move around the insert mark for any of the
# modes

	global tk_version
if { $tk_version >= 8.4 } {
	tk::unsupported::ExposePrivateCommand tkTextSelectTo
	tk::unsupported::ExposePrivateVariable tkPriv
}
foreach mode [list Replace_bindings apost_bindings change_bindings \
	colon_bindings delete_bindings grave_bindings mark_bindings \
	replace_bindings search_bindings vi_bindings yank_bindings \
	text_bindings] {

	bind $mode	<1>		{
		set mark [lindex [%W dump -mark insert] 2]
		viTextButton1 %W %x %y
		%W tag remove sel 0.0 end
		%W mark set insert $mark
		break
	}
	bind $mode	<B1-Motion> {
		set tkPriv(x) %x
		set tkPriv(y) %y
		set mark [lindex [%W dump -mark insert] 2]
		tkTextSelectTo %W %x %y
		%W mark set insert $mark
		break
	}
	bind $mode	<Double-1> {
		set tkPriv(selectMode) word
		set mark [lindex [%W dump -mark insert] 2]
		tkTextSelectTo %W %x %y
		%W mark set insert $mark
		break
	}
	bind $mode	<Triple-1> {
		set tkPriv(selectMode) line
		set mark [lindex [%W dump -mark insert] 2]
		tkTextSelectTo %W %x %y
		%W mark set insert $mark
		break
	}
}

# for the normal mode, paste the selected text at the insert mark
#bind Text <ButtonRelease-2> {
#	%W insert insert [selection get -displayof %W]
#	if {[%W cget -state] == "normal"} {focus %W}
#	break
#}

# for the colon and search modes, paste the selected text into the
# status bar
bind colon_bindings <ButtonRelease-2> {
	append_colon %W [selection get -displayof %W]
	break
}
bind search_bindings <ButtonRelease-2> {
	append_search %W [selection get -displayof %W]
	break
}

####################
#################### bindings for vi command mode
####################

bind vi_bindings
bind vi_bindings    <2>  { break }
bind vi_bindings	<3>		{ break }
bind vi_bindings    <KeyPress>      { ; break }
bind vi_bindings	<o>		{viopen %W   ; break }
bind vi_bindings	<O>		{viOpen %W   ; break }
bind vi_bindings	<i>		{insert %W   ; break }
bind vi_bindings	<I>		{Insert %W   ; break }
bind vi_bindings	<a>		{viappend %W ; break }
bind vi_bindings	<A>		{viAppend %W ; break }

bind vi_bindings	<BackSpace>	{char_move %W -1 ; chk_end %W ; break }
bind vi_bindings	<Left>		{char_move %W -1 ; chk_end %W ; break }
bind vi_bindings	<h>		{char_move %W -1 ; chk_end %W ; break }

bind vi_bindings	<space>		{char_move %W +1 ; chk_end %W ; break }
bind vi_bindings	<Right>		{char_move %W +1 ; chk_end %W ; break }
bind vi_bindings	<l>		{char_move %W +1 ; chk_end %W ; break }

bind vi_bindings	<Up>		{line_move %W -1 ; chk_end %W ; break }
bind vi_bindings	<k>		{line_move %W -1 ; chk_end %W ; break }
	
bind vi_bindings	<Return>	{line_move %W +1 ; chk_end %W ; break }
bind vi_bindings	<Down>		{line_move %W +1 ; chk_end %W ; break }
bind vi_bindings	<j>		{line_move %W +1 ; chk_end %W ; break }

bind vi_bindings	<Control-f>	{page_down %W      ; break }
bind vi_bindings	<Control-b>	{page_up   %W      ; break }
bind vi_bindings	<Control-e>	{line_down %W      ; break }
bind vi_bindings	<Control-d>	{half_page_down %W ; break }
bind vi_bindings	<Control-u>	{half_page_up %W   ; break }

bind vi_bindings        <asciicircum>   {
   %W mark set insert "insert linestart"
   goto_nonwhite %W
   break
}
bind vi_bindings        <minus>         {
   line_move %W -1
   %W mark set insert "insert linestart"
   goto_nonwhite %W
   break
}
bind vi_bindings        <plus>          {
   line_move %W +1
   %W mark set insert {insert linestart}
   goto_nonwhite %W
   break
}

bind vi_bindings        <H>             {goto_first  %W ; break }
bind vi_bindings        <KeyPress-M>    {goto_middle %W ; break }

bind vi_bindings	<w>		{word_right %W ; break }
# just mimik <W>
bind vi_bindings	<W>		{word_right %W ; break }
bind vi_bindings	<b>		{word_left %W  ; break }
# just mimik <b>
bind vi_bindings        <B>             {word_left %W  ; break }
bind vi_bindings	<e>		{word_end %W   ; break }
# just mimik <E>
bind vi_bindings	<E>		{word_end %W   ; break }
bind vi_bindings	<G>		{text_end %W   ; break }
bind vi_bindings	<dollar>	{line_end %W   ; break }

bind vi_bindings	<u>		{undo %W        ; break }
bind vi_bindings        <asciitilde>    {change_case %W ; break }
bind vi_bindings	<x>		{del_right %W   ; chk_end %W ; break }
bind vi_bindings	<X>		{del_left %W    ; break }
bind vi_bindings	<D>		{del_lineend %W ; break }
bind vi_bindings	<C>		{change_lineend %W ; break }
bind vi_bindings	<J>		{join_lines %W  ; break }

bind vi_bindings	<p>		{put_after %W  ; break }
bind vi_bindings	<P>		{put_before %W ; break }

bind vi_bindings	<s>		{subst_text %W ; break }
bind vi_bindings	<S>		{Subst_text %W ; break }
bind vi_bindings        <n>             {repeat_search %W 1 ; do_vi %W ; break }
bind vi_bindings        <N>             {repeat_search %W 0 ; do_vi %W ; break }

bind vi_bindings	<KeyPress-0>	{check_zero %W   ; break }
bind vi_bindings	<KeyPress-1>	{set_repeat %W 1 ; break }
bind vi_bindings        <KeyPress-2>    {set_repeat %W 2 ; break }
bind vi_bindings        <KeyPress-3>    {set_repeat %W 3 ; break }
bind vi_bindings        <KeyPress-4>    {set_repeat %W 4 ; break }
bind vi_bindings        <KeyPress-5>    {set_repeat %W 5 ; break }
bind vi_bindings        <KeyPress-6>    {set_repeat %W 6 ; break }
bind vi_bindings        <KeyPress-7>    {set_repeat %W 7 ; break }
bind vi_bindings        <KeyPress-8>    {set_repeat %W 8 ; break }
bind vi_bindings        <KeyPress-9>    {set_repeat %W 9 ; break }

bind vi_bindings	<d>		{do_delete %W    ; break }
bind vi_bindings	<c>		{do_change %W    ; break }
bind vi_bindings	<r>		{do_replace %W   ; break }
bind vi_bindings	<y>		{do_yank %W      ; break }
bind vi_bindings	<f>		{do_find %W      ; break }
bind vi_bindings	<R>		{do_Replace %W   ; break }

bind vi_bindings	<colon>		{do_colon %W     ; break }
bind vi_bindings        <slash>         {do_search %W f  ; break }
bind vi_bindings        <question>      {do_search %W b  ; break }
bind vi_bindings        <period>        {do_lastcmd %W   ; do_vi %W ; break }

bind vi_bindings        <m>             {bindtags %W mark_bindings  ; break}

if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
	bind vi_bindings        <quoteleft>     {bindtags %W grave_bindings ; break}
} else {
	bind vi_bindings        <grave>         {bindtags %W grave_bindings ; break}
}

if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
	bind vi_bindings        <quoteright>    {bindtags %W apost_bindings ; break}
} else {
	bind vi_bindings        <apostrophe>    {bindtags %W apost_bindings ; break}
}

bind vi_bindings        <Control-g>     {do_status  %W   ; break }
bind vi_bindings        <Shift-L>       {
   %W mark set insert [lindex [split [%W index @0,[winfo height %W]] .] 0].0
   break
}

###############
############### bindings for vi delete mode
###############

bind delete_bindings	<w>		{del_word_right %W 1 ; do_vi %W}
bind delete_bindings	<b>		{del_word_left %W    ; do_vi %W}
bind delete_bindings	<d>		{del_line %W         ; do_vi %W}
bind delete_bindings	<f>		{
   disp_error "df not implemented" .; 
   set viInfo(%W,status_plus) 0
   do_vi %W
}
bind delete_bindings	<dollar>	{del_lineend %W}

bind delete_bindings    <h>             {delete_h %W ; do_vi %W }
bind delete_bindings    <j>             {delete_j %W ; do_vi %W }
bind delete_bindings    <k>             {delete_k %W ; do_vi %W }
bind delete_bindings    <l>             {delete_l %W ; do_vi %W }

bind delete_bindings	<Escape>	{do_vi %W}


###############
############### bindings for vi change mode
###############

bind change_bindings	<w>		{change_word %W}
bind change_bindings	<dollar>	{change_lineend %W}
bind change_bindings	<f>		{
   disp_error "cf not implemented" .;
   set viInfo(%W,status_plus) 0
   do_vi %W
}
bind change_bindings	<c>	        {change_c %W ; do_normal %W }
bind change_bindings	<h>	        {change_h %W ; do_normal %W }
bind change_bindings	<j>	        {change_j %W ; do_normal %W }
bind change_bindings	<k>	        {change_k %W ; do_normal %W }
bind change_bindings	<l>	        {change_l %W ; do_normal %W }
bind change_bindings	<Escape>	{do_vi %W}


###############
############### bindings for vi yank mode
###############

bind yank_bindings	<w>		{yank_word %W}
bind yank_bindings	<dollar>	{yank_lineend %W}
bind yank_bindings	<y>		{yank_line %W}
bind yank_bindings	<f>		{
   disp_error "yf not implemented" .;
   set viInfo(%W,status_plus) 0
   do_vi %W
}

bind yank_bindings	<j>	        {yank_j %W ; do_vi %W }
bind yank_bindings	<k>	        {yank_k %W ; do_vi %W }
bind yank_bindings	<l>	        {yank_l %W ; do_vi %W }
bind yank_bindings	<h>	        {yank_h %W ; do_vi %W }

bind yank_bindings	<Escape>	{do_vi %W}

###############
############### bindings for vi colon mode
###############

bind colon_bindings	<Any-KeyPress>	{append_colon %W %A}
bind colon_bindings	<BackSpace>	{del_colon %W}
bind colon_bindings	<Return>	{eval_colon %W}
bind colon_bindings	<Escape>	{quit_colon %W}


###############
############### bindings for vi search mode
###############

bind search_bindings    <Any-KeyPress>  {append_search %W %A}
bind search_bindings    <BackSpace>     {del_search %W}
bind search_bindings    <Return>        {eval_search %W}
bind search_bindings    <Escape>        {eval_search %W}


###############
############### bindings for vi replace mode 
###############

bind replace_bindings   <Shift_L> { ; break }
bind replace_bindings   <Shift_R> { ; break }
bind replace_bindings   <Control_L> { ; break }
bind replace_bindings   <Control_R> { ; break }
bind replace_bindings	<Any-KeyPress>	{
   global viInfo

   backup %W
   set viInfo(%W,yank_buffer) %A
   replace_char %W
   do_vi %W
   set viInfo(%W,last_txt) %A
   set viInfo(%W,last_cmd) "replace_text %W"
}
bind replace_bindings	<Escape>      {do_vi %W}

bind Replace_bindings <Escape>        {
   global viInfo
   if {$viInfo(%W,got_bs)} { 
      set viInfo(%W,last_txt) $viInfo(%W,last_char)
      %W mark set save insert
      replace_text %W
      %W mark set insert save 
   }
   chk_txt %W
   do_vi %W
}
bind Replace_bindings <KeyPress>  {
   global viInfo
   set viInfo(%W,yank_buffer) %A
   set viInfo(%W,last_cmd) "replace_text %W"
   append viInfo(%W,last_txt) %A
   replace_char %W
   %W mark set insert "insert +1c"
}

###############
############### bindings for vi mark mode 
###############
bind mark_bindings      <Escape>        {do_vi %W}
bind mark_bindings      <KeyPress>      {set_mark  %W %A; break}

bind grave_bindings     <Escape>        {do_vi %W}
bind grave_bindings     <KeyPress>      {goto_mark  %W %A; break}

bind apost_bindings     <Escape>        {do_vi %W}
bind apost_bindings     <KeyPress>      {goto_Mark  %W %A; break}

#########################
#########################
###
### procedures to set up each mode
###
#########################
#########################

proc do_vi { t }  {
    global viInfo

    chk_end $t
    if {$viInfo($t,status_plus)} {
       set viInfo($t,status) "VI Command Mode : $viInfo($t,status)"
    } else {
       set viInfo($t,status) "VI Command Mode"
    }
	# why were text_bindings and Text in there?
    # bindtags $t {vi_bindings text_bindings Text}
    bindtags $t {vi_bindings }
	set viInfo($t,mode) vi
}

proc do_colon { t }  {
    global viInfo

    set viInfo($t,status) {:}
    set viInfo($t,colstr) ""
    bindtags $t {colon_bindings }
	set viInfo($t,mode) colon
}

proc do_search { t type }  {
    global viInfo
    
    if {$type == "f"}  {
	set viInfo($t,status) {/}
	set viInfo($t,search_type) "f"
	set viInfo($t,other_search_type) "b"
    } else {
	set viInfo($t,status) {?}
	set viInfo($t,search_type) "b"
	set viInfo($t,other_search_type) "f"
    }
    bindtags $t {search_bindings }
	set viInfo($t,mode) search
}

proc do_delete { t }  {
	global viInfo
    bindtags $t {delete_bindings }
	set viInfo($t,mode) delete
}

proc do_change { t }  {
	global viInfo
    bindtags $t change_bindings
	set viInfo($t,mode) change
}

proc do_normal { t }  {
    global viInfo

    set viInfo($t,status)      "Insert Mode"
    set viInfo($t,status_plus) 0
    set viInfo($t,last_txt)    ""
    bindtags $t {text_bindings Text}
	set viInfo($t,mode) normal
}

proc do_replace { t }  {
	global viInfo 
    bindtags $t {replace_bindings }
    set viInfo($t,mode) replace
}

proc do_yank { t }  {
	global viInfo
    bindtags $t {yank_bindings }
    set viInfo($t,mode) yank
}

# not implemented
proc do_find { t }  {
   disp_error "find... not implemented" .
   set viInfo(%W,status_plus) 0
}

proc do_Replace { t }  {
   global viInfo

   # forced to do the backup here since we treat each char seperatly
   # and still want to 'undo' from the whole process
   backup $t
   bindtags $t Replace_bindings
   set viInfo($t,mode) Replace
   set viInfo($t,last_char) ""
   set viInfo($t,last_txt) ""
}

# initiate the 'set mark' bindings
proc do_mark { t } {

   bindtags $t mark_bindings
   set viInfo($t,mode) mark
}



#########################
### procedure to repeat a given command
#########################

proc get_repeat { t }  {
    global viInfo

    if {$viInfo($t,num_repeat)}  {
	set i $viInfo($t,num_repeat)
    } else {
	set i 1
    }  

    set viInfo($t,num_repeat) 0

    return $i
}

proc repeat { t args }  {
    global viInfo

    if {$viInfo($t,num_repeat)}  {
    } else {set viInfo($t,num_repeat) 1}

    for {set i 0} {$i < $viInfo($t,num_repeat)} {incr i} {
	eval [lindex $args 0]
    }

    set viInfo($t,num_repeat) 0
}



#########################
### procedures for cursor movement
#########################

# move to the first non-white char on the current line
proc goto_nonwhite { t } {
   set char [$t get insert]
   while {($char == " ") || ($char == "\t")}  {
      $t mark set insert "insert +1c"
      set char [$t get insert]
   }
}

# move the specified number of characters
proc char_move { t n }  {
    
    set lineinfo [split [$t index insert] {.}]
    set line [lindex $lineinfo 0]
    set char [lindex $lineinfo 1]
    set lineend [string compare [$t index insert] \
		     [$t index {insert lineend -1c}]]
    set repeat [get_repeat $t]

    for {set i 0} {$i < $repeat} {incr i} {
	if {(($char == 0) && ($n < 0)) || (!($lineend) && ($n > 0))} {
          bell
	} else {
	    $t mark set insert "insert $n c"
	}
    }
}

# move the specified number of lines (n is the direction)
proc line_move { t n }  {
    global viInfo

    set curr_line    [lindex [split [$t index insert] .] 0]
    set last_line [expr [lindex [split [$t index end]    .] 0] - 1]
    set repeat [get_repeat $t]

    for {set i 0} {$i < $repeat} {incr i} {
	if {(($curr_line == 1) && ($n == -1)) || \
		(($curr_line == $last_line) && ($n == +1))}  { 
             bell
	} else {
            $t mark set insert "insert $n l"
        } 
    }
    $t yview -pickplace insert
}

proc word_right { t }  {
   global viInfo

   $t mark set insert "insert wordend +1c"
   set repeat [get_repeat $t]
   set char   [$t get insert]

   for {set i 0} {$i < $repeat} {incr i} {
      while {($char == "\t") || ($char == { }) || ($char == "\n")}  {
         $t mark set insert "insert +1c"

         # make sure we don't try to keep going past the end of file
         if {[$t index insert] != [$t index "end -1c"]} {
            set char [$t get insert]
         } else {
            $t mark set insert "insert -1c"
            bell
            break
         }
      }
   }
   $t yview -pickplace insert
}
	
proc word_left { t }  {
   global viInfo
    
   $t mark set insert "insert wordstart -1c"
   set repeat [get_repeat $t]

   set char [$t get insert]
   for {set i 0} {$i < $repeat} {incr i} {
      while {($char == "\t") || ($char == { }) || ($char == "\n") &&
             ([$t index insert] != [$t index "insert linestart"])} {
         $t mark set insert "insert -1c"
         set char [$t get insert]
      }
   }
   $t mark set insert {insert wordstart} 
   $t yview -pickplace insert
}

proc word_end { t }  {
   global viInfo
    
   set repeat [get_repeat $t]
  
   $t mark set insert "insert +1c" 
   set char [$t get insert]
   for {set i 0} {$i < $repeat} {incr i} {
      while {($char == "\t") || ($char == { }) || ($char == "\n")}  {
         if {[$t index insert] != [$t index "end -1c"]} {
            $t mark set insert "insert +1c"
            set char [$t get insert]
         } else {
            bell
            break
         }
      }
      $t mark set insert "insert wordend -1c"
   }
   chk_end $t
}

proc text_end { t }  {
   global viInfo
  
   set repeat $viInfo($t,num_repeat)
   set viInfo($t,num_repeat) 0

   # if the repeat is set, go to that line # in the file
   if {$repeat} {
      $t mark set insert $repeat.0
      set viInfo($t,num_repeat) 0
   # otherwise go to the end of the file
   } else {
      $t mark set insert "end -1l linestart"
   }
   $t yview -pickplace insert
}

proc line_end { t }  {
   global viInfo
  
   $t mark set insert "insert lineend -1c +[expr [get_repeat $t] - 1]l"
}

proc page_up { t }  {

    $t yview scroll -1 pages
    $t mark set insert "@0,[winfo height $t] linestart"
}

proc page_down { t }  {
   
    $t yview scroll 1 pages
    $t mark set insert @0,0
}

# scroll the page 1 line down (different from cursor down)
proc line_down { t }  {
   
    $t yview scroll 1 unit
    $t mark set insert @0,0
}

proc half_page_up { t }  {

    $t mark set insert @0,0
    $t yview scroll [expr 0 - [$t cget -height] / 2] units
    $t mark set insert @0,0
}

proc half_page_down { t }  {

    $t mark set insert @0,0
    $t yview scroll [expr [$t cget -height] / 2] units
    $t mark set insert @0,0
}    

# goto the middle line on the screen - ala 'M'
proc goto_middle { t } {
    $t mark set insert @0,[expr [winfo height $t] / 2]
}

# goto the first line on the screen - ala 'H'
proc goto_first  { t } {
    $t mark set insert @0,0
}

#########################
### procedures for inserting text
#########################

proc text_put_char  { t char }  {
   global viInfo

   if {$char == ""} {
      return
   }
   if {[$t tag nextrange sel 1.0 end] != ""} {
      set range [$t tag ranges sel]
      if {! [check_readonly_range $t $range]} {
         # $t delete sel.first sel.last
      } else {
         return
      }
   }
   set ok_to_insert 0
   set range [$t tag ranges readonly]
   for {set idx 0} {$idx < [llength $range]} {incr idx 2} {
      if {[lindex $range $idx] == [$t index insert]} {
         set ok_to_insert 1
      }
   }
   if {! [check_readonly $t] || $ok_to_insert} {
      switch -- $char {
         \b {
            # back the cursor up and see if we are in a readonly region
            $t mark set insert {insert -1c}
            if {[check_readonly $t]} {
               $t mark set insert {insert +1c}
               return
            }
            $t mark set insert {insert +1c}
            chop viInfo($t,last_txt)
            set viInfo($t,last_txt) $viInfo($t,last_txt)
            $t delete insert-1c
         }
         default {
            append viInfo($t,last_txt) $char
            $t insert insert $char
         }
      }
      $t yview -pickplace insert
   }
}

proc insert { t }  {

    backup $t
    do_normal $t
}

proc Insert { t }  {

    backup $t
    $t mark set insert "insert linestart"
    goto_nonwhite $t
    do_normal $t
}

proc viappend { t }  {
    
    backup $t
    $t mark set insert {insert +1c}
    do_normal $t
}

proc viAppend { t }  {
    
    backup $t
    $t mark set insert {insert lineend}
    do_normal $t
}

proc viopen { t }  {
    global viInfo

    backup $t
    $t mark set insert "insert lineend"
    $t insert insert "\n"
    do_normal $t 
    set viInfo($t,last_txt) "\n"
    # fake the last_cmd function to do what we want...
    set viInfo($t,last_cmd) "viAppend $t"
}

proc viOpen { t }  {
   global viInfo

   backup $t
   $t mark set insert "insert linestart"
   $t insert insert "\n"
   $t mark set insert "insert -1c"
   do_normal $t
}


#########################
### procedures for deleting text
#########################

proc del_right { t }  {
    global viInfo

   if {[check_readonly $t]} {
      return
   }
    set repeat [get_repeat $t]

    set viInfo($t,line_yanked) 0
    set viInfo($t,yank_buffer) ""
    for {set i 0} {$i < $repeat} {incr i} {
	set line [lindex [split [$t index insert] .] 0]
	set char [lindex [split [$t index insert] .] 1]
	set insert [$t index insert]
	set lineend [$t index "insert lineend"]
        if {($insert != $lineend) || ($char != 0)} {
           backup $t
           append viInfo($t,yank_buffer) [$t get insert]
	   $t delete insert "insert +1c "
        } else {
           bell
        }
    }
}

proc del_left { t }  {

   if {[check_readonly $t]} {
      return
   }
    backup $t
    set repeat [get_repeat $t]

    for {set i 0} {$i < $repeat} {incr i}  {
	set lineinfo [split [$t index insert] {.}]
	set line [lindex $lineinfo 0]
	set char [lindex $lineinfo 1]
	if {$char == 0}  {
           bell
	} else {
           $t delete {insert -1c} insert
	}
    }
}

proc del_lineend { t }  {
    global viInfo

   backup $t
   set viInfo($t,line_yanked) 0
   set viInfo($t,yank_buffer) [$t get insert "insert lineend"]

   if {[check_readonly_line $t]} {
      set range [$t tag nextrange readonly {insert linestart} {insert lineend}]
      set range_pos  [lindex [split [lindex $range 0] .] 1]
      set insert_pos [lindex [split [$t index insert] .] 1] 
      if {$insert_pos < $range_pos} {
         $t delete insert [lindex $range 0]
      }
      $t mark set insert [lindex [$t tag nextrange readonly \
                                        {insert linestart} {insert lineend}] 1]
      $t delete insert "insert lineend"
   } else {
      $t delete insert "insert lineend"
   }
   set viInfo($t,num_repeat) 0

   do_vi $t
}

proc del_whitespace {t char} {
   global viInfo

   while {[regexp \[\ \t\] $char] && ![check_readonly $t]}  {
      append viInfo($t,yank_buffer) [$t get insert]
      $t delete insert
      set char [$t get insert]
   }
}

proc del_word_right {t delwhite} {
    global viInfo

   if {[check_readonly $t]} {
      return
   }
   backup $t
   set repeat [get_repeat $t]
   set viInfo($t,yank_buffer) {}
   set viInfo($t,line_yanked) 0
    
   set char [$t get insert]
   for {set i 0} {$i < $repeat} {incr i}  {
      # current char is whitespace
      if {[regexp \[\ \t\] $char]} {
         del_whitespace $t $char
      } elseif {[regexp \[a-zA-Z0-9_\] $char]} {
         # current char is alphanumeric
         while {[regexp \[a-zA-Z0-9_\] $char] && ! [check_readonly $t]} {
            append viInfo($t,yank_buffer) [$t get insert]
            $t delete insert
            set char [$t get insert]
         }
         if {$delwhite} { del_whitespace $t $char }
      } elseif {[regexp \[^a-zA-Z0-9_\ \t\] $char]} {
         # current char is non-alphanumeric
         $t delete insert
         set char [$t get insert]
         if {$delwhite} { del_whitespace $t $char }
      }
   }
}

proc del_word_left { t }  {
    global viInfo

   if {[check_readonly $t]} {
      return
   }
    backup $t
    set repeat [get_repeat $t]
    set char [$t get {insert -1c}]

    for {set i 0} {$i < $repeat} {incr i}  {
	if {($char == " ") || ($char == "\t")}  {
	    while {($char == " ") || ($char == "\t")}  {
		$t delete {insert -1c}
		set char [$t get {insert -1c}]
	    }
	    $t delete {insert wordstart} insert
	} else {
	    $t delete {insert wordstart} insert
	}
    }
}

proc del_line { t }  {
    global viInfo

    backup $t
    if {[check_pos $t]} {
       set line [lindex [split [$t index insert] .]  0]
       set char [lindex [split [$t index insert] .]  1]
       set end  [lindex [split [$t index {end -1l}] .] 0]

       set repeat [get_repeat $t]
       $t mark set start $line.0
 
       for {set i 0} {$i < [expr $repeat - 1]} {incr i}  {
           $t mark set insert {insert +1l}
       }
 
       $t mark set stop {insert lineend}
       set viInfo($t,yank_buffer) [$t get start stop]
       set viInfo($t,line_yanked) 1

       if {! [check_readonly_range $t "[$t index start] [$t index "stop +1c"]"]} {
          $t delete start "stop +1c"
          $t mark set insert "insert linestart"
       }
       set viInfo($t,num_repeat) 0
       set viInfo($t,status_plus) 0
   } else {
       bell
       set viInfo($t,num_repeat) 0
   }
}

# delete 1 char to the left ala 'dh'
proc delete_h { t } {
   del_left $t
}

# delete 1 line ala 'dj'
proc delete_j { t } {
   global viInfo

   if {[$t index "insert linestart"] != [$t index "end -1c linestart"]} {
      set viInfo($t,num_repeat) [expr [get_repeat $t] + 1]
      del_line $t
   } else {
      bell
   }
}

# delete 1 line ala 'dk'
proc delete_k { t } {
   global viInfo

   set repeat [get_repeat $t]
   if {[$t index "insert linestart"] != 1.0} {
      $t mark set insert "insert linestart -${repeat}l"
      set viInfo($t,num_repeat) [expr $repeat + 1]
      del_line $t
   } else {
      bell
   }

}

# delete 1 char to the right ala 'dl'
proc delete_l { t } {
   del_right $t
}

proc change_word { t }  {
   global viInfo

   if {[check_readonly $t]} {
      do_normal $t
      return
   }
   backup $t
   set repeat [get_repeat $t]

   for {set i 0} {$i < $repeat} {incr i} {
      del_word_right $t 0
   }
   set viInfo($t,last_cmd) "change_word $t"
   do_normal $t
}

proc change_lineend { t }  {
   global viInfo

   if {[check_readonly $t]} {
      do_normal $t
      return
   }
   del_lineend $t
   set viInfo($t,last_cmd) "Replace_text $t"
   $t mark set insert "insert lineend"
   do_normal $t
}

proc replace_char { t }  {  
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   set repeat [get_repeat $t]
   set char $viInfo($t,yank_buffer)
   set viInfo($t,got_bs) 0
   set viInfo($t,status_plus) 0

   for {set i 0} {$i < $repeat} {incr i}  {
      set pos [lindex [split [$t index insert] .] 1]
      set end [lindex [split [$t index "insert lineend"] .] 1]
      if {($pos != $end) && ($char != "\b")} {
         append viInfo($t,last_char) [$t get insert]
         $t delete insert "insert +1c"
      }
      switch -- $char {
         \b {
            chop viInfo($t,last_txt)
            $t mark set insert "insert -1c"
            set viInfo($t,got_bs) 1
         }
         \r {
            $t insert insert "\n"
         } 
         default {
            $t insert insert $char
         }
      }
   }
   $t mark set insert "insert -1c"
}

# replace the text at the insertion point
proc replace_text { t } {
   global viInfo

   if {[check_readonly $t]} {
      do_vi $t
      return
   }
   backup $t
   set backup_string $viInfo($t,backup_string)
   set len [string length $viInfo($t,last_txt)]
   set string $viInfo($t,last_txt)

   for {set i 0} {$i < $len} {incr i} {
      set viInfo($t,yank_buffer) [string index $string $i]
      replace_char $t
      $t mark set insert "insert +1c"
   }
   set viInfo($t,backup_string) $backup_string
   chk_txt $t
   do_vi $t
}

# replace the text at the insertion point and delete to end of line
proc Replace_text { t } {
   global viInfo

   if {[check_readonly $t]} {
      do_vi $t
   }
   backup $t
   set backup_string $viInfo($t,backup_string)
   set len [string length $viInfo($t,last_txt)]
   set string $viInfo($t,last_txt)

   for {set i 0} {$i < $len} {incr i} {
      set viInfo($t,yank_buffer) [string index $string $i]
      replace_char $t
      $t mark set insert "insert +1c"
   }
   set viInfo($t,backup_string) $backup_string
   del_lineend $t
   set viInfo($t,last_cmd) "Replace_text $t"
   do_vi $t
}

# substitute the current char
proc subst_text { t }  {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   backup $t
   set repeat [get_repeat $t]
   for {set i 0} {$i < $repeat} {incr i}  {
      del_right $t
   }
   do_normal $t
   set viInfo($t,last_cmd) "replace_text $t"
}

# substitute the current line
proc Subst_text { t }  {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   backup $t
   $t mark set insert "insert linestart"
   del_lineend $t 
   set viInfo($t,last_cmd) "Subst_text $t"
   do_normal $t
}

proc join_lines { t }  {
    
    backup $t
    set repeat [get_repeat $t]

    for {set i 0} {$i < $repeat} {incr i}  {
	$t mark set insert {insert lineend}
	set insert [$t index insert]
	set end [$t index end]
	if {$insert != $end}  {
	    $t delete insert
	    $t insert insert { }
	    
	    set char [$t get insert]
	    while {($char == " ") || ($char == "\t")}  {
		$t delete insert
		set char [$t get insert]
	    }
	}
    }
}

proc change_case { t } {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   backup $t
   set char [$t get insert]
   if {[string toupper $char] == $char} {
      set viInfo($t,yank_buffer) [string tolower $char]
   } else {
      set viInfo($t,yank_buffer) [string toupper $char]
   }
   replace_char $t
   $t mark set insert "insert +1c"
   chk_end $t
}

#change the current line ala 'cc'	
proc change_c { t } {
   backup $t
   Subst_text $t
}

#change the current char ala 'cl'	
proc change_l { t } {
   backup $t
   subst_text $t
}

#change the char to the left ala 'ch'	
proc change_h { t } {
   backup $t
   char_move $t -1
   subst_text $t
}

#change the lines above ala 'ck'
proc change_k { t } {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   #save the backup information because 'del_line' and 'Subst_text' are
   # going to overwrite it
   set backup_insert [$t index insert]
   set backup_string [$t get 1.0 {end -1c}]
   set last_cmd      "change_j $t"

   line_move $t -1
   del_line $t
   del_lineend $t

   # now restore the original backup information
   set viInfo($t,backup_insert) $backup_insert
   set viInfo($t,backup_string) $backup_string
   set viInfo($t,last_cmd)      $last_cmd
}

#change the lines below ala 'ck'
proc change_j { t } {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   # save the backup information because 'del_line' and 'Subst_text' are 
   # going to overwrite it
   set backup_insert [$t index insert]
   set backup_string [$t get 1.0 {end -1c}]
   set last_cmd      "change_j $t"

   del_line $t
   Subst_text $t

   # now restore the original backup information
   set viInfo($t,backup_insert) $backup_insert
   set viInfo($t,backup_string) $backup_string
   set viInfo($t,last_cmd)      $last_cmd
}

#########################
### procedures to yank and replace text
#########################

# yank the char to the left ala 'yh'
proc yank_h { t }  {
   global viInfo

   set repeat [get_repeat $t]
   if {[$t index insert] != [$t index "insert linestart"]} {
      set viInfo($t,yank_buffer) [$t get "insert -${repeat}c" insert]
      set viInfo($t,line_yanked) 0
   } else {
      bell
   }
}

# yank the lines below ala 'yj'
proc yank_j { t }  {
   global viInfo

   set repeat [get_repeat $t]
   if {[$t index "insert linestart"] != [$t index "end -1c linestart"]} {
      set viInfo($t,yank_buffer) \
                     [$t get "insert linestart" "insert +${repeat}l lineend"]
      set viInfo($t,line_yanked) 1
   } else {
      bell
   }
}

# yank the lines above ala 'yk'
proc yank_k { t }  {
   global viInfo

   set repeat [get_repeat $t]
   if {[$t index "insert linestart"] != 1.0} {
      set viInfo($t,yank_buffer) \
                     [$t get "insert linestart -${repeat}l" "insert lineend"]
      set viInfo($t,line_yanked) 1
      $t mark set insert "insert -${repeat}l"
   } else {
      bell
   }
}

# yank the char to the right ala 'yl'
proc yank_l { t }  {
   global viInfo
   set repeat [get_repeat $t]
   set viInfo($t,yank_buffer) [$t get insert "insert +${repeat}c"]
   set viInfo($t,line_yanked) 0
}

proc yank_word { t }  {
   global viInfo

   set repeat [get_repeat $t]

   $t mark set save insert
   for {set i 0} {$i < $repeat} {incr i}  {
      word_right $t
   }
   set viInfo($t,yank_buffer) [$t get save insert]
   set viInfo($t,line_yanked) 0
   $t mark set insert save

   do_vi $t
}

proc yank_lineend { t }  {
    global viInfo

    set viInfo($t,yank_buffer) [$t get insert {insert lineend}]
    set viInfo($t,line_yanked) 0

    do_vi $t
}

proc yank_line { t }  {
    global viInfo

    if {[check_pos $t]} {
       $t mark set save insert

       set line [lindex [split [$t index insert] .]  0]
       set char [lindex [split [$t index insert] .]  1]

       set repeat [get_repeat $t]
       $t mark set start $line.0
 
       for {set i 0} {$i < [expr $repeat - 1]} {incr i}  {
           $t mark set insert {insert +1l}
       }
 
       $t mark set stop {insert lineend}
       set viInfo($t,yank_buffer) [$t get start stop]
       set viInfo($t,line_yanked) 1
   
       $t mark set insert save
    } else {
       bell
       set viInfo($t,num_repeat) 0
    }
    do_vi $t
}

proc put_after { t }  {

    global viInfo
    backup $t

   if {[check_readonly $t]} {
      return
   }
    $t mark set save insert
    if {[info exists viInfo($t,yank_buffer)]}  {
	if {$viInfo($t,line_yanked)}  {
	    $t mark set insert "insert lineend"
	    $t insert insert "\n$viInfo($t,yank_buffer)"
            $t mark set insert "save + 1l"
	} else {
           $t insert "insert +1c" $viInfo($t,yank_buffer)
           $t mark set insert "insert +[string length $viInfo($t,yank_buffer)]c"
        }
        $t yview -pickplace insert
    }
}

proc put_before { t }  {
   global viInfo

   if {[check_readonly $t]} {
      return
   }
   backup $t

    set line [lindex [split [$t index insert] .]  0]

    if {[info exists viInfo($t,yank_buffer)]}  {
	if {$viInfo($t,line_yanked)}  {
           if {$line == 1} {
              $t mark set insert 1.0
              $t insert insert "$viInfo($t,yank_buffer)\n"
              $t mark set insert 1.0
           } else {
              $t mark set save insert
              $t mark set insert {insert -1l lineend}
              $t insert insert "\n$viInfo($t,yank_buffer)"
              $t mark set insert "save -1l"
           }
	} else {
	    $t insert insert $viInfo($t,yank_buffer)
	}
	$t yview -pickplace insert
    }
}



#########################
### procs to add up the number of repeats
#########################

proc check_zero { t }  {

    global viInfo

    if {$viInfo($t,num_repeat)}  {
	set_repeat $t 0
    } else {
	$t mark set insert {insert linestart}
    }

}

proc set_repeat { t n }  {

    global viInfo

    set  viInfo($t,num_repeat) [expr $viInfo($t,num_repeat) * 10]
    incr viInfo($t,num_repeat) $n
}



#########################
### procedures related to undo
#########################

proc backup { t }  {
   global viInfo
   
   set viInfo($t,modified)      1
   set viInfo($t,backup_insert) [$t index insert]
   set viInfo($t,backup_string) [$t get 1.0 {end -1c}]
   set viInfo($t,last_cmd)      [info level [expr [info level] - 1]]
   set viInfo($t,last_rpt)      $viInfo($t,num_repeat)

   set tagnames [$t tag names]
   foreach tag $tagnames {
      set tag_range [$t tag ranges $tag]
      set viInfo($t,tag,$tag) $tag_range
   }
}

proc undo { t }  {
   global viInfo

   # if we haven't saved the backup_insert position, there isn't anything
   # to undo
   if {$viInfo($t,backup_insert) == ""} {
      do_vi $t
      return
   }
   # don't want to call 'backup' because we don't want to
   # overwrite the last cmd information, so just save it ourself
   set oldbackup $viInfo($t,backup_string)
   set viInfo($t,modified)      1
   set viInfo($t,status_plus)   0
   set viInfo($t,backup_string) [$t get 1.0 "end -1c"]
   set insert [$t index insert]
   $t delete 1.0 end
   $t insert 1.0 $oldbackup
   $t mark set insert $viInfo($t,backup_insert)
   $t yview -pickplace insert

   set taglist [array names viInfo "$t,tag,*"]
   foreach tag $taglist {
      regsub "$t,tag," $tag "" tagname
      set taglist $viInfo($tag)
      if {$taglist != ""} {
         for {set idx 0} {$idx < [llength $taglist]} {incr idx 2} {
            $t tag add $tagname [lindex $taglist $idx] \
                                [lindex $taglist [expr $idx + 1]]
         }
      }
   }
   do_vi $t
}


#########################
### colon mode stuff
#########################

proc append_colon { t c }  {
   global viInfo

   append viInfo($t,colstr) $c
   append viInfo($t,status) $c
}

proc del_colon { t }  {
    global viInfo

    if {$viInfo($t,colstr) != {}}  {
	set viInfo($t,colstr) [string range $viInfo($t,colstr) 0 \
				[expr [string length $viInfo($t,colstr)] - 2]]
	set viInfo($t,status) [string range $viInfo($t,status) 0 \
				[expr [string length $viInfo($t,status)] - 2]]
    } else {
       quit_colon $t
    }
}

proc quit_colon { t }  {
   global viInfo

   set viInfo($t,colstr)      ""
   set viInfo($t,status_plus) 0
   do_vi $t 
}

proc eval_colon { t }  {
   global viInfo

   set last_line [expr [lindex [split [$t index end] .] 0] - 1]
   set col_cmd   [lindex [split [string trim $viInfo($t,colstr)]] 0]
   set col_arg   [lrange [split [string trim $viInfo($t,colstr)]] 1 end]
   set viInfo($t,status_plus) 0
   set viInfo($t,num_repeat)  0
   set viInfo($t,status)      ""
   $t mark set save insert

   if {$col_cmd == ""} { do_vi $t ; return}

   # check to see if we have a line#,line# format command
   if {[regexp , $col_cmd]} {
      regsub {\$} $col_cmd [expr [lindex [split [$t index end] .] 0] -1] col_cmd
      regsub {\.} $col_cmd [lindex [split [$t index insert] .] 0] col_cmd
      set start [lindex [split $col_cmd ,] 0]
      set end   [lindex [split $col_cmd ,] 1]

      # make sure our ranges are valid
      if {$end <= $last_line} {
         if {$start <= $end} {
            $t mark set insert $start.0
            set viInfo($t,num_repeat) [expr $end - $start + 1]
         } else {
            set viInfo($t,status_plus) 1
            set viInfo($t,status) " First address exceeds second" 
            do_vi $t
            return
         } 
      } else {
         set viInfo($t,status_plus) 1
         set viInfo($t,status) " Not that many lines in buffer"
         do_vi $t
         return
      }
      set tmp $col_cmd
      set col_cmd $col_arg
      set col_arg $tmp
   }

   switch -- $col_cmd  {
      w  {vi_save $t}
      q  {
         if {[vi_quit $t]} {
            return
         }
      }
	  wq {
		 set retval [vi_save $t]  
		  if {$retval != "" && $retval != "0"}  {
			  return
		  }
		 if {[vi_quit $t]} {
			return
		 }
      }
      q! {
         set viInfo($t,modified) 0
         if {[vi_quit $t]} {
            return
         }
      }
      r {
         backup $t
         set line [lindex [split [$t index insert] .] 0]
         if {[catch {set f [open $col_arg]; close $f} err] == 0} {
            set f [open $col_arg]
            set input [read $f]
            chop input
            $t insert "insert lineend" "\n$input"
            close $f
            $t mark set insert [expr $line + 1].0
         } else {
            set viInfo($t,status_plus) 1
            set viInfo($t,status) "  \"$col_arg\" [lindex [split $err :] 1]"
         }
      }
      \$ {
         set last_line [expr [lindex [split [$t index end] .] 0] - 1]
         set curr_line [lindex [split [$t index insert] .] 0]
         if {$curr_line != $last_line} {
            $t mark set insert "$last_line.0"
            $t yview -pickplace insert
         }
      }
      d {
         del_line $t
         # dis-allow 'repeat last cmd' functionality
         set viInfo($t,last_cmd) ""
         set viInfo($t,last_txt) ""
      }
      y {
         yank_line $t
         # dis-allow 'repeat last cmd' functionality
         set viInfo($t,last_cmd) ""
         set viInfo($t,last_txt) ""
      }
      s {
         # dis-allow 'repeat last cmd' functionality
         set viInfo($t,last_cmd) ""
         set viInfo($t,last_txt) ""
      }
      default {
         switch -regexp -- $viInfo($t,colstr)  {
            (^[0-9]+$) {
               set last_line [lindex [split [$t index "end -1l"] .] 0]
               if {$col_cmd <= $last_line}  {
                     $t mark set insert $col_cmd.0
                  $t yview -pickplace insert
               } else {
                  set viInfo($t,status_plus) 1
                  set viInfo($t,status) "  Not that many lines in buffer"
               }
            }
            default {
               set temp 0
               set viInfo($t,last_cmd) ""
               set viInfo($t,status) "     $viInfo($t,colstr): "
               set viInfo($t,status) "$viInfo($t,status) Not an editor command"
               set viInfo($t,status_plus) 1
            }
         } 
      }
   }
   do_vi $t
}

#########################
### search mode stuff (very similar to colon below)
#########################

proc append_search { t c }  {

    global viInfo

    if {$viInfo($t,search_state)}  {
	set viInfo($t,search_state) 0
	set viInfo($t,search_string) $c
	append viInfo($t,status) $c
    } else {
	append viInfo($t,search_string) $c
	append viInfo($t,status) $c
    }
}

proc del_search { t }  {

    global viInfo

    set mystring $viInfo($t,search_string)
    if {$mystring != {}}  {
	set viInfo($t,search_string) [string range $mystring 0 \
		[expr [string length $mystring] - 2]]
	set viInfo($t,status) [string range $viInfo($t,status) 0 \
		[expr [string length $viInfo($t,status)] - 2]]
    }
}

proc repeat_search { t type }  {
    global viInfo
    
    if {$viInfo($t,search_string) == ""}  { 
       set viInfo($t,status) "     No previous regular expression"
       set viInfo($t,status_plus) 1
       return 
    }
    set viInfo($t,status_plus) 0

    ### if 1 then do actions for n, if 0 do actions for N
    if {$type}  {
	if {$viInfo($t,search_type) == "f"}  {
            set viInfo($t,status) "  Search wrapped around BOTTOM of buffer"
	    set found [$t search -regexp -nocase -forwards -- \
		    $viInfo($t,search_string) {insert +1c}]
	} else {
            set viInfo($t,status) "  Search wrapped around TOP of buffer"
	    set found [$t search -regexp -nocase -backwards -- \
		    $viInfo($t,search_string) {insert -1c}]
	} 
    } else {
	if {$viInfo($t,other_search_type) == "f"}  {
            set viInfo($t,status) "  Search wrapped around BOTTOM of buffer"
	    set found [$t search -regexp -nocase -forwards -- \
		    $viInfo($t,search_string) {insert +1c}]
	} else {
            set viInfo($t,status) "  Search wrapped around TOP of buffer"
	    set found [$t search -regexp -nocase -backwards -- \
		    $viInfo($t,search_string) {insert -1c}]
	}
   }
   if {$found == ""} {
      set viInfo($t,status_plus) 1
      set viInfo($t,status) "  Pattern not found"
   } 
   if {$found == [$t index insert]} {
      set viInfo($t,status_plus) 1
   }
   if {$found != ""} {
      $t mark set insert $found
      $t yview -pickplace insert
      catch {selection clear -displayof $t}
      set length [string length $viInfo($t,search_string)]
      $t tag add sel insert "insert +${length}c"
   }
}

# show the current status ala '^g'
proc do_status { t } {
   global viInfo

   set file_size [lindex [split [$t index "end -1l"] .] 0]
   set curr_line [lindex [split [$t index insert   ] .] 0]
   set percent   [lindex [split [expr ($curr_line.0 / $file_size.0) * 100] .] 0]
   set $viInfo($t,status_plus) 1

   if {$viInfo($t,modified)} {
      set viInfo($t,status) \
                   "\[Modified\] line $curr_line of $file_size --$percent%--"
   } else {
      set viInfo($t,status) "line $curr_line of $file_size --$percent%--"
   }
}

# repeat the last command ala '.'
proc do_lastcmd { t } {
   global viInfo

   set last_cmd [lindex $viInfo($t,last_cmd) 0]
   set last_arg [lindex $viInfo($t,last_cmd) 1]
   set last_txt $viInfo($t,last_txt)
   set viInfo($t,last_char) ""

   # make sure we had a valid 'last command'
   if {$last_cmd == ""} { 
      set viInfo($t,status)      ""
      set viInfo($t,status_plus) 0
      bell
      return
   }
   switch -- $last_cmd {
      insert {
         if {$last_txt != ""} {
            set viInfo($t,yank_buffer) $last_txt
            set viInfo($t,line_yanked) 0
            $t mark set insert "insert -1c"
            put_after $t
            set viInfo($t,last_cmd) "insert $t"
         }
      }
      Insert {
         if {$last_txt != ""} {
            set viInfo($t,yank_buffer) $last_txt
            set viInfo($t,line_yanked) 0
            $t mark set insert {insert linestart}
            put_before $t
            set viInfo($t,last_cmd) "Insert $t"
            $t mark set insert "insert -1c"
         }
      }
      viappend {
         if {$last_txt != ""} {
            set viInfo($t,yank_buffer) $last_txt
            set viInfo($t,line_yanked) 0
            put_after $t
            set viInfo($t,lastcmd) "viappend $t"
         }
      }
      viAppend {
         if {$last_txt != ""} {
            set viInfo($t,yank_buffer) $last_txt
            set viInfo($t,line_yanked) 0
            $t mark set insert "insert lineend -1c"
            put_after $t
            set viInfo($t,last_cmd) "viAppend $t"
            $t mark set insert "insert lineend -1c"
         }
      }
      viOpen {
         # preserve the backup string
         set backup_string [$t get 1.0 "end -1c"]
         set viInfo($t,yank_buffer) $last_txt
         set viInfo($t,line_yanked) 0
         $t mark set insert "insert -1l lineend"
         $t insert insert "\n"
         $t mark set insert "insert -1c"
         put_after $t
         set viInfo($t,last_cmd) "viOpen $t"
         $t mark set insert "insert lineend -1c"
         set viInfo($t,backup_string) $backup_string
         set viInfo($t,backup_insert) [$t index insert]
      }
      Subst_text {
         # preserve the backup string
         set backup_string [$t get 1.0 "end -1c"]
         $t mark set insert "insert linestart"
         del_lineend $t 
         replace_text $t
         set viInfo($t,last_cmd) "Subst_text $t"
         set viInfo($t,backup_string) $backup_string
      }
      change_word {
         # preserve the backup string
         set backup_string [$t get 1.0 "end -1c"]
         set repeat [get_repeat $t]
         for {set i 0} {$i < $repeat} {incr i} {
            del_word_right $t 0
         }
         $t insert insert $last_txt
         set viInfo($t,last_cmd) "change_word $t"
         set viInfo($t,backup_string) $backup_string
      }
      default {
         set viInfo($t,num_repeat) $viInfo($t,last_rpt)
         eval {$last_cmd $last_arg}
      }
   }
}

proc eval_search { t }  {
    global viInfo

    if {$viInfo($t,search_type) == "f"}  {
	set found [$t search -regexp -nocase -forwards -- \
		$viInfo($t,search_string) {insert +1c}]
    } else {
	set found [$t search -regexp -nocase -backwards -- \
		$viInfo($t,search_string) {insert -1c}]
    }
    if {$found != ""} {
       set viInfo($t,search_state) 1
       $t mark set insert $found
       $t yview -pickplace insert
       catch {selection clear -displayof $t}
       set length [string length $viInfo($t,search_string)]
       $t tag add sel insert "insert +${length}c"
    } else {
       set viInfo($t,status_plus) 1
       set viInfo($t,status) "  Pattern not found"
       set viInfo($t,search_string) ""
    }
    do_vi $t
}

proc vi_save { t }  {
   global viInfo

	# puts "$t"
   if {$viInfo($t,fileops)}  {
      if {$viInfo($t,savecommand) != ""} {
         set savecmd $viInfo($t,savecommand)
         set newscript [string trim [$t get 1.0 end]]
         #append savecmd " \{$newscript\}"
	#puts $savecmd
	#regsub {\\} $newscript {\\\\} newscript
#	puts $savecmd
         set retval [eval $viInfo($t,savecommand) \$newscript]
         set viInfo($t,modified) 0
         return $retval
      } else {
         set viInfo($t,status_plus) 1
         set viInfo($t,status) "  No SaveCommand Defined"
      }
   } else  {
      return 0
   }
}

proc vi_quit { t }  {
	global viInfo
	
	# puts "$t"
	if {$viInfo($t,fileops)}  {
		if {$viInfo($t,modified)} {
			set viInfo($t,status) "     changed since last save"
			set viInfo($t,status_plus) 1
			return 0
		} else {
			destroy [winfo parent [winfo parent $t]]
			return 1
		}
	}
	return 0
}

# set a mark at the current location ala 'm char'
proc set_mark  { t char } {
   $t mark set mark_$char insert
   do_vi $t
}

# goto said mark ala '` char'
proc goto_mark { t char } {
   if {! [catch {$t mark set insert mark_$char}]} {
      $t yview -pickplace insert
   } else {
      bell
   }
   do_vi $t
}

# goto line start of said mark ala '' char'
proc goto_Mark { t char } {
   if {! [catch {$t mark set insert "mark_$char linestart"}]} {
      $t yview -pickplace insert
   } else {
      bell
   }
   do_vi $t
}

#########################
### auxillary routines
#########################

# pretend we are PERL ;-)
proc chop { string } {
   upvar $string str
 
   set char [string index $str [expr [string length $str] - 1]]
   set str  [string range $str 0 [expr [string length $str] - 2]]
   return $char
}

# check the current position and backup a space if we need too 
proc check_pos { t } {
   global viInfo

   set line [lindex [split [$t index insert] .]  0]
   set end  [lindex [split [$t index {end -1l}] .] 0]
   set repeat [expr $viInfo($t,num_repeat) - 1]

   if {[expr $line + $repeat] > $end} {
     return 0
   } else {
     return 1
   }
}

# procedure to check the insert position and back it up a space if
# necessary (ie end of line)
proc chk_end { t } {
   set curr_pos [lindex [split [$t index insert] .] 1]
   set last_pos [lindex [split [$t index "insert lineend"] . ] 1]
   if {($curr_pos == $last_pos) && ($curr_pos != 0)} {
      $t mark set insert "insert -1c"
   }
}

# procedure to check if we inserted text and back up a space if we
# did
proc chk_txt { t } {
   global viInfo
   # if we didn't insert any text, leave the cursor where it is
   if {$viInfo($t,last_txt) != ""} {
      # else, back it up one position
      char_move $t -1
   }
} 

# Procedure Name:   disp_error
#        Purpose:   display an error message
#         Inputs:   a string consisting of the message
#      Variables:   None
proc disp_error {error_message parent} {
  tk_messageBox -type ok -title "Error" -message "$error_message" \
	-icon error -parent $parent
}

proc check_readonly { t } {
   # check to make sure we aren't in a readonly region
   # specified by a tag named 'readonly'
   if {[lsearch [$t tag names insert] readonly] >= 0} {
     return 1
   }
   return 0
}
proc check_readonly_line { t } {
   # check to make sure the line we are on doesn't contain a readonly
   # tag
   set currline [lindex [split [$t index insert] .] 0]
   set range [$t tag ranges readonly]
   for {set idx 0} {$idx < [llength $range]} {incr idx 2} {
      if {[lindex [split [lindex $range $idx] .] 0] == $currline} {
         return 1
      }
   }
   return 0
}
proc check_readonly_range {t range} {
   set rdonly [$t tag ranges readonly]
   set range_start [lindex $range 0]
   set range_end   [lindex $range 1]

   # check to see if the range actually starts/ends in a readonly region
   $t mark set save insert
   $t mark set insert $range_start
   if {[check_readonly $t]} {
      $t mark set insert save
      return 1
   }
   $t mark set insert "$range_end -1c"
   if {[check_readonly $t]} {
      $t mark set insert save
      return 1
   }
   $t mark set insert save
   for {set idx 0} {$idx < [llength $rdonly]} {incr idx 2} {
      set rdonly_start [lindex $rdonly $idx]
      set rdonly_end   [lindex $rdonly [expr $idx + 1]]

      if {($range_start < $rdonly_start) && ($range_end > $rdonly_start)} {
         return 1
      }
      if {($range_start < $rdonly_end) && ($range_end > $rdonly_end)} {
         return 1
      }
      if {($range_start > $rdonly_start) && ($range_end < $rdonly_end)} {
         return 1
      }
   }
   return 0
}

proc viTextButton1 {w x y} {
	global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

    set tkPriv(selectMode) char
    set tkPriv(mouseMoved) 0
    set tkPriv(pressX) $x
    $w mark set anchor @$x,$y
    if {[$w cget -state] == "normal"} {focus $w}
}

# todo (ie bugs)
#
#  Functions not working:
#       search-and-replace
#
#  Keys not working
#       B - goto beginning of previous word, ignore punct
#       W - goto beginning of next     word, ignore punct
#       U - undo changes to current line

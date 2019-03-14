
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.


# Get my Network name

global myHostname myHostaddr nameserver tcl_platform aci_comm_type

global env

# Set the variables aci_comm_type = ACI | IPC and
# nameserver = aci_dir | qsrv | user-specified
# If aci_comm_type == IPC, then nameserver has to be qsrv.

if { ([info exists env(ACI_COMM_TYPE)] && $env(ACI_COMM_TYPE) == "ACI") || \
		$tcl_platform(platform) == "windows" || 
		$tcl_platform(platform) == "linux"} {
	set aci_comm_type ACI
	set myHostname [an_hostname]
	if {$myHostname == ""} { 
		puts "Error getting hostname"
		exit
	}

	set myHostaddr [an_hostaddr]
	if {$myHostaddr == "" || $myHostaddr == "0"} { 
		puts "Error with nslookup: no interface addresses found"
		exit
	}
	
	set nameserver [dv_get nameserver]
	if { "$nameserver" == "" } {
		set nameserver "unknown"
	}
} else {
	set aci_comm_type IPC
	set nameserver qsrv
}




proc mangle_aci_name {aciname} {

	global env
   
	set myName [dv_get >name]
	if { ([info exists env(ACI_NAME_USES_ASHL)] && 
			$env(ACI_NAME_USES_ASHL) == "1") } {
    	set iAmMangling 1

	} else {
		set iAmMangling 0
	}
	set destIsMangling [string equal -length 5 "ashl." $aciname]

	# If we're using name manging and the destination server isn't, add a 
	# routing file entry.
    if { $iAmMangling } {
		if {! $destIsMangling } {
        	catch { an_cmd deleterf anname=$aciname }
        	catch { an_cmd addrf anname=$aciname aciname=$aciname }

			return $aciname
		} else {
			# strip off the 'ashl.' so the code can add it bad.  Silly.
			return [string range $aciname 5 end]
		}

	} else {

		if { $destIsMangling && ! $iAmMangling } {

			set anname [string range $aciname 5 end]
        	catch { an_cmd deleterf anname=$anname }
	        catch { an_cmd addrf anname=$anname aciname=ashl.$anname }
			return $anname

		} else {

			return $aciname
		}

	}
}

proc unmangle_aci_name {anname} {

	# If no routing file entry exists, return the name
	# else return the aciname

	if {[catch {set aciname [an_cmd getrf anname=$anname]}] } {
		return $anname
	} else {
		return $aciname
	}

}



#
# Author : Cris Magalang
# Script: gproxyrc.tcl
# Description:
#   Reads individual user .netrc , wgetrc and .curlrc credential files.
#    Use for loading into scripts requiring credentials for proxy configuration.
#

package provide gproxyrc 1.0

namespace eval gproxyrc {
	variable cred
	variable loaded
	array set loaded {
		netrc 0 curlrc 0 wgetrc 0
	}

	proc get_curlrc {} {
		variable cred
		if {[file exists ~/.curlrc]} {
			set fn [open "~/.curlrc" r]
			set fd [read $fn]
			close $fn
			foreach line [split $fd "\n"] {
				lassign [split $line =] k v
				dict set cred curlrc $k $v
				if {[string match $k proxy]} {
					dict set cred curlrc machine $v
				}
				if {[string match $k proxy-user]} {
					regexp -nocase -all {([A-Za-z0-9]+):(.*)} $v tmp user pass
					dict set cred curlrc login $user
					dict set cred curlrc password $pass
				}
		    }
		} else {
			set message "User netrc credentials not found."
			dict set cred netrc error_message $message
	    }
	}

	proc get_netrc {} {
		variable cred
		if {[file exists ~/.netrc]} {
			set fn [open "~/.netrc" r]
			set fd [read $fn]
			close $fn
			foreach {k v} $fd {
				dict set cred netrc $k $v
		    }
		} else {
			set message "User netrc credentials not found."
			dict set cred netrc error_message $message
	    }
	}

	proc get_wgetrc {} {
		variable cred
		if {[file exists ~/.wgetrc]} {
			set fn [open "~/.wgetrc" r]
			set fd [read $fn]
			close $fn
			foreach {k equals v} $fd {
				dict set cred  wgetrc $k $v
				if {[string match $k http_proxy]} {
					dict set cred wgetrc proxy $v
					dict set cred wgetrc machine $v
				}
				if {[string match $k proxy_user]} {
					dict set cred wgetrc login $v
				}
				if {[string match $k proxy_password]} {
					dict set cred wgetrc password $v
				}
		    }
		} else {
			set message "User wgetrc credentials not found."
			dict set cred wgetrc error_message $message
	    }
	}

	proc get {src {fld {}}} {
		variable cred
		variable loaded

		if {![info exists loaded($src)]} {
			puts ERROR:UNKNOWN_CREDENTIAL_SOURCE:<$src>
			return
		}

		if {$loaded($src) == 0} {
			switch -- $src {
				netrc {
					get_netrc
			    }
				curlrc {
					get_curlrc
			    }
				wgetrc {
					get_wgetrc
			    }
			    default {
			    	puts ERROR:UNKNOWN_CREDENTIAL_SOURCE:<$src>
			    	return
			    }
		    }
		}
		if {![dict exists [subst $cred] $src $fld]} {
			puts "Option $src->$fld does not exist"
			usage
		} else {
			return [dict get [subst $cred] $src $fld]
	    }

	}

	proc usage {} {
		puts "This script will read one of the following as specified: '.netrc' , '.curlrc' or '.wgetrc'."
		puts "\tgrproxyrc::get <netrc|curlrc|wgetrc> <option_var>"
		puts "\t[info script] cmdline netrc <machine,login,password>"
		puts "\t[info script] cmdline wgetrc <http_proxy,https_proxy,proxy_user,proxy_password,login,password>"
		puts "\t[info script] cmdline curlrc <proxy,proxy-user,machine,login,password>"
		puts "\t[info script] cmdline usage"
	}
}

if {$argc == 3 && [string match [lindex $argv 0] cmdline]} {
	puts [gproxyrc::get [lindex $argv 1] [lindex $argv 2]]
}

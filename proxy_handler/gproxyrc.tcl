# Proxy Handler Tcl Sample
#
# This small library reads common user-style proxy configuration files.  It can
# be sourced by another script or run directly to load the included demo files.

package provide gproxyrc 2.0

namespace eval gproxyrc {
    # config is a nested dictionary keyed by the source file type.
    variable config [dict create]
}

# Read a text file safely and return its lines.  Keeping file handling in one
# helper makes each parser easier to follow.
proc gproxyrc::read_lines {file_path} {
    set channel [open $file_path r]
    try {
        return [split [read $channel] "\n"]
    } finally {
        close $channel
    }
}

# Remove surrounding whitespace and optional double quotes from a value.
proc gproxyrc::clean_value {value} {
    set value [string trim $value]
    if {[string match \"*\" $value] && [string length $value] >= 2} {
        set value [string range $value 1 end-1]
    }
    return $value
}

# Parse a .netrc file into a dictionary.  Each machine name maps to its own
# dictionary, making files with multiple machine entries straightforward.
proc gproxyrc::parse_netrc {file_path} {
    if {![file exists $file_path]} {
        return [dict create error_message "File not found: $file_path"]
    }

    if {[catch {set lines [read_lines $file_path]} err]} {
        return [dict create error_message "Unable to read $file_path: $err"]
    }

    set result [dict create]
    set machine ""
    set content ""

    foreach line $lines {
        # netrc comments begin with # and continue to the end of the line.
        regsub {#.*$} $line "" line
        append content " " $line
    }

    set tokens [regexp -all -inline {[^\s]+} $content]
    foreach {key value} $tokens {
        if {$key eq "machine"} {
            set machine $value
            if {![dict exists $result $machine]} {
                dict set result $machine [dict create]
            }
        } elseif {$machine ne ""} {
            dict set result $machine $key $value
        }
    }

    return $result
}

# Parse simple key=value files such as .curlrc and .wgetrc.  Empty lines and
# comment lines are ignored, and values may optionally be wrapped in quotes.
proc gproxyrc::parse_key_value_file {file_path} {
    if {![file exists $file_path]} {
        return [dict create error_message "File not found: $file_path"]
    }

    if {[catch {set lines [read_lines $file_path]} err]} {
        return [dict create error_message "Unable to read $file_path: $err"]
    }

    set result [dict create]
    foreach line $lines {
        set line [string trim $line]
        if {$line eq "" || [string match "#*" $line]} {
            continue
        }

        if {[regexp {^([^=]+)=(.*)$} $line -> key value]} {
            dict set result [string trim $key] [clean_value $value]
        }
    }

    return $result

    return $result
}

proc gproxyrc::parse_curlrc {file_path} {
    return [parse_key_value_file $file_path]
}

proc gproxyrc::parse_wgetrc {file_path} {
    return [parse_key_value_file $file_path]
}

# Load configuration files into the namespace dictionary.  By default this
# checks the current user's home directory, while options allow demo or custom
# paths to be supplied without touching real configuration files.
proc gproxyrc::load {args} {
    variable config

    set paths [dict create \
        -netrc ~/.netrc \
        -curlrc ~/.curlrc \
        -wgetrc ~/.wgetrc]

    if {[llength $args] % 2 != 0} {
        error "usage: gproxyrc::load ?-netrc path? ?-curlrc path? ?-wgetrc path?"
    }

    foreach {option file_path} $args {
        if {![dict exists $paths $option]} {
            error "unknown option: $option"
        }
        dict set paths $option $file_path
    }

    set config [dict create]
    dict set config netrc [parse_netrc [dict get $paths -netrc]]
    dict set config curlrc [parse_curlrc [dict get $paths -curlrc]]
    dict set config wgetrc [parse_wgetrc [dict get $paths -wgetrc]]
    return $config
}

# Return a setting from one configuration section, or a caller-provided default
# when the section or key is not present.
proc gproxyrc::get {section key {default ""}} {
    variable config

    if {[dict exists $config $section $key]} {
        return [dict get $config $section $key]
    }
    return $default
}

# Look up a property for a specific .netrc machine entry.
proc gproxyrc::get_netrc {machine key {default ""}} {
    variable config

    if {[dict exists $config netrc $machine $key]} {
        return [dict get $config netrc $machine $key]
    }
    return $default
}

# Print loaded settings while redacting values that may contain credentials.
# This is useful for inspecting structure without accidentally exposing secrets.
proc gproxyrc::dump {} {
    variable config

    dict for {section settings} $config {
        puts "$section:"
        dict for {key value} $settings {
            if {$section eq "netrc" && $key ne "error_message"} {
                puts "  $key:"
                dict for {machine_key machine_value} $value {
                    if {$machine_key in {login password account}} {
                        set machine_value "<redacted>"
                    }
                    puts "    $machine_key = $machine_value"
                }
            } else {
                if {$key in {proxy-user proxy_user proxy_password password login}} {
                    set value "<redacted>"
                }
                puts "  $key = $value"
            }
        }
    }
}

# When invoked with tclsh, load demo values next to this script.  When sourced,
# define only the reusable library procedures and leave loading to the caller.
if {[file normalize [info script]] eq [file normalize $argv0]} {
    set sample_dir [file dirname [file normalize [info script]]]

    gproxyrc::load \
        -netrc [file join $sample_dir sample.netrc] \
        -curlrc [file join $sample_dir sample.curlrc] \
        -wgetrc [file join $sample_dir sample.wgetrc]

    puts "Proxy Handler Tcl Sample"
    puts "Loaded sample.netrc, sample.curlrc, sample.wgetrc"
    puts ""
    puts "curl proxy: [gproxyrc::get curlrc proxy {not set}]"
    puts "wget use_proxy: [gproxyrc::get wgetrc use_proxy {not set}]"
    puts "netrc example.com login: [gproxyrc::get_netrc example.com login {not set}]"
}

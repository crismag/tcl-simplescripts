# Proxy Handler Tcl Sample

This sample demonstrates how to read common proxy and credential configuration files from Tcl.

## What it demonstrates

- Namespaces
- File existence checks
- Safe file handling
- Line-by-line parsing
- Dictionaries
- Optional arguments
- Safe defaults
- Script reuse through `source`

## Files

| File | Purpose |
|---|---|
| `gproxyrc.tcl` | Tcl namespace/library for loading proxy config. |
| `sample.netrc` | Demo `.netrc` file. |
| `sample.curlrc` | Demo `.curlrc` file. |
| `sample.wgetrc` | Demo `.wgetrc` file. |

## Run the sample

```bash
cd proxy_handler
tclsh gproxyrc.tcl
```

Example output:

```text
Proxy Handler Tcl Sample
Loaded sample.netrc, sample.curlrc, sample.wgetrc

curl proxy: http://proxy.example.com:8080
wget use_proxy: on
netrc example.com login: demo_user
```

## Use from another Tcl script

Source the library and pass explicit paths when you want to use the included demo configuration:

```tcl
source ./gproxyrc.tcl

gproxyrc::load \
    -netrc ./sample.netrc \
    -curlrc ./sample.curlrc \
    -wgetrc ./sample.wgetrc

puts [gproxyrc::get curlrc proxy "not set"]
puts [gproxyrc::get wgetrc http_proxy "not set"]
puts [gproxyrc::get_netrc example.com login "not set"]
```

Call `gproxyrc::load` without options to read `~/.netrc`, `~/.curlrc`, and `~/.wgetrc`. Missing files are handled gracefully and recorded with an `error_message` setting. The `gproxyrc::dump` helper prints loaded settings while redacting common credential fields.

## Security note

The included sample files use fake credentials only. Do not commit real usernames, passwords, or proxy credentials. Be careful when loading or displaying values from your actual home-directory configuration files.

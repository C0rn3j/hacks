#!/bin/bash
# httpget-devtcp v1.0.1
# Download files over HTTP using the /dev/tcp feature of bash.
#
# (c) 2009 Mantas Mikulėnas <grawity@gmail.com>
# Released under WTFPL v2 <http://sam.zoy.org/wtfpl/>
#
# Usage: httpget <url>

get() {
	local url host port path
	url="$1"
	host="${url#http://}"
	if [[ "$host" == */* ]]
		then path="/${host#*/}"; host="${host%%/*}"
		else path="/"
	fi
	if [[ "$host" == *:* ]]
		then port="${host#*:}"; host="${host%%:*}"
		else port="80"
	fi
	exec 5<>"/dev/tcp/$host/$port"
	#exec 5<>/dev/stdout

	{
		echo -en "GET $path HTTP/1.0\r\n"
		echo -en "Host: $host:$port\r\n"
		echo -en "\r\n"
	} >&5

	read httpver httpstatus httpmsg <&5
	case "$httpstatus" in
	200)
		while true; do
			read line <&5
			[ "$line" = $'\r\n' ] && break;
		done
		cat <&5
		exec 5>&-
		;;
	301|302)
		while true; do
			read hdr val <&5
			if [ "${hdr,,}" = "location:" ]; then
				exec 5>&-
				echo "--> redirected to $val" >&2
				get "$val"
				break
			elif [ "$hdr" = "" -o "$hdr" = $'\r\n' ]; then
				cat <&5
				exec 5>&-
				break
			fi
		done
		;;
	4??|5??)
		exec 5>&-
		return 1
		;;
	*)
		echo "$httpver $httpstatus $httpmsg"
		cat <&5
		exec 5>&-
		return 1
		;;
	esac
}
get "$1"

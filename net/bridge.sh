# Copyright (c) 2007-2008 Roy Marples <roy@marples.name>
# All rights reserved. Released under the 2-clause BSD license.

bridge_depend()
{
	before interface macnet
	program /sbin/brctl
}

_config_vars="$_config_vars bridge bridge_add brctl"

_is_bridge()
{
	# Ignore header line so as to allow for bridges named 'bridge'
	brctl show 2>/dev/null | sed '1,1d' | grep -q "^${IFACE}[[:space:]]"
}

bridge_pre_start()
{
	local brif= iface="${IFACE}" e= x=
	local ports="$(_get_array "bridge_${IFVAR}")"
	local opts="$(_get_array "brctl_${IFVAR}")"
	
	eval brif=\$bridge_add_${IFVAR}
	eval x=\${bridge_${IFVAR}-y\}
	if [ -z "${brif}" -a -z "${opts}" ]; then
		[ -n "${ports}" -o "${x}" != "y" ] || return 0
	fi

	[ -n "${ports}" ] && bridge_post_stop

	(
	if [ -z "${ports}" -a -n "${brif}" ]; then
		ports="${IFACE}"
		IFACE="${brif}"
	else
		ports="${ports}"
		metric=1000
	fi

	if ! _is_bridge; then
		ebegin "Creating bridge ${IFACE}"
		if ! brctl addbr "${IFACE}"; then
			eend 1
			return 1
		fi
	fi

	local IFS="$__IFS"
	for x in ${opts}; do
		unset IFS
		set -- ${x}
		x=$1
		shift
		set -- "${x}" "${IFACE}" "$@"
		brctl "$@"
	done
	unset IFS

	if [ -n "${ports}" ]; then
		einfo "Adding ports to ${IFACE}"
		eindent

		local OIFACE="${IFACE}"
		for x in ${ports}; do
			ebegin "${x}"
			local IFACE="${x}"
			_set_flag promisc
			_up
			if ! brctl addif "${OIFACE}" "${x}"; then
				_set_flag -promisc
				eend 1
				return 1
			fi
			eend 0
		done
		eoutdent
	fi
	) || return 1

	# Bring up the bridge
	_up
}

bridge_post_stop()
{
	local port= ports= delete=false extra=

	if _is_bridge; then
		ebegin "Destroying bridge ${IFACE}"
		_down
		# Ignore header line so as to allow for bridges named 'bridge'
		ports="$(brctl show 2>/dev/null | \
			sed -n -e '1,1d' -e '/^'"${IFACE}"'[[:space:]]/,/^\S/ { /^\('"${IFACE}"'[[:space:]]\|\t\)/s/^.*\t//p }')"
		delete=true
		iface=${IFACE}
		eindent
	else
		# Work out if we're added to a bridge for removal or not
		# Ignore header line so as to allow for bridges named 'bridge'
		eval set -- $(brctl show 2>/dev/null | sed -e '1,1d' -e "s/'/'\\\\''/g" -e "s/$/'/g" -e "s/^/'/g")
		local line=
		for line; do
			set -- ${line}
			if [ "$3" = "${IFACE}" ]; then
				iface=$1
				break
			fi
		done
		[ -z "${iface}" ] && return 0
		extra=" from ${iface}"
	fi

	for port in ${ports}; do
		ebegin "Removing port ${port}${extra}"
		local IFACE="${port}"
		_set_flag -promisc
		brctl delif "${iface}" "${port}"
		eend $?
	done

	if ${delete}; then
		eoutdent
		brctl delbr "${iface}"
		eend $?
	fi
	
	return 0
}

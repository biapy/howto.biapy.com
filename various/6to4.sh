# 6to4.sh - IPv6-in-IPv4 tunnel backend
# Copyright (c) 2010-2011 OpenWrt.org

# Changes by Pierre-Yves Landuré for howto.biapy.com
# add defaultroute_ip option (default: 192.88.99.1
# add prefix6 option (default: '') to force prefix
# add prefix6_template option (default: 2002:????:????)
#         (? are replated by IPv4 hexadecimal notation)
# add suffix6 option (default: '::1/16') to for suffix.

# For Free french SP, use:
# option defaultroute_ip 192.88.99.101 (or 102).
# option prefix6_template 2a01:e3?:????:???0
# option suffix6 ::1/128

find_6to4_wanif() {
	local if=$(ip -4 r l e 0.0.0.0/0); if="${if#default* dev }"; if="${if%% *}"
	[ -n "$if" ] && grep -qs "^ *$if:" /proc/net/dev && echo "$if"
}

find_6to4_wanip() {
	local ip=$(ip -4 a s dev "$1"); ip="${ip#*inet }"
	echo "${ip%%[^0-9.]*}"
}

find_6to4_prefix() {
	local ip4="$1"
	local template="$2"

	[ -z "$template" ] && {
		template="2002:????:????"
	}

	local oIFS="$IFS"; IFS="."; set -- $ip4; IFS="$oIFS"
	local hex_ip4=$(printf "%02x%02x%02x%02x" $1 $2 $3 $4 | sed -e 's/\(.\)/\1 /g')

  for i in $hex_ip4; do
    template=$(echo $template | sed -e "s/?/$i/")
  done

  echo $template
}

test_6to4_rfc1918()
{
	local oIFS="$IFS"; IFS="."; set -- $1; IFS="$oIFS"
	[ $1 -eq  10 ] && return 0
	[ $1 -eq 192 ] && [ $2 -eq 168 ] && return 0
	[ $1 -eq 172 ] && [ $2 -ge  16 ] && [ $2 -le  31 ] && return 0
	return 1
}

set_6to4_radvd_interface() {
	local cfgid="$1"
	local lanif="${2:-lan}"
	local ifmtu="${3:-1280}"
	local ifsection=""

	find_ifsection() {
		local net
		local cfg="$1"
		config_get net "$cfg" interface

		[ "$net" = "$lanif" ] && {
			ifsection="$cfg"
			return 1
		}
	}

	config_foreach find_ifsection interface

	[ -z "$ifsection" ] && {
		ifsection="iface_$sid"
		uci_set_state radvd "$ifsection" "" interface
		uci_set_state radvd "$ifsection" interface "$lanif"
	}

	uci_set_state radvd "$ifsection" ignore            0
	uci_set_state radvd "$ifsection" IgnoreIfMissing   1
	uci_set_state radvd "$ifsection" AdvSendAdvert     1
	uci_set_state radvd "$ifsection" MaxRtrAdvInterval 30
	uci_set_state radvd "$ifsection" AdvLinkMTU        "$ifmtu"
}

set_6to4_radvd_prefix() {
	local cfgid="$1"
	local lanif="${2:-lan}"
	local wanif="${3:-wan}"
	local prefix="${4:-0:0:0:1::/64}"
	local vlt="${5:-300}"
	local plt="${6:-120}"
	local pfxsection=""

	find_pfxsection() {
		local net base
		local cfg="$1"
		config_get net  "$cfg" interface
		config_get base "$cfg" Base6to4Interface

		[ "$net" = "$lanif" ] && [ "$base" = "$wanif" ] && {
			pfxsection="$cfg"
			return 1
		}
	}

	config_foreach find_pfxsection prefix

	[ -z "$pfxsection" ] && {
		pfxsection="prefix_${sid}_${lanif}"
		uci_set_state radvd "$pfxsection" ""                   prefix
		uci_set_state radvd "$pfxsection" ignore               0
		uci_set_state radvd "$pfxsection" interface            "$lanif"
		uci_set_state radvd "$pfxsection" prefix               "$prefix"
		uci_set_state radvd "$pfxsection" AdvOnLink            1
		uci_set_state radvd "$pfxsection" AdvAutonomous        1
		uci_set_state radvd "$pfxsection" AdvValidLifetime     "$vlt"
		uci_set_state radvd "$pfxsection" AdvPreferredLifetime "$plt"
		uci_set_state radvd "$pfxsection" Base6to4Interface    "$wanif"
	}
}


# Hook into scan_interfaces() to synthesize a .device option
# This is needed for /sbin/ifup to properly dispatch control
# to setup_interface_6to4() even if no .ifname is set in
# the configuration.
scan_6to4() {
	config_set "$1" device "6to4-$1"
}

coldplug_interface_6to4() {
	setup_interface_6to4 "6to4-$1" "$1"
}

setup_interface_6to4() {
	local iface="$1"
	local cfg="$2"
	local link="6to4-$cfg"

	local local4=$(uci_get network "$cfg" ipaddr)

	local mtu
	config_get mtu "$cfg" mtu

	local ttl
	config_get ttl "$cfg" ttl

	local metric
	config_get metric "$cfg" metric

	local defaultroute
	config_get_bool defaultroute "$cfg" defaultroute 1


		local defaultroute_ip
		config_get defaultroute_ip "$cfg" defaultroute_ip
		[ -z "$defaultroute_ip" ] && {
			defaultroute_ip="192.88.99.1"
		}

	local wanif=$(find_6to4_wanif)
	[ -z "$wanif" ] && {
		logger -t "$link" "Cannot find wan interface - aborting"
		return
	}

	local wancfg=$(find_config "$wanif")
	[ -z "$wancfg" ] && {
		logger -t "$link" "Cannot find wan network - aborting"
		return
	}

	# If local4 is unset, guess local IPv4 address from the
	# interface used by the default route.
	[ -z "$local4" ] && {
		[ -n "$wanif" ] && {
			local4=$(find_6to4_wanip "$wanif")
			uci_set_state network "$cfg" wan_device "$wanif"
		}
	}

	test_6to4_rfc1918 "$local4" && {
		logger -t "$link" "Local wan ip $local4 is private - aborting"
		return
	}

	[ -n "$local4" ] && {
		logger -t "$link" "Starting ..."

		# creating the tunnel below will trigger a net subsystem event
		# prevent it from touching or iface by disabling .auto here
		uci_set_state network "$cfg" ifname $link
		uci_set_state network "$cfg" auto 0

		# find our local prefix
		local prefix6
		config_get prefix6 "$cfg" prefix6

		[ -z "$prefix6" ] && {
			local prefix6_template
			config_get prefix6_template "$cfg" prefix6_template
			prefix6=$(find_6to4_prefix "$local4" "$prefix6_template")
		}

		local suffix6
		config_get suffix6 "$cfg" suffix6
		[ -z "$suffix6" ] && {
			suffix6="::1/16"
		}

		local local6="$prefix6$suffix6"

		logger -t "$link" " * IPv4 address is $local4"
		logger -t "$link" " * IPv6 address is $local6"
		ip tunnel add $link mode sit remote any local $local4 ttl ${ttl:-64}
		ip link set $link up
		ip link set mtu ${mtu:-1280} dev $link
		ip addr add $local6 dev $link

		uci_set_state network "$cfg" ipaddr $local4
		uci_set_state network "$cfg" ip6addr $local6

		[ "$defaultroute" = 1 ] && {
			logger -t "$link" " * Adding default route"
			ip -6 route add 2000::/3 via ::$defaultroute_ip metric ${metric:-1} dev $link
			uci_set_state network "$cfg" defaultroute 1
		}

		[ -f /etc/config/radvd ] && /etc/init.d/radvd enabled && {
			local sid="6to4_$cfg"

			uci_revert_state radvd
			config_load radvd

			# find delegation target
			local adv_interface
			config_get adv_interface "$cfg" adv_interface

			local adv_subnet=$(uci_get network "$cfg" adv_subnet)
			      adv_subnet=$((0x${adv_subnet:-1}))

			local adv_subnets=""

			for adv_interface in ${adv_interface:-lan}; do
				local adv_ifname
				config_get adv_ifname "${adv_interface:-lan}" ifname

				grep -qs "^ *$adv_ifname:" /proc/net/dev && {
					local adv_valid_lifetime adv_preferred_lifetime
					config_get adv_valid_lifetime     "$cfg" adv_valid_lifetime
					config_get adv_preferred_lifetime "$cfg" adv_preferred_lifetime

					local subnet6="$(printf "%s:%x::1/64" "$prefix6" $adv_subnet)"

					logger -t "$link" " * Advertising IPv6 subnet $subnet6 on ${adv_interface:-lan} ($adv_ifname)"
					ip -6 addr add $subnet6 dev $adv_ifname

					set_6to4_radvd_interface "$sid" "$adv_interface" "$mtu"
					set_6to4_radvd_prefix    "$sid" "$adv_interface" \
						"$wancfg" "$(printf "0:0:0:%x::/64" $adv_subnet)" \
						"$adv_valid_lifetime" "$adv_preferred_lifetime"

					adv_subnets="${adv_subnets:+$adv_subnets }$adv_ifname:$subnet6"
					adv_subnet=$(($adv_subnet + 1))
				}
			done

			uci_set_state network "$cfg" adv_subnets "$adv_subnets"

			/etc/init.d/radvd restart
		}

		logger -t "$link" "... started"

		env -i ACTION="ifup" INTERFACE="$cfg" DEVICE="$link" PROTO=6to4 /sbin/hotplug-call "iface" &
	} || {
		echo "Cannot determine local IPv4 address for 6to4 tunnel $cfg - skipping"
	}
}

stop_interface_6to4() {
	local cfg="$1"
	local link="6to4-$cfg"

	local local6=$(uci_get_state network "$cfg" ip6addr)
	local defaultroute=$(uci_get_state network "$cfg" defaultroute)

		local defaultroute_ip
		config_get defaultroute_ip "$cfg" defaultroute_ip
		[ -z "$defaultroute_ip" ] && {
			defaultroute_ip="192.88.99.1"
		}

	local adv_subnets=$(uci_get_state network "$cfg" adv_subnets)

	grep -qs "^ *$link:" /proc/net/dev && {
		logger -t "$link" "Shutting down ..."
		env -i ACTION="ifdown" INTERFACE="$cfg" DEVICE="$link" PROTO=6to4 /sbin/hotplug-call "iface" &

		[ -n "$adv_subnets" ] && {
			uci_revert_state radvd
			/etc/init.d/radvd enabled && /etc/init.d/radvd restart

			local adv_subnet
			for adv_subnet in $adv_subnets; do
				local ifname="${adv_subnet%%:*}"
				local subnet="${adv_subnet#*:}"

				logger -t "$link" " * Removing IPv6 subnet $subnet from interface $ifname"
				ip -6 addr del $subnet dev $ifname
			done
		}

		[ "$defaultroute" = "1" ] && \
			ip -6 route del 2000::/3 via ::$defaultroute_ip dev $link

		ip addr del $local6 dev $link
		ip link set $link down
		ip tunnel del $link

		logger -t "$link" "... stopped"
	}
}

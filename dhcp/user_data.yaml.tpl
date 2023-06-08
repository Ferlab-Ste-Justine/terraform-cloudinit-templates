#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - path: /etc/dhcp-customization/dhcpd.conf
    owner: root:root
    permissions: "0644"
    content: |
      authoritative;
%{ if pxe.enabled ~}
      allow bootp;
      allow booting;
      option client-architecture code 93 = unsigned integer 16;
%{ endif ~}

%{ for network in dhcp.networks ~}
      subnet ${split("/", network.addresses).0} netmask ${cidrnetmask(network.addresses)} {
        option routers                  ${network.gateway};
        option broadcast-address        ${network.broadcast};
        option subnet-mask              ${cidrnetmask(network.addresses)};
        option domain-name-servers      ${join(", ", network.dns_servers)};
        range ${network.range_start} ${network.range_end};
      }
%{ endfor ~}

%{ if pxe.enabled ~}
      if exists user-class and option user-class = "iPXE" {
        filename "http://${pxe.self_url}/${pxe.boot_script_name}";
      } elsif option client-architecture = 00:00 {
        filename "undionly.kpxe";
      } else {
        filename "ipxe.efi";
      }
%{ endif ~}
  - path: /etc/dhcp-customization/isc-dhcp-server
    owner: root:root
    permissions: "0644"
    content: |
      INTERFACESv4="${join(" ", dhcp.interfaces)}"
      INTERFACESv6=""
  - path: /etc/dhcp-customization/apparmor-profile
    owner: root:root
    permissions: "0644"
    content: |
      # This file was adapted from its original format to give the
      # dhcp daemon access to the /etc/dhcp-customization directory
      # Original Author: Jamie Strandboge <jamie@canonical.com>

      #include <tunables/global>

      /usr/sbin/dhcpd {
        #include <abstractions/base>
        #include <abstractions/nameservice>
        #include <abstractions/ssl_keys>

        capability chown,
        capability net_bind_service,
        capability net_raw,
        capability setgid,
        capability setuid,

        network inet raw,
        network packet packet,
        network packet raw,

        @{PROC}/[0-9]*/net/dev r,
        @{PROC}/[0-9]*/net/{dev,if_inet6} r,
        owner @{PROC}/@{pid}/comm rw,
        owner @{PROC}/@{pid}/task/[0-9]*/comm rw,

        # LP: #1926139
        @{PROC}/cmdline r,

        /etc/hosts.allow r,
        /etc/hosts.deny r,

        /etc/dhcp/ r,
        /etc/dhcp/** r,
        /etc/dhcp-customization/ r,
        /etc/dhcp-customization/** r,
        /etc/dhcpd{,6}.conf r,
        /etc/dhcpd{,6}_ldap.conf r,

        /usr/sbin/dhcpd mr,

        /var/lib/dhcp/dhcpd{,6}.leases* lrw,
        /var/log/ r,
        /var/log/** rw,
        /{,var/}run/{,dhcp-server/}dhcpd{,6}.pid rw,

        # isc-dhcp-server-ldap
        /etc/ldap/ldap.conf r,

        # LTSP. See:
        # http://www.ltsp.org/~sbalneav/LTSPManual.html
        # https://wiki.edubuntu.org/
        /etc/ltsp/ r,
        /etc/ltsp/** r,
        /etc/dhcpd{,6}-k12ltsp.conf r,
        /etc/dhcpd{,6}.leases* lrw,
        /ltsp/ r,
        /ltsp/** r,

        # Eucalyptus
        /{,var/}run/eucalyptus/net/ r,
        /{,var/}run/eucalyptus/net/** r,
        /{,var/}run/eucalyptus/net/*.pid lrw,
        /{,var/}run/eucalyptus/net/*.leases* lrw,
        /{,var/}run/eucalyptus/net/*.trace lrw,

        # wicd
        /var/lib/wicd/* r,

        # access to bind9 keys for dynamic update
        # It's expected that users will generate one key per zone and have it
        # stored in both /etc/bind9 (for bind to access) and /etc/dhcp/ddns-keys
        # (for dhcpd to access).
        /etc/dhcp/ddns-keys/** r,

        # allow packages to re-use dhcpd and provide their own specific directories
        #include <dhcpd.d>

        # Site-specific additions and overrides. See local/README for details.
        #include <local/usr.sbin.dhcpd>
      }
  - path: /etc/systemd/system/isc-dhcp-server.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description=ISC DHCP IPv4 server
      Documentation=man:dhcpd(8)
      Wants=network-online.target
      After=network-online.target
      After=time-sync.target
      ConditionPathExists=/etc/dhcp-customization/isc-dhcp-server
      ConditionPathExists=|/etc/dhcp-customization/dhcpd.conf

      [Service]
      EnvironmentFile=/etc/dhcp-customization/isc-dhcp-server
      RuntimeDirectory=dhcp-server
      Restart=always
      RestartSec=1
      # The leases files need to be root:dhcpd even when dropping privileges
      ExecStart=/bin/sh -ec '\
          CONFIG_FILE=/etc/dhcp-customization/dhcpd.conf; \
          [ -e /var/lib/dhcp/dhcpd.leases ] || touch /var/lib/dhcp/dhcpd.leases; \
          chown root:dhcpd /var/lib/dhcp /var/lib/dhcp/dhcpd.leases; \
          chmod 775 /var/lib/dhcp ; chmod 664 /var/lib/dhcp/dhcpd.leases; \
          exec dhcpd -user dhcpd -group dhcpd -f -4 -pf /run/dhcp-server/dhcpd.pid -cf $CONFIG_FILE $INTERFACESv4'
%{ if pxe.static_boot_script != "" ~}
  - path: /var/www/html/${pxe.boot_script_name}
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, pxe.static_boot_script)}
%{ endif ~}

%{ if install_dependencies ~}
packages:
  - isc-dhcp-server
%{ if pxe.enabled ~}
  - tftpd-hpa
  - nginx
%{ endif ~}
%{ endif ~}

runcmd:
  - cp /etc/dhcp-customization/apparmor-profile /etc/apparmor.d/usr.sbin.dhcpd
  - apparmor_parser -r /etc/apparmor.d/usr.sbin.dhcpd
  - systemctl start isc-dhcp-server.service
  - systemctl enable isc-dhcp-server.service
%{ if pxe.enabled ~}
  - curl https://boot.ipxe.org/undionly.kpxe -o /var/lib/tftpboot/undionly.kpxe
  - curl https://boot.ipxe.org/ipxe.efi -o /var/lib/tftpboot/ipxe.efi
  - systemctl start tftpd-hpa.service
  - systemctl enable tftpd-hpa.service
  - systemctl start nginx.service
  - systemctl enable nginx.service
%{ endif ~}
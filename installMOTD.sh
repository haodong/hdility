#!/bin/sh

BLK='\033[1;30m'
WHT='\033[47m'
NC='\033[0m'
echo This script was written by
echo "${WHT}${BLK}"
cat << EOF
          _   _                     ____                                        
         | | | |   __ _    ___     |  _ \    ___    _ __     __ _               
         | |_| |  / _  |  / _ \    | | | |  / _ \  |  _ \   / _  |              
         |  _  | | (_| | | (_) |   | |_| | | (_) | | | | | | (_| |    _         
         |_| |_|  \__,_|  \___/    |____/   \___/  |_| |_|  \__, |   (_)        
                                                            |___/               
EOF
echo "${NC}"
echo It will install a set of MOTD to your Debian OS.
lsb_release -ds | grep -iq debian || {
    echo "Sorry, you're not using Debian."
    exit 1
}
read -p "Continue (y/n)? " ctn
ctn=${ctn:-n}
if [ "$ctn" != "y" ]; then
    exit 0
fi

if ! dpkg -l | grep -q figlet; then
    apt update
    apt install figlet -y
fi
mkdir -p /etc/update-motd.d
cat > /etc/update-motd.d/00-header << EOF
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "\$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=\$(lsb_release -s -d)
fi

CYAN='\033[0;36m'
NC='\033[0m'
echo "\${CYAN}"
figlet -cW \$(hostname)
echo "\${NC}"

GREEN='\033[0;32m'
printf "\${GREEN}  Welcome to %s (%s).\n" "\$DISTRIB_DESCRIPTION" "\$(uname -r)"
printf "\${NC}\n"
EOF

cat > /etc/update-motd.d/10-sysinfo << EOF
#!/bin/bash
#
#    10-sysinfo - generate the system information
#    Copyright (c) 2013 Nick Charlton
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

date=\`date\`
load=\`cat /proc/loadavg | awk '{print \$1}'\`
root_usage=\`df -h / | awk '/\\// {print \$(NF-1)}'\`
memory_usage=\`free -m | awk '/Mem/ { printf("%3.1f%%", \$3/\$2*100) }'\`
swap_usage=\`free -m | awk '/Swap/ { printf("%3.1f%%", \$3/\$2*100) }'\`
users=\`users | wc -w\`
ip_address=\$(dig +short myip.opendns.com @resolver1.opendns.com)

echo "  System information as of: \$date"
echo
YELLOW='\033[1;33m'
NC='\033[0m'
printf "\${YELLOW}  System load:\t%s\tMemory usage:\t%s\n" \$load \$memory_usage
printf "  Usage on /:\t%s\tSwap usage:\t%s\n" \$root_usage \$swap_usage
printf "  Local users:\t%s\tIP address:\t%s\${NC}\n" \$users \$ip_address
echo
EOF

cat > /etc/update-motd.d/20-updates << EOF
#!/usr/bin/python
#
#   20-updates - create the system updates section of the MOTD
#   Copyright (c) 2013 Nick Charlton
#
#   Authors: Nick Charlton <hello@nickcharlton.net>
#   Based upon prior work by Dustin Kirkland and Michael Vogt.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

import sys
import subprocess
import apt_pkg

DISTRO = subprocess.Popen(["lsb_release", "-c", "-s"],
                          stdout=subprocess.PIPE).communicate()[0].strip()

class OpNullProgress(object):
    '''apt progress handler which supresses any output.'''
    def update(self):
        pass
    def done(self):
        pass

def is_security_upgrade(pkg):
    '''
    Checks to see if a package comes from a DISTRO-security source.
    '''
    security_package_sources = [("Ubuntu", "%s-security" % DISTRO),
                               ("Debian", "%s-security" % DISTRO)]

    for (file, index) in pkg.file_list:
        for origin, archive in security_package_sources:
            if (file.archive == archive and file.origin == origin):
                return True
    return False

# init apt and config
apt_pkg.init()

# open the apt cache
try:
    cache = apt_pkg.Cache(OpNullProgress())
except SystemError, e:
    sys.stderr.write("Error: Opening the cache (%s)" % e)
    sys.exit(-1)

# setup a DepCache instance to interact with the repo
depcache = apt_pkg.DepCache(cache)

# take into account apt policies
depcache.read_pinfile()

# initialise it
depcache.init()

# give up if packages are broken
if depcache.broken_count > 0:
    sys.stderr.write("Error: Broken packages exist.")
    sys.exit(-1)

# mark possible packages
try:
    # run distro-upgrade
    depcache.upgrade(True)
    # reset if packages get marked as deleted -> we don't want to break anything
    if depcache.del_count > 0:
        depcache.init()

    # then a standard upgrade
    depcache.upgrade()
except SystemError, e:
    sys.stderr.write("Error: Couldn't mark the upgrade (%s)" % e)
    sys.exit(-1)

# run around the packages
upgrades = 0
security_upgrades = 0
for pkg in cache.packages:
    candidate = depcache.get_candidate_ver(pkg)
    current = pkg.current_ver

    # skip packages not marked as upgraded/installed
    if not (depcache.marked_install(pkg) or depcache.marked_upgrade(pkg)):
        continue

    # increment the upgrade counter
    upgrades += 1

    # keep another count for security upgrades
    if is_security_upgrade(candidate):
        security_upgrades += 1

    # double check for security upgrades masked by another package
    for version in pkg.version_list:
        if (current and apt_pkg.version_compare(version.ver_str, current.ver_str) <= 0):
            continue
        if is_security_upgrade(version):
            security_upgrades += 1
            break

WARNING = '\033[0;31m'
ENDC = '\033[0m'
print "  " + WARNING + "%d updates to install." % upgrades
print "  %d are security updates." % security_upgrades
print "" + ENDC # leave a trailing blank line
EOF

cat > /etc/update-motd.d/99-footer << EOF
#!/bin/sh
#
#    99-footer - write the admin's footer to the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -f /etc/motd.tail ] && cat /etc/motd.tail || true
EOF

chmod +x /etc/update-motd.d/*
ln -fs /run/motd /run/motd.dynamic
echo Congratulations! The MOTD has been installed successfully.
echo Logout and Login to see its face.
exit 0

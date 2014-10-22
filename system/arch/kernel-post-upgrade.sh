#!/usr/bin/bash -eu

die() {
	echo "error: $*" >&2
	exit 1
}

try_esp() {
	mountpoint -q "$1" && [[ -d "$1/EFI" ]] && [[ -d "$1/loader" ]]
}

check_kernel() {
	local kernel=$1
	local suffix=
	local config=$ID

	if [[ $kernel != 'linux' ]]; then
		suffix="-${kernel#linux-}"
		config=$config$suffix
	fi

	if [[ -e "/boot/vmlinuz-$kernel" ]]; then
		install_kernel
	else
		remove_kernel
	fi
}

install_kernel() {
	local version=

	if version=$(pacman -Q "$kernel" 2>/dev/null); then
		version=${version#"$kernel "}${suffix}
	else
		(die "package '$kernel' does not exist")
		return
	fi

	echo "Installing package: $kernel $version as \"$PRETTY_NAME\""

	echo "+ copying kernel to EFI system partition"
	mkdir -p "$ESP/EFI/$ID"
	cp -f "/boot/vmlinuz-$kernel"		"$ESP/EFI/$ID/vmlinuz-$kernel.efi"
	cp -f "/boot/intel-ucode.img"		"$ESP/EFI/$ID/intel-ucode.img"
	cp -f "/boot/initramfs-$kernel.img"	"$ESP/EFI/$ID/initramfs-$kernel.img"

	echo "+ generating bootloader config"
	parameters=(
		"title"		"$PRETTY_NAME"
		"version"	"$version"
		"machine-id"	"$MACHINE_ID"
		"linux"		"\\EFI\\$ID\\vmlinuz-$kernel.efi"
		"initrd"	"\\EFI\\$ID\\intel-ucode.img"
		"initrd"	"\\EFI\\$ID\\initramfs-$kernel.img"
		"options"	"$BOOT_OPTIONS"
	)
	mkdir -p "$ESP/loader/entries"
	printf '%s\t%s\n' "${parameters[@]}" > "$ESP/loader/entries/$config.conf"
}

remove_kernel() {
	echo "Uninstalling package: $kernel"

	echo "+ removing kernel from EFI system partition"
	rm -f "$ESP/EFI/$ID/vmlinuz-$kernel.efi"
	rm -f "$ESP/EFI/$ID/initramfs-$kernel.img"

	echo "+ removing bootloader config"
	rm -f "$ESP/loader/entries/$config.conf"
}

unset ID NAME PRETTY_NAME MACHINE_ID BOOT_OPTIONS

if try_esp /boot/efi; then
	ESP=/boot/efi
elif try_esp /boot; then
	ESP=/boot
else
	die "EFI system partition not found; please \`mkdir <efisys>/loader\`"
fi

echo "Found EFI system partition at $ESP"

if [[ -e /etc/os-release ]]; then
	os_release=/etc/os-release
elif [[ -e /usr/lib/os-release ]]; then
	os_release=/usr/lib/os-release
else
	die "/usr/lib/os-release not found or invalid; see os-release(5)"
fi

. "$os_release" ||
	die "$os_release not found or invalid; see os-release(5)"

[[ ${PRETTY_NAME:=$NAME} ]] ||
	die "$os_release is missing both PRETTY_NAME and NAME; see os-release(5)"

[[ $ID ]] ||
	die "$os_release is missing ID; see os-release(5)"

read -r MACHINE_ID < /etc/machine-id ||
	die "/etc/machine-id not found or empty; see machine-id(5)"

[[ -s /etc/kernel/cmdline ]] ||
	die "/etc/kernel/cmdline not found or empty; please configure it"

BOOT_OPTIONS=(`grep -v "^#" /etc/kernel/cmdline`)
BOOT_OPTIONS=${BOOT_OPTIONS[*]}

check_kernel "${1:-linux}"

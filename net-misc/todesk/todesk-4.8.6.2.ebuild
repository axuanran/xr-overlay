# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

MY_P="${PN}-v${PV}"
MY_DIST="${MY_P}-amd64.deb"

DESCRIPTION="ToDesk remote desktop client"
HOMEPAGE="https://www.todesk.com"
SRC_URI="https://dl.todesk.com/linux/${MY_DIST}"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"

# Proprietary prebuilt binaries must not be stripped or redistributed.
RESTRICT="bindist mirror strip"

RDEPEND="
    dev-libs/libayatana-appindicator
    media-libs/libpulse
    sys-apps/systemd-utils
"

QA_PREBUILT="
    opt/todesk/*
"

src_install() {
    # Preserve the modes supplied by the official Debian package.
    dodir /opt/todesk
    cp -a --no-preserve=ownership \
        "${S}/opt/todesk/." \
        "${ED}/opt/todesk/" || die "Failed to install ToDesk files"

    # ToDesk expects Ubuntu's old libappindicator filename.
    rm -f \
        "${ED}/opt/todesk/bin/libappindicator3.so.1" \
        || die

    dosym -r \
        "/usr/$(get_libdir)/libayatana-appindicator3.so" \
        "/opt/todesk/bin/libappindicator3.so.1"

    # Install the official launcher.
    exeinto /opt/bin
    doexe "${S}/usr/local/bin/todesk"

    # Desktop entry.
    domenu "${S}/usr/share/applications/todesk.desktop"

    # Application icons.
    local size
    for size in 16 24 32 48 64 128 256 512; do
        if [[ -f "${S}/usr/share/icons/hicolor/${size}x${size}/apps/todesk.png" ]]; then
            doicon -s "${size}" \
                "${S}/usr/share/icons/hicolor/${size}x${size}/apps/todesk.png"
        fi
    done

    # OpenRC service.
    newinitd "${FILESDIR}/todeskd.initd" todeskd
}

pkg_postinst() {
    xdg_pkg_postinst

    elog
    elog "Start the ToDesk daemon with:"
    elog "  rc-service todeskd start"
    elog
    elog "Enable it at boot with:"
    elog "  rc-update add todeskd default"
    elog
    elog "Then launch the GUI as a normal desktop user:"
    elog "  todesk"
}

# Maintainer: sukkergris
pkgname=ytcast-tui-git
pkgver=r10.dad6d3f
pkgrel=1
pkgdesc='YouTube Music on Chromecast speakers from the terminal, e.g. Harman Kardon Citation (unofficial)'
arch=(any)
url='https://github.com/sukkergris/ytcast-tui'
license=(MIT)
depends=(bash fzf curl iproute2 python python-pychromecast yt-dlp)
makedepends=(git)
provides=(ytcast-tui)
conflicts=(ytcast-tui)
source=("git+$url.git")
sha256sums=(SKIP)

pkgver() {
    cd ytcast-tui
    printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd ytcast-tui
    install -Dm755 bin/ytcast "$pkgdir/usr/bin/ytcast"
    install -Dm755 bin/ytcast-player "$pkgdir/usr/bin/ytcast-player"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}

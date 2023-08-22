.PHONY: install

install:
	install -Dm 775 ./wmrc.sh /usr/bin/wmrc
	sed -i 's/^WMRC_DIR=.*$$/WMRC_DIR=\/usr\/share\/wmrc/' /usr/bin/wmrc
	install -Dm 664 ./libwmrc.sh /usr/share/wmrc/libwmrc.sh
	install -dm 755 /usr/share/man/man1
	gzip -ck wmrc.1.man > /usr/share/man/man1/wmrc.1.gz

uninstall:
	rm -f /usr/bin/wmrc
	rm -fr /usr/share/wmrc
	rm -f /usr/share/man/man1/wmrc.1.gz

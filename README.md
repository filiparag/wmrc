## About
**wmrc** is shell utility for extending window manager capabilities using modules with dependency and error checking.

By using wmrc, you can declutter your *.profile* and window manager's configuration file, while gaining modularity and portability. If set up correctly, a single wmrc configuration can have modules which work across multiple window managers and init deamons.

## Installation

### Generic instructions
```shell
git clone 'https://github.com/filiparag/wmrc' && cd ./wmrc
sudo install -Dm 775 ./wmrc.sh /usr/bin/wmrc
sudo install -Dm 664 ./libwmrc.sh /usr/share/wmrc/libwmrc.sh
sudo install -Dm 664 wmrc.man /usr/share/man/man1/wmrc
sudo sed -i 's/^WMRC_DIR=.*$/WMRC_DIR=\/usr\/share\/wmrc/' /usr/bin/wmrc
```

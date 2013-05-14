name             "myblog"
maintainer       "Tom Duffield"
maintainer_email "tom.duffield@gmail.com"
license          "All rights reserved"
description      "Installs/Configures myblog"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.2"

recipe "myblog::default", "Installs a self-contained wordpress blog on a single server."
recipe "myblog::frontend", "Installs Wordpress and configures it to talk to a MySQL Database"
recipe "myblog::backend", "Installs a MySQL server"
recipe "myblog::sensu_server", "Installs a stand-alone sensu server with some basic checks."

supports "rhel"
supports "ubuntu"

depends 'wordpress', '= 1.0.0'
depends 'partial_search', '= 1.0.0'
depends 'sensu', '= 0.5.0'

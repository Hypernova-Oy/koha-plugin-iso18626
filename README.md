# koha-plugin-iso18626
ISO 18626:2021 implemented to Koha ILS

# Downloading

From the [release page](https://github.com/Hypernova-Oy/koha-plugin-iso18626/releases) you can download the relevant *.kpz file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.

# Updating

After updating the plugin, you must restart plack to update the new REST endpoints.

# Testing

    KOHA_CONF=/etc/koha/sites/demo_1/koha-conf.xml PERL5LIB="$PERL5LIB:/usr/share/koha/lib/:." perl t/*

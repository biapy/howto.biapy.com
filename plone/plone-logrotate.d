# Logrotate configuration file for Plone buildout

"%LOG_PATH%/*/*.log" {
    weekly
    missingok
    rotate 52
    copytruncate
    compress                                                      
    delaycompress
    notifempty
    create
    sharedscripts
    postrotate
    sh -c '[ -x "/etc/init.d/plone-%INSTANCE_NAME%" ] && /etc/init.d/plone-%INSTANCE_NAME% logreopen'
    endscript
}


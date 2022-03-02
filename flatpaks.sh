app_name=com.belmoussaoui.Authenticator
app_name=com.microsoft.Teams
app_name=flathub com.poweriso.PowerISO
app_name=com.github.micahflee.torbrowser-launcher
app_name=com.github.phase1geo.minder

flatpak install flathub ${app_name}

sudo ln \
    /var/lib/flatpak/app/${app_name}/current/active/files/share/applications/${app_name}.desktop \
    /usr/share/applications/${app_name}.desktop

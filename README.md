# Computer-Security

## About
Department of Defense Security Technical Implementation Guides (STIGS) for MacOS and Windows 10 
## License
GNU General Public License V3.0
## References
See https://iase.disa.mil/stigs/Pages/index.aspx
## Files
* MacOS-update.sh
	* Apple OS X 10.12 (Sierra) Security Technical Implementation Guide (STIG) Version 1, 8 August 2017
```
sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep LastSuccessfulDate | sed -e 's@^.* "\([0-9\\-]*\) .*$@\1@'); if [ "$LASTUPDATE" = "$(date +%Y-%m-%d)" ];then exit 0; fi; exit 1
sudo /usr/bin/softwareupdate -i -a
```
* Windows10-update.psh
	* Microsoft Windows 10 Security Technical Implementation Guide (STIG) Version 1, 25 November 2015
```
$CompObj | Add-Member noteproperty Computername $computer.Name
      
        If($computer.'ms-Mcs-AdmPwdExpirationTime' -eq $null){$ExpirationDate = $computer.'ms-Mcs-AdmPwdExpirationTime'}
        Else {$ExpirationDate = [DateTime]::FromFileTime($computer.'ms-Mcs-AdmPwdExpirationTime')} 
$CompObj | Add-Member noteproperty NextPasswordExpiration $ExpirationDate
```
* Linux-hardening.sh
	* Ubuntu Linux 18.04 --> modified Canonical Ubuntu 16.04 LTS Security Technical Implementation Guide (STIG) Version 1, Release 1 25 July 2018 using scripts from JackTheStripper and others.
```
restrictive_umask(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Setting UMASK to a more Restrictive Value (027)"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   spinner
   cp templates/login.defs /etc/login.defs
   # sed -i s/umask\ 022/umask\ 027/g /etc/init.d/rc
   echo ""
   echo "OK"
   say_done
}
```



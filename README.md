# check_tomcat_applications
Check Tomcat applications via tomcat manager.

## Setup
You need to have curl installed, on systems using apt, use:
```
apt install curl
```

Furthermore, in order to authenticate to tomcat, add a dedicated user to conf/tomcat-users.xml as such:
```
<user username="icinga" password="YOUR_PASSWORD" roles="manager-script"/>
```

## Usage
```
Usage: check_tomcat_applications [OPTIONS]
  [OPTIONS]:
  -U URL        URL to Tomcat Status Call (default: $url)
  -u USER       Username
  -p PASSWORD   Password
  -f FILE       Instead of USER and PASSWORD, read credentials from FILE
  -c CHECK      List of application names to check, comma seperated
  -i INSECURE   Sets the --insecure flag of curl
```

## Example Outputs
All good:
```
All applications (myService,someOtherService) are running on Tomcat
```

Application not found:
```
Application(s) that cannot be found: nonExistent
```

Wrong status:
```
Application(s) in non running status: myService = 'stopped'
```

## Command Template
```
object CheckCommand "check-tomcat-applications" {
  command = [ ConfigDir + "/scripts/check_tomcat_applications.sh" ]
  arguments += {
    "-U" = "$cta_url$"
    "-u" = "$cta_user$"
    "-p" = "$cta_password$"
    "-c" = "$cta_check$"
  }
}
```


#!/bin/bash
# startup checks

if [ -z "$BASH" ]; then
  echo "Please use BASH."
  exit 3
fi
if [ ! -e "/usr/bin/which" ]; then
  echo "/usr/bin/which is missing."
  exit 3
fi
curl=$(which curl)
if [ $? -ne 0 ]; then
  echo "Please install 'curl'."
  exit 3
fi


url="http://127.0.0.1:8080/manager/text/list"

# Usage Info
usage() {
  echo '''Usage: check_tomcat_applications [OPTIONS]
  [OPTIONS]:
  -U URL        URL to Tomcat Status Call (default: $url)
  -u USER       Username
  -p PASSWORD   Password
  -f FILE       Instead of USER and PASSWORD, read credentials from FILE
  -c CHECK      List of application names to check, comma seperated
  -i INSECURE   Sets the --insecure flag of curl'''
}


#main
#get options
while getopts "U:u:p:f:c:i:" opt; do
  case $opt in
    U)
      url=$OPTARG
      ;;
    u)
      user=$OPTARG
      ;;
    p)
      password=$OPTARG
      ;;
    f)
      file=$OPTARG
      ;;
    c)
      check=$OPTARG
      ;;
    i)
      insecure=1
      ;;
    *)
      usage
      exit 3
      ;;
  esac
done

# check for required / valid parameters 
if [ -z "$check" ]; then
  echo "Error: No application name provided to check, use -c"
  echo ""
  usage
  exit 3
fi

if [ -z "$file" ] && ( [ -z "$user" ] || [ -z "$password" ] ); then
  echo "Error: Either provide the credentials with -u & -p or through -f"
  echo ""
  usage
  exit 3
fi

# load from file if no user is set
if [ -z "$user" ]; then
  login=`cat $file 2> /dev/null`
  ret=$?
  if [ "$ret" -ne "0" ];then
    echo "Cannot load file provided by -f $file"
    exit 3
  fi
  if [[ $login != *":"* ]]; then
    echo "Credential string in file $file does not contain a : - syntax is 'username':'password'"
    exit 3
  fi
else
  login=$user":"$password
fi

insecurearg=""
if [[ $insecure -eq 1 ]]; then
  insecurearg=" --insecure "
fi

# do the curl
body=$(curl -s -w "-%{http_code}" -u $login $url $insecurearg)
code=${body: -3}
bodyshort=${body:0:400}

# exit if we don't get HTTP 200
if [[ $code -ne 200 ]]; then
  if [[ $code -eq 000 ]]; then
    echo "Curl failed to connect"
    body=$(curl -s -u $login $url $insecurearg --verbose)
    echo $body
  else
    echo "Response code is not 200 but $code"
    echo ""
    echo "Reponse body is: $bodyshort . . . "
  fi
  exit 3
fi

# evaluate state for all applications
allrunning=true
notrunning=""
wrongstate=""

IFS=','
for application in $check
do
  if [[ $body != *"$application:running"* ]]; then
    allrunning=false
    if [[ $body != *"$application:"* ]]; then
      notrunning=$notrunning$application","
    else
      status=$(echo "$body" | grep -o -P '(?<='$application':).*?(?=:)')
      wrongstate=$wrongstate$application" = '$status' , "
    fi
  fi
done

if [ $allrunning == true ]; then
  echo "All applications ($check) are running on Tomcat"
else
  if [ ! -z "$notrunning" ]; then
    echo "Application(s) that cannot be found: ${notrunning:0:-1}"
  fi
  if [ ! -z "$wrongstate" ]; then
    echo "Application(s) in non running status: ${wrongstate:0:-2}"
  fi
  exit 2
fi

#!/usr/bin/env bash

DEFAULT_MAVEN_VERSION="3.3.9"

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|JAVA_OPTS)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

real_curl=$(which curl)
function curl() {
  local http_url=''
  local write_file=''
  local create_output_filename=''
  local curl_args=$*

  for i ; do
    case "$i" in
    -O|--remote-name)
      create_output_filename=true
      shift;;
    -o|--output)
      if [[ ${2} != "-" ]]
      then
        write_file=${2}
      fi
      shift; shift;;
    -s|--silent)
      shift;;
    -L|--location|--)
      http_url=${2}; shift;
      filename=$(sed 's/[:\/]/_/g' <<< ${http_url})
      shift;
    esac
  done

  ## Do we have to generate a filename ourselves to write to?
  if [[ -n "$create_output_filename" ]]
  then
    write_file=$(echo ${http_url} | rev | cut -d\/ -f1 | rev)
  fi

  if test -f $BIN_DIR/../dependencies/$filename
  then
    ## Was a file to write to provided?
    if [[ -n "$write_file" ]]
    then
      ## Write to file
      cat $BIN_DIR/../dependencies/$filename > $write_file
    else
      # Stream output
    cat $BIN_DIR/../dependencies/$filename
    fi
  else
    $real_curl $curl_args
  fi
}

install_maven() {
  local installDir=$1
  local buildDir=$2
  mavenHome=$installDir/.maven

  definedMavenVersion=$(detect_maven_version $buildDir)

  mavenVersion=${definedMavenVersion:-$DEFAULT_MAVEN_VERSION}

  status_pending "Installing Maven ${mavenVersion}"
  if is_supported_maven_version ${mavenVersion}; then
    mavenUrl="http://lang-jvm.s3.amazonaws.com/maven-${mavenVersion}.tar.gz"
    download_maven ${mavenUrl} ${installDir} ${mavenHome}
    status_done
  else
    error_return "Error, you have defined an unsupported Maven version in the system.properties file.
The default supported version is ${DEFAULT_MAVEN_VERSION}"
    return 1
  fi
}

download_maven() {
  local mavenUrl=$1
  local installDir=$2
  local mavenHome=$3
  rm -rf $mavenHome
  curl --retry 3 --silent --max-time 60 --location ${mavenUrl} | tar xzm -C $installDir
  chmod +x $mavenHome/bin/mvn
}

is_supported_maven_version() {
  local mavenVersion=${1}
  if [ "$mavenVersion" = "$DEFAULT_MAVEN_VERSION" ]; then
    return 0
  elif [ "$mavenVersion" = "3.2.5" ]; then
    return 0
  elif [ "$mavenVersion" = "3.2.3" ]; then
    return 0
  elif [ "$mavenVersion" = "3.1.1" ]; then
    return 0
  elif [ "$mavenVersion" = "3.0.5" ]; then
    return 0
  else
    return 1
  fi
}

detect_maven_version() {
  local baseDir=${1}
  if [ -f ${baseDir}/system.properties ]; then
    mavenVersion=$(get_app_system_value ${baseDir}/system.properties "maven.version")
    if [ -n "$mavenVersion" ]; then
      echo $mavenVersion
    else
      echo ""
    fi
  else
    echo ""
  fi
}

get_app_system_value() {
  local file=${1?"No file specified"}
  local key=${2?"No key specified"}

  # escape for regex
  local escaped_key=$(echo $key | sed "s/\./\\\./g")

  [ -f $file ] && \
  grep -E ^$escaped_key[[:space:]=]+ $file | \
  sed -E -e "s/$escaped_key([\ \t]*=[\ \t]*|[\ \t]+)([A-Za-z0-9\.-]*).*/\2/g"
}

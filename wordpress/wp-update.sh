#!/bin/bash
#
# Wordpress update cron scripts.
#
# Use wp-cli to update local wordpress instances.
# List wordpress instances path in /etc/wp-update.conf
# (one path per line)
#
# For suggestion and bug reports, please contact
# Pierre-Yves Landuré <pierre-yves dot landure at biapy dot fr>
#
version="0.1.0"

# History
# -------
#
#
# 0.1.0
#  - First public release.
#

# wp-update configuration file path.
wpUpdateConfFile='/etc/wp-update.conf'



# Echo text in color.
#
# Colors definitions.
# See http://mywiki.wooledge.org/BashFAQ/037
#
# @param string $color Color and weight for text. (boldgreen for example).
# @param string $text The text to echo (and echo options).
function cecho() {
  if [[ ${#} -lt 2 ]]; then
    echo "${@}"
    return 0
  fi

  local color="${1}"

  # remove color information from arguments.
  shift 1

  # Check that the output is to a terminal.
  if [[ ! -t 1 ]]; then
    # Not outputing to a terminal, discaring colors.
    echo "${@}"
    return 0
  fi

  # Bash 4 version with associative array.
  ## Color and weight definitions.
  #declare -A font
  #font['black']="$(tput 'setaf' 0)"
  #font['red']="$(tput 'setaf' 1)"
  #font['green']="$(tput 'setaf' 2)"
  #font['yellow']="$(tput 'setaf' 3)"
  #font['blue']="$(tput 'setaf' 4)"
  #font['magenta']="$(tput 'setaf' 5)"
  #font['cyan']="$(tput 'setaf' 6)"
  #font['white']="$(tput 'setaf' 7)"

  #font['bgBlack']="$(tput 'setab' 0)"
  #font['bgRed']="$(tput 'setab' 1)"
  #font['bgGreen']="$(tput 'setab' 2)"
  #font['bgYellow']="$(tput 'setab' 3)"
  #font['bgBlue']="$(tput 'setab' 4)"
  #font['bgMagenta']="$(tput 'setab' 5)"
  #font['bgCyan']="$(tput 'setab' 6)"
  #font['bgWhite']="$(tput 'setab' 7)"

  #font['bold']="$(tput 'bold')"
  #font['stout']="$(tput 'smso')" # Standout.
  #font['under']="$(tput 'smul')" # Underline.
  #font['blink']="$(tput 'blink')" # Blinking
  #font['italic']="$(tput 'sitm')"

  ## Parse the color string.
  #for key in "${!font[@]}"; do
  #  [[ "${color}" = *"${key}"* ]] && echo -n "${font[${key}]}"
  #done

  declare -a fontIndex
  declare -a fontValue

  fontIndex=()
  fontValue=()

  fontIndex+=( 'black' );     fontValue+=( "$(tput 'setaf' 0)" )
  fontIndex+=( 'red' );       fontValue+=( "$(tput 'setaf' 1)" )
  fontIndex+=( 'green' );     fontValue+=( "$(tput 'setaf' 2)" )
  fontIndex+=( 'yellow' );    fontValue+=( "$(tput 'setaf' 3)" )
  fontIndex+=( 'blue' );      fontValue+=( "$(tput 'setaf' 4)" )
  fontIndex+=( 'magenta' );   fontValue+=( "$(tput 'setaf' 5)" )
  fontIndex+=( 'cyan' );      fontValue+=( "$(tput 'setaf' 6)" )
  fontIndex+=( 'white' );     fontValue+=( "$(tput 'setaf' 7)" )

  fontIndex+=( 'bgBlack' );   fontValue+=( "$(tput 'setab' 0)" )
  fontIndex+=( 'bgRed' );     fontValue+=( "$(tput 'setab' 1)" )
  fontIndex+=( 'bgGreen' );   fontValue+=( "$(tput 'setab' 2)" )
  fontIndex+=( 'bgYellow' );  fontValue+=( "$(tput 'setab' 3)" )
  fontIndex+=( 'bgBlue' );    fontValue+=( "$(tput 'setab' 4)" )
  fontIndex+=( 'bgMagenta' ); fontValue+=( "$(tput 'setab' 5)" )
  fontIndex+=( 'bgCyan' );    fontValue+=( "$(tput 'setab' 6)" )
  fontIndex+=( 'bgWhite' );   fontValue+=( "$(tput 'setab' 7)" )

  fontIndex+=( 'bold' );      fontValue+=( "$(tput 'bold')" )
  fontIndex+=( 'stout' );     fontValue+=( "$(tput 'smso')" ) # Standout.
  fontIndex+=( 'under' );     fontValue+=( "$(tput 'smul')" ) # Underline.
  fontIndex+=( 'blink' );     fontValue+=( "$(tput 'blink')" ) # Blinking.
  fontIndex+=( 'italic' );    fontValue+=( "$(tput 'sitm')" )

  for key in "${!fontIndex[@]}"; do
    [[ "${color}" = *"${fontIndex[${key}]}"* ]] && echo -n "${fontValue[${key}]}"
  done

  # Output the text.
  echo "${@}"

  # Reset all attributes.
  tput 'sgr0'

  return 0
} # cecho()
export -f 'cecho'



# Check if a binary is present. Print its path on &1 if found.
#
# @param string $binary The binaries to check, separated by ;.
# @param string $package The package the binary come from.
#
# @return Exit with error if the binary is missing.
function check_binary() {
  [[ ${#} -ne 2 ]] && exit 1

  local primary
  local binaries
  local binary

  primary="${1%%;*}"
  binaries=()

  read -d ';' -r -a binaries <<< "${1}"

  # Test the binary presence.
  for binary in "${binaries[@]}"; do
    if type "${binary}" &>'/dev/null'; then
      command -v "${binary}"
      return 0
    fi
  done

  cecho 'redbold' "Error: '${primary}' is missing. Please install package '${2}'." >&2
  exit 1
} # check_binary()

#######################################################################################
#######################################################################################
#######################################################################################
# Check for binaries presence
check_binary "wp" "wp-cli" > '/dev/null'
check_binary "php" "php-cli" > '/dev/null'

if [[ ! -e "${wpUpdateConfFile}" ]]; then
  cecho 'redbold' "Error: configuration file is missing.
Please create '${wpUpdateConfFile}' file
with one Wordpress installation path per line." >&2
  exit 1
fi

while read -r wordpressInstallPath; do
  if [[ -e "${wordpressInstallPath}/wp-config.php" ]]; then
  	wordpressInstallUser="$(stat -c '%U' "${wordpressInstallPath}")"

  	cecho 'greenbold' "Updating Wordpress at ${wordpressInstallPath}..."

  	# update wordpress core
  	cecho 'cyanbold' " - Updating core..."
    sudo -u "${wordpressInstallUser}" wp --quiet --path="${wordpressInstallPath}" core update
    
    # update wordpress plugins
  	cecho 'cyanbold' " - Updating plugins..."
    sudo -u "${wordpressInstallUser}" wp --quiet --path="${wordpressInstallPath}" plugin update --all

    # update wordpress themes
  	cecho 'cyanbold' " - Updating themes..."
    sudo -u "${wordpressInstallUser}" wp --quiet --path="${wordpressInstallPath}" theme update --all

    # update wordpress languages files.
  	cecho 'cyanbold' " - Updating language files..."
    sudo -u "${wordpressInstallUser}" wp --quiet --path="${wordpressInstallPath}" core language update
  else
   cecho 'yellowbold' "Warning: no wordpress found in '${wordpressInstallPath}'." >&2 	
  fi
done < "${wpUpdateConfFile}"


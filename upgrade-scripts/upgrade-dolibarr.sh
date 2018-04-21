#!/bin/bash


# Get the absolute path for a file or directory.
# Print its path on &1 if found.
#
# @param string $path A relative path.
#
# @return ${realpath} A absolute path.
function realpath() {
  [[ ${#} -ne 1 ]] && exit 1

  local realpath

  case "$(uname)" in
    'Linux' )
      realpath="$(readlink -f "${1}")"
      ;;
    'Darwin' )
      realpath="$(stat -f '%N' "${1}")"
      ;;
    * )
      realpath="$(realpath "${1}")"
      ;;
  esac

  echo -n "${realpath}"
  return 0
} # realpath



if [[ ${#} -ne 1 ]]; then
  echo "Error: non install path provided."
  exit 1
fi

INSTALL_PATH="$(realpath "${1}")"

if [[ ! -d "${INSTALL_PATH}/htdocs/fichinter" ]]; then
  echo "Error '${INSTALL_PATH}' n'est pas une installation valide de Dolibarr."
  exit 1
fi

echo "Backuping current installation."
if [ -d "${INSTALL_PATH}.old" ]; then
  command rm -r "${INSTALL_PATH}.old"
fi
command cp -a "${INSTALL_PATH}" "${INSTALL_PATH}.old"

echo "Downloading new version of Dolibarr."
command wget 'https://raw.github.com/biapy/howto.biapy.com/master/various/sf-downloader' \
    --quiet --no-check-certificate --output-document='/tmp/sf-downloader'
SOURCE="$(command bash '/tmp/sf-downloader' --zip --strip-components=1 \
    --output-directory="${INSTALL_PATH}" \
    --download-template='Dolibarr ERP-CRM/VERSION/dolibarr-VERSION.zip' \
    'dolibarr' 'dolibarr-VERSION.zip')"

echo "Adjusting permissions."
command find "${INSTALL_PATH}" -type d -exec chmod 755 "{}" \+
command find "${INSTALL_PATH}" -type f -exec chmod 644 "{}" \+

command find "${INSTALL_PATH}/htdocs" -type f -exec chown www-data:www-data "{}" \+

if [ -e "${INSTALL_PATH}/documents/install.lock" ]; then
  command rm "${INSTALL_PATH}/documents/install.lock"
fi

DOMAIN="$(basename "${INSTALL_PATH}")"

echo "Install lock removed.
Please visit http://${DOMAIN}/ to finish upgrade.

Once the upgrade is finished, please run these command to lock the install:

command touch '${INSTALL_PATH}/documents/install.lock'
command chown -R root:root '${INSTALL_PATH}'
command rm -r '${INSTALL_PATH}/htdocs/install'
"

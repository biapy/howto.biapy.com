#!/bin/bash
#
# Backuping the EasyCreadoc installation.
# Ran by Backup Manager for folders that are to big to be compressed.
# It use Backup Manager FTP settings to copy the specified folders on a distant FTP.
#
# Require : ncftpput

# We check the existance of ncftpput
if [ ! -x /usr/bin/yafc ]; then
  echo "ERROR: yafc is needed by this script. Please install yafc by using : apt-get install yafc"
  exit 1
fi

# If the backup-manager configuration file is not present. We die in excruciating pain ;D.
if [ ! -e /etc/backup-manager.conf ]; then
  echo "ERROR: Backup Manager is not present on your system."
  exit 1
fi

# If the ftp-copy configuration file is not present. We die in excruciating pain ;D.
if [ ! -e /etc/backup-manager/ftp-copy.conf ]; then
  echo "ERROR: unable to find ftp-copy.conf configuration file in /etc/backup-manager/."
  exit 1
fi

# We sources the configuration files.
source /etc/backup-manager.conf
source /etc/backup-manager/ftp-copy.conf

# We test the availability of FTP parameters.
# If some are missing, we die.
if [ -z "${BM_UPLOAD_FTP_HOSTS}" -o -z "${BM_UPLOAD_FTP_USER}" -o -z "${BM_UPLOAD_FTP_PASSWORD}" ]; then
  echo "ERROR: Backup Manager Upload FTP is not configured."
  exit 1
fi

# We detect the target destination folder.
COPY_DESTINATION="/"

if [ -n "${BM_UPLOAD_FTP_DESTINATION}" ]; then
  COPY_DESTINATION="${BM_UPLOAD_FTP_DESTINATION}"
fi

if [ -n "${FTP_COPY_DESTINATION}" ]; then
  COPY_DESTINATION="${FTP_COPY_DESTINATION}"
fi

for FOLDER in ${FTP_COPY_FOLDERS}; do
  if [ ! -d ${FOLDER} ]; then
    echo "WARNING : This path is not a folder : ${FOLDER}."
  else
    STRIPPED_SLASHES_FOLDER=$(/bin/echo ${FOLDER} \
                | /usr/bin/tr "/" "-" \
                | /bin/sed -e 's/^[-]*\([^-].*[^-]\)[-]*$/\1/')
    TARGET=$(/bin/echo "${COPY_DESTINATION}/${BM_ARCHIVE_PREFIX}-${STRIPPED_SLASHES_FOLDER}" \
                | /bin/sed -e 's|[/]\{1,\}|/|g')

    # We upload modified files, replacing the ones already present on the FTP
    /bin/echo "put --newer --recursive --preserve --output=${TARGET} ${FOLDER}" \
                | /usr/bin/yafc "ftp://${BM_UPLOAD_FTP_USER}:${BM_UPLOAD_FTP_PASSWORD}@${BM_UPLOAD_FTP_HOSTS}/" > /dev/null 2>&1

    # We try to complete the files that could have been broken during transfert.
    # This step is optionnal, since it take time, but it is recommended.
    /bin/echo "put --resume --recursive --preserve --output=${TARGET} ${FOLDER}" \
                | /usr/bin/yafc "ftp://${BM_UPLOAD_FTP_USER}:${BM_UPLOAD_FTP_PASSWORD}@${BM_UPLOAD_FTP_HOSTS}/" > /dev/null 2>&1
  fi
done

exit 0

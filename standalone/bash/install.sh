#!/usr/bin/env bash

lisa_has() {
  type "$1" > /dev/null 2>&1
}

lisa_default_install_dir() {
  printf %s "${HOME}/.listenai/lisa"
}

lisa_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

lisa_download() {
  if lisa_has "curl"; then
    command curl --fail --compressed -q "$@"
  elif lisa_has "wget"; then
    ARGS=$(lisa_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
                            -e 's/--compressed //' \
                            -e 's/--fail //' \
                            -e 's/-L //' \
                            -e 's/-I /--server-response /' \
                            -e 's/-s /-q /' \
                            -e 's/-sS /-nv /' \
                            -e 's/-o /-O /' \
                            -e 's/-C - /-c /')
    eval wget $ARGS
  else
    lisa_echo "You need either curl or wget to download packages"
    exit 1
  fi
}

lisa_tar() {
  if lisa_has "tar"; then
    command pv "$1" |tar xJf - -C "$2"
  else
    lisa_echo >&2 'You need tar to install Lisa'
    exit 1
  fi
}

lisa_unzstd() {
  if lisa_has "unzstd" && lisa_has "tar"; then
    command pv "$1" |tar -I zstd -xf -  -C "$2"
  else
    lisa_echo >&2 'You need tar and zstd to install Lisa'
    exit 1
  fi
}

lisa_shell_command_link() {
  lnpath="/usr/local/bin/lisa"
  if [ -L "$lnpath" ]; then
    sudo rm -f $lnpath;
  fi
  lisa_echo "=> ${LISA_BIN}/lisa -> $lnpath"
  sudo ln -s "${LISA_BIN}/lisa" $lnpath
}

lisa_get_os() {
  local LISA_UNAME
  LISA_UNAME="$(command uname -a)"
  local LISA_OS
  case "${LISA_UNAME}" in
    Linux\ *) LISA_OS=linux ;;
    Darwin\ *) LISA_OS=darwin ;;
  esac
  lisa_echo "${LISA_OS-}"
}

lisa_get_format() {
  local LISA_UNAME
  LISA_UNAME="$(command uname -a)"
  local LISA_FORMAT
  case "${LISA_UNAME}" in
    Linux\ *) LISA_FORMAT=.tar.xz ;;
    Darwin\ *) LISA_FORMAT=.tar.gz ;;
  esac
  lisa_echo "${LISA_FORMAT-}"
}

lisa_inst_requirements() {
  if lisa_has "apt"; then
    sudo apt install -y gpg zstd pv xz-utils
    if [ $? -ne 0 ]; then
      lisa_echo "Oops...something went wrong when installing required application(s)"
      exit 1
    fi
  elif lisa_has "yum"; then
    sudo yum install -y epel-release
    if [ $? -ne 0 ]; then
      lisa_echo "Oops...something went wrong when enabling EPEL repository"
      exit 1
    fi
    sudo yum install -y gpg zstd pv xz
    if [ $? -ne 0 ]; then
      lisa_echo "Oops...something went wrong when installing required application(s)"
      exit 1
    fi
  else
    lisa_echo "No apt or yum found in your system, please install one of them first."
    exit 1
  fi
}

lisa_is_gpgkey_imported() {
  gpg --list-keys |grep "6DE025312AE473230DA39108E9092D29A4E4A547" >/dev/null 2>&1
  return $?
}

lisa_verify_signature() {
  gpg --verify "$@" >/dev/null 2>&1
  return $?
}

lisa_do_install() {
  local INSTALL_DIR
  INSTALL_DIR="$(lisa_default_install_dir)"

  local LISA_OS
  LISA_OS="$(lisa_get_os)"

  local LISA_FORMAT
  LISA_FORMAT="$(lisa_get_format)"

  local LISA_SOURCE
  case "${DOWNLOAD_CHANNEL}" in
    beta) LISA_SOURCE="https://cdn.iflyos.cn/public/cskTools/lisa-zephyr-${LISA_OS}_x64-${DOWNLOAD_CHANNEL}${LISA_FORMAT}";;
    *) LISA_SOURCE="https://cdn.iflyos.cn/public/cskTools/lisa-zephyr-${LISA_OS}_x64${LISA_FORMAT}";;
  esac

  local LISA_BIN
  LISA_BIN="${INSTALL_DIR}/libexec"

  local LISA_RC
  LISA_RC="${HOME}/ifly/lisa/standalone/bash/.lisarc"

  local LISA_SDK_SOURCE
  LISA_SDK_SOURCE="https://cdn.iflyos.cn/public/lisa-zephyr-dist/lisa-zephyr-sdk-latest.tar.zst"

  local LISA_SDK_SIG
  LISA_SDK_SIG="https://cdn.iflyos.cn/public/lisa-zephyr-dist/lisa-zephyr-sdk-latest.tar.zst.sig"

  local LISA_WHL_SOURCE
  LISA_WHL_SOURCE="https://cdn.iflyos.cn/public/lisa-zephyr-dist/lisa-zephyr-whl-latest.tar.zst"

  local LISA_WHL_SIG
  LISA_WHL_SIG="https://cdn.iflyos.cn/public/lisa-zephyr-dist/lisa-zephyr-whl-latest.tar.zst.sig"

  if ! [ -d "${INSTALL_DIR}" ]; then
    command mkdir -p $INSTALL_DIR
  fi

  lisa_is_gpgkey_imported
  local GPGCHECK=$?

  lisa_echo "=> Installing zstd & gpg"
  lisa_inst_requirements

  echo $LISA_SOURCE
  lisa_echo "=> Downloading LISA"
  lisa_download --progress-bar "$LISA_SOURCE" -o "$INSTALL_DIR/lisa-zephyr-${LISA_OS}_x64${LISA_FORMAT}"
  lisa_echo "=> Downloading SDK package"
  lisa_download --progress-bar "$LISA_SDK_SOURCE" -o "$INSTALL_DIR/lisa-zephyr-sdk-latest.tar.zst"
  lisa_echo "=> Downloading required python wheel package"
  lisa_download --progress-bar "$LISA_WHL_SOURCE" -o "$INSTALL_DIR/lisa-zephyr-whl-latest.tar.zst"

  if [ $GPGCHECK -eq 0 ]; then
    lisa_echo "=> Checking integrity of resource package"
    lisa_download -s "$LISA_SDK_SIG" -o "$INSTALL_DIR/lisa-zephyr-sdk-latest.tar.zst.sig"
    lisa_download -s "$LISA_WHL_SIG" -o "$INSTALL_DIR/lisa-zephyr-whl-latest.tar.zst.sig"
    lisa_verify_signature "$INSTALL_DIR/lisa-zephyr-sdk-latest.tar.zst.sig" "$INSTALL_DIR/lisa-zephyr-sdk-latest.tar.zst"
    local SDK_SIG_OK=$?
    lisa_verify_signature "$INSTALL_DIR/lisa-zephyr-whl-latest.tar.zst.sig" "$INSTALL_DIR/lisa-zephyr-whl-latest.tar.zst"
    local WHL_SIG_OK=$?
    if [ $SDK_SIG_OK -ne 0 ] || [ $WHL_SIG_OK -ne 0 ]; then
      lisa_echo "Resource packages integrity check failed!"
      exit 1
    fi
  fi

  lisa_echo "=> Extracting LISA to '$INSTALL_DIR'"
  lisa_tar "$INSTALL_DIR/lisa-zephyr-${LISA_OS}_x64${LISA_FORMAT}" "$INSTALL_DIR"
  lisa_echo "=> Extracting SDK package"
  mkdir -p "$INSTALL_DIR/../csk-sdk"
  lisa_unzstd "$INSTALL_DIR/lisa-zephyr-sdk-latest.tar.zst" "$INSTALL_DIR/../csk-sdk"
  lisa_echo "=> Extracting WHL package"
  mkdir -p "$INSTALL_DIR/../lisa-zephyr/whl"
  lisa_unzstd "$INSTALL_DIR/lisa-zephyr-whl-latest.tar.zst" "$INSTALL_DIR/../lisa-zephyr/whl"

  lisa_echo "=> Preparing workspace specially for you"
  lisa_shell_command_link
  export LISA_HOME=$INSTALL_DIR/../
  export LISA_PREFIX=$INSTALL_DIR
  $INSTALL_DIR/libexec/lisa zep install
  echo "{\"env\":\"csk6\"}" |tee $LISA_HOME/lisa-zephyr/config.json >/dev/null 2>&1
  $INSTALL_DIR/libexec/lisa zep use-sdk "$INSTALL_DIR/../csk-sdk/zephyr"
  sudo sed -i '/^LISA_HOME=/d' /etc/environment
  sudo sed -i '/^LISA_PREFIX=/d' /etc/environment
  echo "LISA_HOME=\"${LISA_HOME}\"" |sudo tee -a /etc/environment >/dev/null 2>&1
  echo "LISA_PREFIX=\"${LISA_PREFIX}\"" |sudo tee -a /etc/environment >/dev/null 2>&1
  source /etc/environment
  
  lisa_echo "=> Success! try run command 'lisa info zephyr'"
}

DOWNLOAD_CHANNEL="stable"
if [ $# -eq 1 ]; then
  case "$1" in
    beta | stable) DOWNLOAD_CHANNEL=$1 ;;
    *) DOWNLOAD_CHANNEL="stable" ;;
  esac
fi

lisa_do_install

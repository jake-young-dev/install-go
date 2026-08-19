#!/bin/bash

##
# installs commands using "go install" if any are set in the commands input
##
function installCommands {
  # "." is used as a default, meaning no commands were added
  if [[ "$GO_INSTALL_COMMANDS" != "." ]]; then 
    #splitting into an array allows for multiple cmds using |
    INPUT_ARR=( $GO_INSTALL_COMMANDS )
    for i in "${INPUT_ARR[@]}"; do
        echo "Installing go command from ${i}"
        if go install ${i}; then
          echo "Installed ${i}"
        else
          echo "FATAL: Unable to install ${i} with go"
          exit 1
        fi
    done
  fi
}

##
# fix version ensures we have a patch level version on our go version string from the go.mod file
##
function fixVersion {
  DL_VSPL=( $DL_VERSION_RAW )
  DL_VERSION="${DL_VSPL[1]}"

  # -P uses perl syntax
  DL_VERSION_PAD_CHECK="$(grep "^go [0-9]+.[0-9]+.[0-9]+" go.mod -P)"
  if [[ -z "$DL_VERSION_PAD_CHECK" ]]; then
    DL_VERSION="$DL_VERSION"".0"
    echo "Fixing version number to ${DL_VERSION}"
  fi
}

#start

echo "Parsing go version"
#check install version field first
if [[ -z "$GO_INSTALL_VERSION" ]]; then
  echo "No version input found, checking go.mod files"
  # -P uses perl syntax
  DL_VERSION_RAW="$(grep "^go [0-9]+.[0-9]+" go.mod -P)"
  if [[ -z "$DL_VERSION_RAW" ]]; then
      echo "FATAL: No Go version found, set version input if no go.mod file is present"
      exit 1
  else
    fixVersion
  fi
else
  echo "Version input found"
  DL_VERSION=$GO_INSTALL_VERSION
fi

echo "Found go version: ${DL_VERSION}"

DL_ARCH=$GO_INSTALL_ARCH
echo "Checking if go is already installed"
#check if go is already present before starting install process and delete files if purge input is set
# -v writes string that indicates command or command path to output, prevents command not found error if go isn't installed
GO_CHECK=$(command -v go)
if [[ "$GO_CHECK" ]]; then
  #if the version of go matches the requested version, skip
  GVC=$(go version)
  if [[ "$GVC" == "go version go${DL_VERSION} linux/${DL_ARCH}" ]]; then
    echo "Go ${DL_VERSION} already installed, skipping go setup"
    installCommands
    exit 0
  fi
  #if the purge flag is not set and version does not match, exit
  if [[ "$GO_INSTALL_PURGE" != "yes" ]]; then
    echo "FATAL: The wrong version of Go is already installed, set purge to 'yes' if you wish to update installed version"
    exit 1
  else
    echo "Removing old go versions"
    sudo rm -r /usr/bin/go 
    sudo rm -r /usr/bin/gofmt
  fi
fi

echo "Ready to install"
echo "Downloading go files for ${DL_VERSION}/${DL_ARCH}"
PATH_FOR_FILES=/usr/local/go
PATH_FOR_TAR=/usr/local
#creating our files with proper file perms
sudo mkdir -v -m 0777 -p "$PATH_FOR_FILES"

#wget
# -q quiets output
# O- outputs file data to pipe instead of file
#tar
# -z use gzip
# -x extract files
# -f extract from "file"
# - extract from pipe as a file
# -C change to GOPATH directory
if sudo wget -qO- "https://golang.org/dl/go${DL_VERSION}.linux-${DL_ARCH}.tar.gz" | sudo tar -zxf - -C "$PATH_FOR_TAR"; then
  echo "Files downloaded successfully"
else
  echo "FATAL: Unable to download and extract files"
  exit 1
fi

echo "Adding go to path"
export PATH=$PATH:$PATH_FOR_FILES/bin
echo "$PATH_FOR_FILES/bin" >> "$GITHUB_PATH" #set action path too

#grab go version to test the go command
GLOBAL_GO_CMD_VERSION=$(go version)
if [[ -z "$GLOBAL_GO_CMD_VERSION" ]]; then
  echo "FATAL: Failed to register go command"
  exit 1
else
  echo "Go command setup for ${GLOBAL_GO_CMD_VERSION}"
fi

#adding GOPATH to path to support go commands
echo "Setting path to allow for commands installed by go"
GP=$(go env GOPATH)/bin
export PATH=$PATH:$GP
echo "$GP" >> "$GITHUB_PATH"

installCommands

#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

# Void - disable icon copying, we already handled icons
# if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
#   cp -rp src/insider/* vscode/
# else
#   cp -rp src/stable/* vscode/
# fi

# Void - keep our license...
# cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "ORG_NAME=\"${ORG_NAME}\""

echo "Applying patches at ../patches/*.patch..." # Void comment
for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  echo "Applying insider patches..." # Void comment
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  echo "Applying OS patches (${OS_NAME})..." # Void comment
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

echo "Applying user patches..." # Void comment
for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
else
  if [[ "${CI_BUILD}" != "no" ]]; then
    clang++ --version
  fi
fi

if [[ -n "${GITHUB_TOKEN}" ]]; then
  export GH_TOKEN="${GITHUB_TOKEN}"
  export npm_config_github_token="${GITHUB_TOKEN}"
fi

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  if [[ "${CI_BUILD}" != "no" && "${OS_NAME}" == "osx" ]]; then
    CXX=clang++ npm ci && break
  else
    npm ci && break
  fi

  if [[ $i == 5 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://github.com/pedro2rafael4561-boop/DarkOS"
# setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item"}'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/pedro2rafael4561-boop/DarkOS/blob/main/LICENSE.txt"
# setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
# setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/pedro2rafael4561-boop/DarkOS/issues/new"
setpath "product" "requestFeatureUrl" "https://github.com/pedro2rafael4561-boop/DarkOS/issues/new"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://x.com/darkoseditor"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/pedro2rafael4561-boop/DarkOS-versions/refs/heads/main"
  setpath "product" "downloadUrl" "https://github.com/pedro2rafael4561-boop/DarkOS-binaries/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "DarkOS - Insiders"
  setpath "product" "nameLong" "DarkOS - Insiders"
  setpath "product" "applicationName" "darkos-insiders"
  setpath "product" "dataFolderName" ".darkos-insiders"
  setpath "product" "linuxIconName" "darkos-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "darkos-insiders"
  setpath "product" "serverApplicationName" "darkos-server-insiders"
  setpath "product" "serverDataFolderName" ".darkos-server-insiders"
  setpath "product" "darwinBundleIdentifier" "ai.darkos.DarkOSInsiders"
  setpath "product" "win32AppUserModelId" "Void.DarkOSInsiders"
  setpath "product" "win32DirName" "DarkOS Insiders"
  setpath "product" "win32MutexName" "DarkOSInsiders"
  setpath "product" "win32NameVersion" "DarkOS Insiders"
  setpath "product" "win32RegValueName" "DarkOSInsiders"
  setpath "product" "win32ShellNameShort" "DarkOS Insiders"
  setpath "product" "win32AppId" "{{5893CE20-77AA-4856-A655-ECE65CBCF1C7}"
  setpath "product" "win32x64AppId" "{{7A261980-5847-44B6-B554-31DF0F5CDFC9}"
  setpath "product" "win32arm64AppId" "{{EE4FF7AA-A874-419D-BAE0-168C9DBCE211}"
  setpath "product" "win32UserAppId" "{{FA3AE0C7-888E-45DA-AB58-B8E33DE0CB2E}"
  setpath "product" "win32x64UserAppId" "{{5B1813E3-1D97-4E00-AF59-C59A39CF066A}"
  setpath "product" "win32arm64UserAppId" "{{C2FA90D8-B265-41B1-B909-3BAEB21CAA9D}"
else
  setpath "product" "nameShort" "DarkOS"
  setpath "product" "nameLong" "DarkOS"
  setpath "product" "applicationName" "DarkOS"
  setpath "product" "linuxIconName" "DarkOS"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "DarkOS"
  setpath "product" "serverApplicationName" "darkos-server"
  setpath "product" "serverDataFolderName" ".darkos-server"
  setpath "product" "darwinBundleIdentifier" "com.darkos"
  setpath "product" "win32AppUserModelId" "DarkOS.DarkOS"
  setpath "product" "win32DirName" "DarkOS"
  setpath "product" "win32MutexName" "DarkOS"
  setpath "product" "win32NameVersion" "DarkOS"
  setpath "product" "win32RegValueName" "DarkOS"
  setpath "product" "win32ShellNameShort" "DarkOS"
  # Void - already set in product
  # setpath "product" "win32AppId" "{{88DA3577-054F-4CA1-8122-7D820494CFFB}"
  # setpath "product" "win32x64AppId" "{{9D394D01-1728-45A7-B997-A6C82C5452C3}"
  # setpath "product" "win32arm64AppId" "{{0668DD58-2BDE-4101-8CDA-40252DF8875D}"
  # setpath "product" "win32UserAppId" "{{0FD05EB4-651E-4E78-A062-515204B47A3A}"
  # setpath "product" "win32x64UserAppId" "{{8BED5DC1-6C55-46E6-9FE6-18F7E6F7C7F1}"
  # setpath "product" "win32arm64UserAppId" "{{F6C87466-BC82-4A8F-B0FF-18CA366BA4D8}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "${RELEASE_VERSION%-insider}"

replace 's|Microsoft Corporation|DarkOS|' package.json

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "DarkOS - Insiders"
  setpath "resources/server/manifest" "short_name" "DarkOS - Insiders"
else
  setpath "resources/server/manifest" "name" "DarkOS"
  setpath "resources/server/manifest" "short_name" "DarkOS"
fi

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "DarkOS - Insiders"
  setpath "resources/server/manifest" "short_name" "DarkOS - Insiders"
else
  # Void already has this
  setpath "resources/server/manifest" "name" "DarkOS"
  setpath "resources/server/manifest" "short_name" "DarkOS"
fi

# announcements
# replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|DarkOS|' build/lib/electron.js
replace 's|Microsoft Corporation|DarkOS|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 Void|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 Void|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to void
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/darkos-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/void/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|DarkOS|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|DarkOS Team <pedro2rafael4561@gmail.com>|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|DarkOS|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|DarkOS Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|DarkOS Team <pedro2rafael4561@gmail.com>|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|DarkOS|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://github.com/pedro2rafael4561-boop/DarkOS|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|DarkOS|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://github.com/pedro2rafael4561-boop/DarkOS|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|DarkOS|' build/win32/code.iss
fi

cd ..

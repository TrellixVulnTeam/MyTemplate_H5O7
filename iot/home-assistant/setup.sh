## HASS Setup Guide + Patch for Windows
set -euo pipefail


## Make sure you are in a [venv]. [conda] does not seem to work.
[ -z "${VIRTUAL_ENV}" ] && echo "Not in a python [venv]" && exit 1
echo "python: $(which python)"
echo "pip   : $(which pip)"
read -n 1 -r -p 'Looking good?'


## If running under Windows
if [[ "$(uname -a)" = *"MINGW64_NT"* ]]; then
  echo Make sure you have these installed:
  printf '\tMS C++ 14.0+ Build Tools\n\tWin 10+ SDK\n\tWinPcap/Npcap (https://npcap.com/#download)'
  read -n 1 -r -p '(press ENTER ...)'
fi


## Make sure these commands are ready
command -v ffmpeg
command -v unzip


## Install
pip install -U --pre wheel homeassistant sqlalchemy fnvhash tzdata


## Patches
if [[ "$(uname -a)" = *"MINGW64_NT"* ]]; then
  SITE_PKGS_DIR=$(pip show homeassistant | fgrep Location | awk '{print $2}')
  ## Using [python] below since Bash does not recognize Windows paths

  ## Patch 1 - homeassistant/util/file.py
  python <<< "with open(R'$SITE_PKGS_DIR/homeassistant/util/file.py','r+b') as f:d=f.read().replace(b'os.fchmod(fdesc.fileno(), 0o644)',b'os.fchmod(fdesc.fileno(),0o644) if os.name != \'nt\' else os.chmod(fdesc.name, 0o644)');f.seek(0);f.truncate();f.write(d)"

  ## Patch 2 - homeassistant/runner.py
  python <<< "with open(R'$SITE_PKGS_DIR/homeassistant/runner.py','r+b') as f:d=f.read().replace(b'return await hass.async_run()',b'import os;return await hass.async_run(attach_signals=os.name!=\'nt\')');f.seek(0);f.truncate();f.write(d)"

  ## Patch 3 - homeassistant/components/onboarding/views.py
  python <<< "with open(R'$SITE_PKGS_DIR/homeassistant/components/onboarding/views.py','r+b') as f:d=f.read().replace(b'onboard_integrations = ["\""met"\"", "\""radio_browser"\""]',b"\""import os;onboard_integrations=['met','radio_browser'] if os.name!='nt' else ['met']"\"");f.seek(0);f.truncate();f.write(d)"
  ## Explain: [aiodns], a dependency of [radio_browser], is currently not compatible with Windows. See https://github.com/saghul/aiodns/issues/86
fi


## Recommended: Get [HACS] from [https://github.com/hacs/get]


## Run
hass --ignore-os-check --open-ui


## Add `hacs` as new integration

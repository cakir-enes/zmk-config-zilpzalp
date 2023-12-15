up:
  #!/usr/bin/env bash
  function getlastrun {
    gh run list --workflow build.yml -L 1 --json "conclusion,databaseId,displayTitle" -q '.[0]'
  }

  # wait until status is not empty
  gum spin --spinner dot --title "Wait until build is finished..." -- bash -c 'while [ -z $status ]; do sleep 1; status=$(gh run list --workflow build.yml -L 1 --json "conclusion,databaseId,displayTitle" -q ".[0].conclusion"); done'

  lastrun=$(getlastrun)
  status=$(echo $lastrun | jq '.conclusion')
  id=$(echo $lastrun | jq -r '.databaseId')
  title=$(echo $lastrun | jq -r '.displayTitle')

  echo "Build finished with status: $status"
  if [ "$status" != '"success"' ]; then
    echo "Build failed, exiting..."
    exit 1
  fi

  gum spin --spinner dot --title "Downloading artifact..." -- gh run download $id -n firmware -D ./firmware
  echo "Downloaded artifact: $title"

  gum spin --spinner dot --title "Wait until zilpzalp mounts..." -- bash -c 'while [ ! -d /Volumes/RPI-RP2 ]; do sleep 1; done'
  echo "Zilpzalp mounted!"

  cp -X ./firmware/zilpzalp-seeeduino_xiao_rp2040-zmk.uf2 /Volumes/RPI-RP2
  rm -rf ./firmware
  echo 'Done!'

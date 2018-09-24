#!/bin/bash

provider=${1:-"aws"}

if [ "${provider}" == "aws" ]; then
		echo "#!/usr/bin/env bash
sudo yum install -y cpuid
output=\`cpuid -1 | grep \"simple synth\"\`
case \"\$output\" in
  *Haswell*)
    echo \"Haswell\"
    exit
    ;;
  *Broadwell*)
    echo \"Broadwell\"
    exit
    ;;
  *Skylake*)
    echo \"Skylake\"
    exit
    ;;
esac
echo \"Could not determine CPU Type\"" > /nfs/getCpuIdentity.sh

elif [ "${provider}" == "gcp" ]; then
	echo "#!/usr/bin/env bash
sudo yum install -y cpuid
output=\`cpuid -1 | grep \"simple synth\"\`
case \"\$output\" in
  *Haswell*)
    echo \"Haswell\"
    exit
    ;;
  *Broadwell*)
    echo \"Broadwell\"
    exit
    ;;
  *Skylake*)
    echo \"Skylake\"
    exit
    ;;
esac
echo \"Could not determine CPU Type\"" > /nfs/getCpuIdentity.sh
fi

sudo chmod 777 /nfs/getCpuIdentity.sh
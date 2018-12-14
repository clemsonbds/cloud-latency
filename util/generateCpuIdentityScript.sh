#!/bin/bash

provider=${1:-"aws"}
target="/nfs/resources/getCpuIdentity.sh"

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
echo \"Could not determine CPU Type\"" > ${target}

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
echo \"Could not determine CPU Type\"" > ${target}
fi

sudo chmod 777 ${target}

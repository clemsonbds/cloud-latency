#! /usr/bin/env bash

provider=${1:-"aws"}

# Write out the script to identify the CPU Architecture of the machine
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
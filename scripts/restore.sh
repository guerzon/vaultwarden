#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

restore_path="/bitwarden/restore"
data_path="/bitwarden/data"
pod_name="restore"
image="ttionya/vaultwarden-backup:1.22.0"


usage ()
{
    echo "Usage: ${0##*/} --archive some-backup.zip --release vaultwarden-helm-release --storage-class storage-class [--chart vaultvarden-chart] [--capacity pv-size] [--namespace kubernetes-namespace] [--context kubernetes-context]"
    echo "Example: ${0##*/} --archive \"/tmp/20221011-19-05-01.zip\" --release main --capacity 10Gi --storage-class \"local-path\""
    echo "Capacity defaults to \"5Gi\""
    exit 1
}


if ! OPTS=$(getopt --options "h" --longoptions archive:,release:,capacity:,chart:,storage-class:,namespace:,context:,help --name 'parse-options' -- "$@"); then
  echo "Failed parsing options." >&2
  exit 1
fi


eval set -- "${OPTS}"

while true; do
  case "$1" in
  --archive)
    archive="$2"
    shift 2
    ;;
  --release)
    release="$2"
    shift 2
    ;;
  --chart)
    chart="$2"
    shift 2
    ;;
  --capacity)
    capacity="$2"
    shift 2
    ;;
  --storage-class)
    storage_class="$2"
    shift 2
    ;;
  --namespace)
    ns="$2"
    shift 2
    ;;
  --context)
    context="$2"
    shift 2
    ;;
  -h | --help ) usage;  ;;
  --)
    shift
    break
    ;;
  *) break ;;
  esac
done

# Let's presume kubectl is installed
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required.  Aborting."; exit 1; }

if [ -z "${archive+set}" ]; then
  echo "Archive file is not set"
  usage
fi

if [ ! -f "${archive}" ]; then
  echo "Archive file does not exist"
  usage
fi

if [ -z "${release+set}" ]; then
  echo "Vaultwarden helm release name is not provided"
  usage
fi

if [ -z "${storage_class+set}" ]; then
  echo "Storage class for PVC is not provided"
  usage
fi

if [ -z "${chart+set}" ]; then
  chart="vaultwarden"
fi

if [ -z "${capacity+set}" ]; then
  capacity="5Gi"
fi

kubeconf=$(kubectl config view -o json)

if [ -z "${context+set}" ]; then
  context=$(echo "${kubeconf}" | jq -r '.["current-context"]')
  if [ -z "${context}" ]; then
    echo "Cannot get current context"
    exit 1
  fi
fi

if [ -z "${ns+set}" ]; then
  ns=$(echo "${kubeconf}" | jq -r --arg ctx "${context}" '.contexts[] | select(.name==$ctx) | .context.namespace')
  if [ -z "${ns}" ]; then
    echo "Cannot get current namespace"
    exit 1
  fi
fi


echo "Kubernetes context: [${context}], namespace: [${ns}]"

if ! kubectl get namespace "${ns}" > /dev/null; then
  echo "Namespace \"${ns}\" does not exist, creating it"
  kubectl create namespace "${ns}"
fi

#{{- if contains $name .Release.Name -}}
#{{- .Release.Name | trunc 20 | trimSuffix "-" -}}
#{{- else -}}
#{{- printf "%s-%s" .Release.Name $name | trunc 20 | trimSuffix "-" -}}
#{{- end -}}

# bit simplified condition
if [[ "${release}" =~ .*"${chart}".* ]]; then
  # release name contained in chart name
    pvc_name="vaultwarden-data-${chart}-0"
else
  # release name not contained in chart name
  pvc_name="vaultwarden-data-${release}-${chart}-0"
fi


echo "Creating PVC: \"${pvc_name}\" ..."

pvc=$(cat <<"EOF"
{
  "apiVersion": "v1",
  "kind": "PersistentVolumeClaim",
  "metadata": {
    "name": $claim
  },
  "spec": {
    "storageClassName": $class,
    "accessModes": ["ReadWriteOnce"],
    "resources": {
      "requests": {
        "storage": $capacity
        }
    }
  }
}
EOF
)

jq -n --arg claim "${pvc_name}" --arg capacity "${capacity}" --arg class "${storage_class}" "${pvc}" | kubectl apply --context "${context}" --namespace "${ns}" -f -

echo "Creating restore pod ..."

pod_template=$(cat <<"EOF"
{
  "apiVersion": "v1",
  "spec": {
    "containers": [{
      "name": $name,
      "image": $image,
      "command": ["sh", "-c", "mkdir "+$restore_path+" && sleep infinite"],
      "volumeMounts" : [{
        "name": "data",
        "mountPath": $data_path
      }]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {
        "claimName": $claim
      }
    }]
  }
}
EOF
)

overrides=$(jq -n --arg name "${pod_name}" --arg image "${image}" --arg restore_path "${restore_path}" --arg claim "${pvc_name}" --arg data_path "${data_path}" "${pod_template}")
kubectl run "${pod_name}" --context "${context}" --namespace "${ns}" --image="${image}" --restart=Never  --overrides="${overrides}"
kubectl wait --context "${context}" --namespace "${ns}" --for=condition=Ready pod/"${pod_name}"

echo "Copying archive to restore pod ..."
kubectl cp --context "${context}" --namespace "${ns}" "${archive}" "${pod_name}:${restore_path}"

echo "Performing the restore, if you have a zip password on archive, it will be prompted during the restore ..."

archive_name=$(basename "${archive}")

echo "Sleeping 5 seconds to make sure pod is ready"

sleep 5

kubectl exec --context "${context}" --namespace "${ns}" -ti "${pod_name}" -- sh -c "/app/entrypoint.sh restore --zip-file "${restore_path}/${archive_name}" --force-restore && chown -R backuptool:backuptool \"${data_path}\""

echo "Data is restored, deleting the pod. It can take up to 30 seconds ..."
kubectl delete pod --context "${context}" --namespace "${ns}" "${pod_name}"

echo "Done !"

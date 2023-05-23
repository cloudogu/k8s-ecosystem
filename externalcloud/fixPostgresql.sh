#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

postgresPod="$(kubectl -n ecosystem get pod | grep postgres | awk '{print $1}')"
kubectl exec -n ecosystem -it "${postgresPod}" --container postgresql -- sed -i 's/32  password/16  password/g' /var/lib/postgresql/pg_hba.conf
kubectl exec -n ecosystem -it "${postgresPod}" --container postgresql -- su postgres -c "pg_ctl reload"
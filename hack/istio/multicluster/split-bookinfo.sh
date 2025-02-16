#!/bin/bash

##############################################################################
# split-bookinfo.sh
#
# Installs Bookinfo, splitting up its components across the two clusters.
#
##############################################################################

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
source ${SCRIPT_DIR}/env.sh $*

if [ "${BOOKINFO_ENABLED}" != "true" ]; then
  echo "Will not install bookinfo demo"
  return 0
else
  echo "Installing bookinfo demo in namespace [${BOOKINFO_NAMESPACE}] across the two clusters"
fi

install_bookinfo() {
  local profile="${1}"
  local traffic_gen_enabled="${2}"
  local traffic_gen_arg=""
  if [ "${traffic_gen_enabled}" == "true" ]; then
    traffic_gen_arg="-tg"
  fi

  "${INSTALL_BOOKINFO_SCRIPT}"             \
    --client-exe "${CLIENT_EXE}"           \
    --istio-dir "${ISTIO_DIR}"             \
    --istio-namespace "${ISTIO_NAMESPACE}" \
    --namespace "${BOOKINFO_NAMESPACE}"    \
    --minikube-profile "${profile}"        \
    ${traffic_gen_arg}

  if [ "$?" != "0" ]; then
    echo "Failed to install bookinfo"
    exit 1
  fi
}

# Find the hack script to be used to install bookinfo
INSTALL_BOOKINFO_SCRIPT=${SCRIPT_DIR}/../install-bookinfo-demo.sh
if [  -x "${INSTALL_BOOKINFO_SCRIPT}" ]; then
  echo "Bookinfo install script: ${INSTALL_BOOKINFO_SCRIPT}"
else
  echo "Cannot find the Bookinfo install script at: ${INSTALL_BOOKINFO_SCRIPT}"
  exit 1
fi

echo "==== INSTALL BOOKINFO ON CLUSTER #1 [${CLUSTER1_NAME}] - ${CLUSTER1_CONTEXT}"
switch_cluster "${CLUSTER1_CONTEXT}" "${CLUSTER1_USER}" "${CLUSTER1_PASS}"
install_bookinfo "${CLUSTER1_CONTEXT}" "true"
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} reviews-v2 --replicas=0
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} reviews-v3 --replicas=0
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} ratings-v1 --replicas=0

echo "==== CREATING TRAFFIC SHIFTING RULES FOR REVIEWS SERVICE"
# This is done to enforce traffic to all reviews workloads (there were ocassions where traffic was not being routed to v3 or v2)
cat <<EOF | ${CLIENT_EXE} apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  namespace: ${BOOKINFO_NAMESPACE}
spec:
  hosts:
    - reviews.bookinfo.svc.cluster.local
  http:
    - route:
        - destination:
            host: reviews.bookinfo.svc.cluster.local
            subset: v1
          weight: 33
        - destination:
            host: reviews.bookinfo.svc.cluster.local
            subset: v2
          weight: 33
        - destination:
            host: reviews.bookinfo.svc.cluster.local
            subset: v3
          weight: 34
EOF
cat <<EOF | ${CLIENT_EXE} apply -f -
kind: DestinationRule
apiVersion: networking.istio.io/v1beta1
metadata:
  name: reviews
  namespace: ${BOOKINFO_NAMESPACE}
spec:
  host: reviews.bookinfo.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
    - name: v3
      labels:
        version: v3
EOF

if [ "${IS_OPENSHIFT}" == "true" ]; then
  INGRESS_HOST=$(${CLIENT_EXE} -n ${ISTIO_NAMESPACE} get route istio-ingressgateway -o jsonpath='{.spec.host}')
else
  INGRESS_HOST=$(${CLIENT_EXE} -n ${ISTIO_NAMESPACE} get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

echo "==== INSTALL BOOKINFO ON CLUSTER #2 [${CLUSTER2_NAME}] - ${CLUSTER2_CONTEXT}"
switch_cluster "${CLUSTER2_CONTEXT}" "${CLUSTER2_USER}" "${CLUSTER2_PASS}"
install_bookinfo "${CLUSTER2_CONTEXT}" "false"
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} productpage-v1 --replicas=0
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} details-v1 --replicas=0
${CLIENT_EXE} scale deploy -n ${BOOKINFO_NAMESPACE} reviews-v1 --replicas=0

echo "Bookinfo application will be available soon at http://${INGRESS_HOST}/productpage"


#!/bin/bash

oc login -u kubeadmin -p "$(cat /root/auth/kubeadmin-password)" https://api.$(hostname | cut -f1 -d'.' | rev | cut -f1 -d'-' --complement | rev).cp.fyre.ibm.com:6443 --insecure-skip-tls-verify=true

# Install ceph
rm -rf rook
echo "Doing clone of rook"
git clone https://github.com/rook/rook.git -b v1.1.7
echo "Doing common.yaml"
oc create -f rook/cluster/examples/kubernetes/ceph/common.yaml
echo "common.yaml exit $?"
echo "Doing operator-openshift.yaml"
oc create -f rook/cluster/examples/kubernetes/ceph/operator-openshift.yaml
echo "operator-openshift.yaml exit $?"
echo "Doing sed of useAllDevices false"
sed -i 's/useAllDevices: true/useAllDevices: false/g' rook/cluster/examples/kubernetes/ceph/cluster.yaml
echo "Exit from useAllDevice $?"
echo "Doing sed of deviceFilter"
sed -i "s/deviceFilter:/deviceFilter: vdb/g" rook/cluster/examples/kubernetes/ceph/cluster.yaml
echo "Exit from deviceFilter $?"
echo "Doing cluster.yaml create"
oc create -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
echo "Exit from cluster.yaml $?"
echo "Doing filessystem-test.yaml"
oc create -f rook/cluster/examples/kubernetes/ceph/filesystem-test.yaml
echo "Exit from filesystem-test.yaml $?"
oc create -f rook/cluster/examples/kubernetes/ceph/csi/cephfs/storageclass.yaml
oc patch storageclass csi-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
oc create -f rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass-test.yaml
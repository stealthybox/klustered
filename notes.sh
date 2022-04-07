# create uwu-admin user config
k get cm -n kube-system kubeadm-config -o go-template="{{ .data.ClusterConfiguration }}" > kubeadm.config.yaml
kubeadm kubeconfig user --client-name uwu-admin --config kubeadm.config.yaml > uwu-admin.kubeconfig.yaml

# changed names in kubernetes static pods -- harmless

# install local path provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml
k annotate storageclasses.storage.k8s.io local-path storageclass.kubernetes.io/is-default-class=true

# install vcluster
curl -s -L "https://github.com/loft-sh/vcluster/releases/latest" | sed -nE 's!.*"([^"]*vcluster-linux-amd64)".*!https://github.com\1!p' | xargs -n 1 curl -L -o vcluster && chmod +x vcluster;
sudo mv vcluster /usr/local/bin;

cat <<EOF > tce-k8s-values.yaml
api:
  image: projects.registry.vmware.com/tkg/kube-apiserver:v1.22.5_vmware.1
etcd:
  image: projects.registry.vmware.com/tkg/etcd:v3.5.0_vmware.7
controller:
  image: projects.registry.vmware.com/tkg/kube-controller-manager:v1.22.5_vmware.1
EOF

vcluster create -n vcluster tanzu-community-edition --distro k8s --extra-values tce-k8s-values.yaml

vcluster connect -n vcluster tanzu-community-edition -- kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml

rm tce-k8s-values.yaml

# bootstrap repo
vcluster connect -n vcluster tanzu-community-edition -- kubectl create secret generic creds --from-file /etc/kubernetes/admin.conf
vcluster connect -n vcluster tanzu-community-edition -- kubectl apply -f vcluster-app.yaml

# replace admin.conf
mv uwu-admin.kubeconfig.yaml /etc/kubernetes/admin.conf

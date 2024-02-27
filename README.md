# OpenShift Agent Based Installer Helper

This repo holds some utilities to easily leverage the OpenShift Agent Based Installer.  Supports bare metal, vSphere, and platform=none deployments in SNO/3 Node/HA configurations.

## Prerequisites

- A RHEL system to work from
- OpenShift CLI Tools - run `./download-openshift-cli.sh` then `sudo cp ./bin/* /usr/local/bin/`
- NMState CLI `dnf install nmstate`
- Ansible Core `dnf install ansible-core`
- Ansible Collections for the automation: `ansible-galaxy install -r openshift-agent-install/collections/requirements.yml`
- Red Hat OpenShift Pull Secret saved to a file: https://console.redhat.com/openshift/downloads#tool-pull-secret
- Any other Pull Secret for a disconnected registry, joined with the Red Hat OpenShift Pull Secret

## Usage - Declarative

In the `examples` directory you'll find sample cluster configuration variables.  By defining the cluster in its own folder with the `cluster.yml` and `nodes.yml` files, you can easily template and generate the ABI ISO in one shot with:

```bash
./hack/create-iso.sh $FOLDER_NAME
```

This script will take those defined files, generate the templates with Ansible, create the ISO, and present next step instructions.

Alternatively, you can perform those steps manually with the instructions below.

---

## Usage - Manual

### 1. Templating Agent Based Installer Manifests

You can quickly and easily template the ABI manifests with the provided `create-manifests.yml` Ansible Playbook.

```bash=
# Make sure you're in the `playbooks` directory
cd playbooks/

# Execute the automation with your custom cluster configuration set in a YAML file
ansible-playbook -e "@your-cluster-vars.yml" create-manifests.yml
```

### 2. Creating the Agent Installer ISO

After running the automation to generate the manifests, you can create the ISO with the following:

```bash=
# Create the ISO
openshift-install agent create image --dir ./generated_manifests/<cluster_name>

# Watch the Bootstrap process
openshift-install agent wait-for bootstrap-complete --dir ./generated_manifests/<cluster_name>

# Watch the installation process
openshift-install agent wait-for install-complete --dir ./generated_manifests/<cluster_name>
```

You'll need to provide it some variables such as the following:

#### General Configuration Variables

```yaml=
# pull_secret path is the path to the pull-secret for the cluster
pull_secret_path: ~/ocp-install-pull-secret.json

# ssh_public_key_path is the path to the SSH public key to use for the cluster
# if this is not set then a new key pair will be generated
# ssh_public_key_path: ~/.ssh/id_rsa.pub

# Cluster metadata
base_domain: d70.kemo.labs
cluster_name: suki-sno

# platform_type is the type of platform to use for the cluster (baremetal, vsphere, none)
# must be none for SNO
platform_type: none

# VIPs - set as a list in case this is a dual-stack cluster
api_vips:
  - 192.168.70.46

app_vips:
  - 192.168.70.46

# Optional NTP Servers
ntp_servers:
  - deep-thought.kemo.labs

# Optional DNS Server definitions
dns_servers:
  - 192.168.42.9
  - 192.168.42.10
dns_search_domains:
  - kemo.labs
  - kemo.network

# cluster_network_cidr is the overall CIDR space for the Pods in the cluster
cluster_network_cidr: 10.128.0.0/14
# cluster_network_host_prefix is the number of bits in the cluster_network_cidr that are for each node
cluster_network_host_prefix: 23

# service_network_cidrs is the CIDR space for the Services in the cluster (ClusterIP/NodePort/LoadBalancer)
service_network_cidrs:
  - 172.30.0.0/16

# machine_network_cidr is the CIDR space for the Machines in the cluster
machine_network_cidrs:
  - 192.168.70.0/23

# networkType is the type of network to use for the cluster (OpenShiftSDN, OVNKubernetes)
network_type: OVNKubernetes

# rendezvous_ip is the IP address of the node that will be used for the bootstrap node
rendezvous_ip: 192.168.70.46

# Optional Disconnected Registry Mirror configuration
disconnected_registries:
  # Must have a direct reference to the openshift-release-dev/ocp-release and openshift-release-dev/ocp-v4.0-art-dev paths
  - target: disconn-harbor.d70.kemo.labs/quay-ptc/openshift-release-dev/ocp-release
    source: quay.io/openshift-release-dev/ocp-release
  - target: disconn-harbor.d70.kemo.labs/quay-ptc/openshift-release-dev/ocp-v4.0-art-dev
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

  - target: disconn-harbor.d70.kemo.labs/quay-ptc
    source: quay.io
  - target: disconn-harbor.d70.kemo.labs/registry-redhat-io-ptc
    source: registry.redhat.io
  - target: disconn-harbor.d70.kemo.labs/registry-connect-redhat-com-ptc
    source: registry.connect.redhat.com

# Optional Outbound Proxy Configuration
# proxy:
#   http_proxy: http://192.168.42.31:3128
#   https_proxy: http://192.168.42.31:3128
#   no_proxy:
#     - .svc.cluster.local
#     - 192.168.0.0/16
#     - .kemo.network
#     - .kemo.labs

# Optional Additional CA Root Trust Bundle
additional_trust_bundle_policy: Always
additional_trust_bundle: |
  -----BEGIN CERTIFICATE-----
  MIIG3TCCBMWgAwIBAgIUJSmf6Ooxg8uIwfFlHQYFQl5KMSYwDQYJKoZIhvcNAQEL
  BQAwgcMxIzAhBgkqhkiG9w0BCQEWFG5hLXNlLXJ0b0ByZWRoYXQuY29tMQswCQYD
  VQQGEwJVUzEXMBUGA1UECAwOTm9ydGggQ2Fyb2xpbmExEDAOBgNVBAcMB1JhbGVp
  Z2gxFDASBgNVBAoMC05vdCBSZWQgSGF0MRswGQYDVQQLDBJTRSBSVE8gTm90IElu
  Zm9TZWMxMTAvBgNVBAMMKFNvdXRoZWFzdCBSVE8gUm9vdCBDZXJ0aWZpY2F0ZSBB
  dXRob3JpdHkwHhcNMjIwMzA3MDAwNTA5WhcNNDIwOTE4MDAwNTA5WjCBwzEjMCEG
  CSqGSIb3DQEJARYUbmEtc2UtcnRvQHJlZGhhdC5jb20xCzAJBgNVBAYTAlVTMRcw
  FQYDVQQIDA5Ob3J0aCBDYXJvbGluYTEQMA4GA1UEBwwHUmFsZWlnaDEUMBIGA1UE
  CgwLTm90IFJlZCBIYXQxGzAZBgNVBAsMElNFIFJUTyBOb3QgSW5mb1NlYzExMC8G
  A1UEAwwoU291dGhlYXN0IFJUTyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eTCC
  AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANGozAIcO/PB4uIwI31kuiGW
  j+Nm+ZJruiOaG0P/Z99F/i7e9aOrQD8BHmlGOp9R0sdabrmidvowLE69g5z4+Q0E
  4+Uvt4GX/DYOBVR/xuV3E8LFJN1zXXbFtXJlSBz3PLWNaySAcg55a/Pwz68EWFA1
  H2RL5I/sPDpFiz0POnZ+MJ15BCQ2P5YCN7lsHSkmbRonz349WAhvE5OM6qIrBw/J
  Y6AJtAuEVnyiKoilqEvg0Gz6mSnog2yJY1CktMmP7S6/DPuJpTrw74027mp+g1Pm
  hRf8jVNsLNM7VPMo8AIodTCIc+Gv3EJ1bjMc/nF1F3K5jBQZrfe21QpgMKyeY/RV
  FvoHaCy2Miw2RFE9HOo0rwnOohiXlZM6ZSL5AUfDH2tSlJJNr08fE4op48UMIahz
  2My117CKFE2gRe5bhEEJAO9gOqsq1oOT4Oi3TP+lysjAVAIcnNFhQ1uRmJ93Y8HU
  qOCOgH+PV7N+kNtOwy8y32+Czh6njL09IbR8TNH2fOXYVt7JDZjnfU+FdzagNWc5
  C+aQCdpKIMig5OuU81Ac8k6+Aj0CBawOcBI63oxV/GWkUJPgQytmyo/2zswD9FcD
  yIVL1nvJOwVWNEyOLtDWmEzSda6CVLFFQnAw35qgS94Hc7IS3nQW6XFEGj7xzTmd
  b2xoEKhgx+dPw5h7AYPHAgMBAAGjgcYwgcMwHQYDVR0OBBYEFDzw4uwWVqsqJDNM
  2Rz+ztC/ZgUNMB8GA1UdIwQYMBaAFDzw4uwWVqsqJDNM2Rz+ztC/ZgUNMA8GA1Ud
  EwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMGAGA1UdHwRZMFcwVaBToFGGT2h0
  dHBzOi8vcmVkLWhhdC1zZS1ydG8uZ2l0aHViLmlvOjQ0My9jcmxzL3NlLXJ0by1y
  b290LWNlcnRpZmljYXRlLWF1dGhvcml0eS5jcmwwDQYJKoZIhvcNAQELBQADggIB
  AFu7g/6ghP0PaLsjjAPW+QWqv9tMk8w0MKbKgVeUOX5xz1I7Svc1ndi2dMcYwK8W
  pgF4bVR8T17NE3V0/xy6BGktN9BtErI9guk3zb3GBIx/1b3Mgce7134nGvhi4ik7
  ziNB2WYwOgwxEpSA1eS68WNMT6pWZvosEZu9AKMUQ8ULsfxiKwVT+Pj171JxIvDV
  blhilnOrBap7sP1XwS9OPcQhm0AMtFEj/zhadO1h2ynwKjd/VE2/nskfLvm1dXK5
  DtdHsCdtT/hJ0XQjLkwOkl87WHZsy4u6kxQzxKH+LDWfSOCOksYD86fBdfQC66gL
  7yJpX9BznEaGCKgFam3m42eH9msCIV/JTTLUbsrwzaEhxBLtpUeo6j1xF2khF8Ri
  45Sir0yotZE0i72S4TLllkgQx9AaOiRAWvtYkcP1TBJnzL5viac3pkTnPjLiQ9BO
  V8+9Y1O6wU0KTbLdMaz+Wfpti1lcnphQDsMJoGTe6wl3QpAK2jz32aFMoTkoyDK5
  MwQqiTMkyOkPCiY4Rq1RRnYGIU7Ob125IjaFqyLvG9KWuiFsH7yn2nVH5kwy7O75
  7yx0UiBuGVfG66I09YM1jR9nq7mKv30Sq1Fa/X76XyxDBGk0rLRCw02Ziq0rS8WG
  S5kIfhw8FM52x6RHCwRicArO8HSTCf4ueEkFL7yj5xSI
  -----END CERTIFICATE-----
```

#### SNO Deployment

```yaml=
# Node Counts the installer will expect
control_plane_replicas: 1
app_node_replicas: 0

# nodes defines the nodes to use for the cluster
nodes:
  - hostname: sno
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
    networkConfig:
      interfaces:
        - name: enp97s0f0.70
          type: vlan
          state: up
          vlan:
            id: 70
            base-iface: enp97s0f0
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0.70
            table-id: 254
```

#### 3 Node Cluster Deployment

```yaml=
# Node Counts the installer will expect
control_plane_replicas: 3
app_node_replicas: 0

# nodes defines the nodes to use for the cluster
nodes:
  - hostname: node1
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: node2
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:96
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:96
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.47
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: node3
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:97
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:97
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.48
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254
```

#### HA Cluster Deployment

```yaml=
# Node Counts the installer will expect
control_plane_replicas: 3
app_node_replicas: 2

# nodes defines the nodes to use for the cluster
nodes:
  - hostname: cp1
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: cp2
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:96
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:96
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.47
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: cp3
    role: master
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:97
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:97
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.48
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: app1
    role: worker
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:98
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:98
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.49
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254

  - hostname: app2
    role: worker
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:99
    networkConfig:
      interfaces:
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:99
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.50
                prefix-length: 23
            dhcp: false
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0
            table-id: 254
```

---

## NMState Configuration Examples

### VLAN

```yaml=
nodes:
  - hostname: sno
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
    networkConfig:
      interfaces:
        - name: enp97s0f0.70
          type: vlan
          state: up
          vlan:
            id: 70
            base-iface: enp97s0f0
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false
        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: enp97s0f0.70
            table-id: 254
```

### Bond

```yaml=
nodes:
  - hostname: sno
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
      - name: enp97s0f1
        mac_address: D0:50:99:DD:58:96
    networkConfig:
      interfaces:
        - name: bond0
          type: bond
          state: up
          ipv4:
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false
            enabled: true
          link-aggregation:
            # mode=1 active-backup
            # mode=2 balance-xor
            # mode=4 802.3ad
            # mode=5 balance-tlb
            # mode=6 balance-alb
            mode: 802.3ad
            port:
              - enp97s0f0
              - enp97s0f1

        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
        - name: enp97s0f1
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:96
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: bond0
            table-id: 254
```

### Bond + VLAN

```yaml=
nodes:
  - hostname: sno
    rootDeviceHints:
      deviceName: /dev/nvme0n1
    interfaces:
      - name: enp97s0f0
        mac_address: D0:50:99:DD:58:95
      - name: enp97s0f1
        mac_address: D0:50:99:DD:58:96
    networkConfig:
      interfaces:
        - name: bond0.70
          type: vlan
          state: up
          vlan:
            id: 70
            base-iface: bond0
          ipv4:
            enabled: true
            address:
              - ip: 192.168.70.46
                prefix-length: 23
            dhcp: false

        - name: bond0
          type: bond
          state: up
          link-aggregation:
            # mode=1 active-backup
            # mode=2 balance-xor
            # mode=4 802.3ad
            # mode=5 balance-tlb
            # mode=6 balance-alb
            mode: 802.3ad
            port:
              - enp97s0f0
              - enp97s0f1

        - name: enp97s0f0
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:95
        - name: enp97s0f1
          type: ethernet
          state: up
          mac-address: D0:50:99:DD:58:96
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.70.1
            next-hop-interface: bond0.70
            table-id: 254
```

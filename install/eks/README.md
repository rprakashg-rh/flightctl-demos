# FlightCTL On EKS
Steps to install FlightCTL on EKS cluster


## Setup Gateway API

Set aws region and cluster name in environment variable

```sh
export AWS_REGION=us-west-2
export CLUSTER_NAME=rhem-eks-demo
```

### Configure EKS Nodes security group to receive traffic from the VPC Lattice network

Get Cluster Security Group ID and set it in environment variable

```sh
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER_NAME --output json | jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
```

```sh
PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
```

Authorize Security Group Ingress

```sh
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID}}],IpProtocol=-1"
```

Do the above for IPV6

```sh
PREFIX_LIST_ID_IPV6=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
```

Authorize Security Group Ingress

```sh
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID_IPV6}}],IpProtocol=-1"
```

Setup necessary permissions for AWS Gateway API Controller to operate

Download recommended policy
```sh
curl https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/recommended-inline-policy.json  -o recommended-inline-policy.json
```

Create the policy

```sh
aws iam create-policy \
    --policy-name VPCLatticeControllerIAMPolicy \
    --policy-document file://recommended-inline-policy.json
```

Set policy ARN in environment variable

```sh
export VPCLatticeControllerIAMPolicyArn=$(aws iam list-policies --query 'Policies[?PolicyName==`VPCLatticeControllerIAMPolicy`].Arn' --output text)
```

Update kubeconfig

```sh
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
```

Create `aws-application-networking-system` namespace

```sh
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/deploy-namesystem.yaml

```

### Use POD Identities to setup permissions for gateway controller

Pod Identity Addon is already added to the cluster using terraform when cluster was created.

Create a service account for the gateway controller

```sh
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
    name: gateway-api-controller
    namespace: aws-application-networking-system
EOF
```

Create the IAM role

```sh
aws iam create-role --role-name VPCLatticeControllerIAMRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}'

Attach role policy to IAM role

```sh
aws iam attach-role-policy --role-name VPCLatticeControllerIAMRole --policy-arn=$VPCLatticeControllerIAMPolicyArn
```

Set the IAM Policy ARN in environment variable

```sh
export VPCLatticeControllerIAMRoleArn=$(aws iam list-roles --query 'Roles[?RoleName==`VPCLatticeControllerIAMRole`].Arn' --output text)
```

Create the association with pod identity agent

```sh
aws eks create-pod-identity-association --cluster-name $CLUSTER_NAME --role-arn $VPCLatticeControllerIAMRoleArn --namespace aws-application-networking-system --service-account gateway-api-controller
```

### Install the controller

Login to ECR

```sh
aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
```

Run helm with either install or upgrade

```sh
helm install gateway-api-controller \
    oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart \
    --version=v1.1.0 \
    --set=serviceAccount.create=false \
    --namespace aws-application-networking-system \
    --set=log.level=info # use "debug" for debug level logs
```

Install Gateway API CRDs

```sh
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml
```

Create the `amazon-vpc-lattice` GatewayClass

```sh
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/gatewayclass.yaml
```

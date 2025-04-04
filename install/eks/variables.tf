variable "region" {
  description = "EKS Cluster AWS region"
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "EKS Cluster name"
  type = string
  default = "rhem-eks-demo"
}

variable "k8sversion" {
  description = "Kubernetes version"
  type = string
  default = "1.32"
}

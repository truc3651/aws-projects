data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

# authentication information needed to connect to EKS cluster
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

provider "helm" {
  kubernetes {
    # API endpoint URL
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

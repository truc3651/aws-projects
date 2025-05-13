resource "aws_iam_policy" "aws_lb_controller_policy" {
  name   = "aws-lb-controller-policy"
  policy = file("${path.module}/aws-lb-controller-policy.json")
}

resource "aws_iam_role" "aws_lb_controller_role" {
  name = "aws-lb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # only this service account can assume this role
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            # although audience will be always sts, but we need to explicitly mention it, rather than implicitly
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy" {
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
  role       = aws_iam_role.aws_lb_controller_role.name
}

# paste to kubernetes service acccount annotation
output "aws_lb_controller_role_arn" {
  value = aws_iam_role.aws_lb_controller_role.arn
}

# RBAC
resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  # this is version of the helm package
  version = "1.5.3"

  set {
    name  = "region"
    value = local.region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  # this is version of the controller
  set {
    name  = "image.tag"
    value = "v2.5.2"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller_role.arn
  }

  depends_on = [aws_eks_node_group.general, aws_iam_policy.aws_lb_controller_policy]
}

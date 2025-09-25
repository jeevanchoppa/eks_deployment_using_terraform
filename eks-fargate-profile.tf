###################################################
        # EKS FARGATE PROFILE #
##################################################

resource "aws_eks_fargate_profile" "project-eks-fp" {
  cluster_name           = aws_eks_cluster.project-eks-cluster.name
  fargate_profile_name   = "project-eks-fp"
  pod_execution_role_arn = aws_iam_role.project-eks-fp.arn
  subnet_ids             = aws_subnet.project-eks-private-subnet[*].id
  depends_on             = [aws_iam_role_policy_attachment.project-eks-fp-AmazonEKSFargatePodExecutionRolePolicy]

  selector {
    namespace = "kube-system"
  }
  selector {
    namespace = "default"
  }
}

resource "aws_iam_role" "project-eks-fp" {
  name = "eks-fargate-profile-project-eks-fp"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "project-eks-fp-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.project-eks-fp.name
}


resource "aws_eks_fargate_profile" "project-eks-fp-game" {
  cluster_name           = aws_eks_cluster.project-eks-cluster.name
  fargate_profile_name   = "alb-sample-app"
  pod_execution_role_arn = aws_iam_role.project-eks-fp.arn
  subnet_ids             = aws_subnet.project-eks-private-subnet[*].id
  depends_on             = [aws_iam_role_policy_attachment.project-eks-fp-AmazonEKSFargatePodExecutionRolePolicy]

  selector {
    namespace = "game-2048"
  }
}
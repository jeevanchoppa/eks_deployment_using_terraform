
#####################################################################
################### EKS NODE GROUP ##################################
#####################################################################
resource "aws_eks_node_group" "project-eks-node-group" {
  cluster_name    = aws_eks_cluster.project-eks-cluster.name
  node_group_name = "project-eks-cluster-node-group"
  node_role_arn   = aws_iam_role.project-eks-cluster-node-role.arn
  subnet_ids      = aws_subnet.project-eks-private-subnet[*].id
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.micro"]
  update_config {
    max_unavailable = 1
  }
  #node_group_name_prefix = "project-eks"
  remote_access {
    ec2_ssh_key               = "ultimate_DevOps_project_server_keypair"
    source_security_group_ids = [aws_security_group.project-eks-allow-ssh-to-node-group.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.project-eks-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.project-eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.project-eks-AmazonEKSWorkerNodePolicy,
  ]
}

resource "aws_iam_role" "project-eks-cluster-node-role" {
  name = "project-eks-cluster-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]

        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "project-eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.project-eks-cluster-node-role.name
}

resource "aws_iam_role_policy_attachment" "project-eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.project-eks-cluster-node-role.name
}

resource "aws_iam_role_policy_attachment" "project-eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.project-eks-cluster-node-role.name
}
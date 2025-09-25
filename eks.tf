resource "aws_eks_cluster" "project-eks-cluster" {
  name = "eks-cluster-demo"
  role_arn = aws_iam_role.project-eks-cluster-role.arn
  version  = "1.32"
  #bootstrap_self_managed_addons = true

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
    elastic_load_balancing {
      enabled = false
    }
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    security_group_ids      = [aws_security_group.project-eks-cluster-sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = concat(aws_subnet.project-eks-private-subnet[*].id, aws_subnet.project-eks-public-subnet[*].id)
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [aws_iam_role_policy_attachment.project-eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.project-eks-AmazonEKSServicePolicy,
  ]

  tags = {
    NAME = "project-eks-cluster"
  }
}

resource "aws_iam_role" "project-eks-cluster-role" {
  name = "project-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          #"sts:TagSession"
        ]

        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "project-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.project-eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "project-eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.project-eks-cluster-role.name
}

resource "aws_security_group" "project-eks-cluster-sg" {
  name        = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.project-eks-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-eks-cluster"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "project-eks-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.project-eks-cluster-sg.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "project-eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.project-eks-cluster-sg.id
  source_security_group_id = aws_security_group.project-eks-allow-ssh-to-node-group.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eks_access_policy_association" "project-eks-access-policy" {
  cluster_name  = aws_eks_cluster.project-eks-cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = "arn:aws:iam::326614947887:user/DevOps_Engineer"

  access_scope {
    type = "cluster"
    #namespaces = ["example-namespace"]
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"
  cluster_name = "pri-cluster"
  cluster_version = "1.29"

  vpc_id = var.eks-vpc-id

  subnet_ids = [
    var.pri-sub1-id,
    var.pri-sub2-id
    # 일단은 변수만 선언을 해두고, 나중에 vpc모듈에서 뽑아낸output값을 넣어줄꺼다
  ]

  eks_managed_node_groups = {
    pri-cluster-nodegroups = {
        min_size = 1
        max_size = 2
        desired_size = 1
        instance_types = ["t3.micro"]

    }
  }
  cluster_endpoint_private_access = true
}


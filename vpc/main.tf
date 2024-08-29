terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

# vpc 정의
resource "aws_vpc" "this" {
    cidr_block = "10.50.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "eks-vpc"
    }
}

# IGW를 생성, vpc와 IGW 연결

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "eks-vpc-igw"
  }

}

# NATGW를 위한 탄력IP 생성

resource "aws_eip" "this" {
    lifecycle {
        create_before_destroy = true 
        # 재성성시 먼저 새로운 리소스(eip)를 하나 만들고 기존 리소스를 삭제
        # 롤링업뎃이라고 생각하면 편하다
    }

    tags = {
        Name = "eks-vpc-eip"

    }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "pub_sub1" {
    vpc_id = aws_vpc.this.id #위에서 aws_vpc라는 리소스로 만든 this라는 리소스의 id
    cidr_block = "10.50.10.0/24"
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "pub-sub1"
        "kubernetes.io/cluster/pri-cluster" = "owned"
        "kubernetes.io/role/elb" = "1"
    
    }
    depends_on = [ aws_internet_gateway.this ]
}

resource "aws_subnet" "pub_sub2" {
    vpc_id = aws_vpc.this.id #위에서 aws_vpc라는 리소스로 만든 this라는 리소스의 id
    cidr_block = "10.50.11.0/24"
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    availability_zone = "ap-northeast-2c"
    tags = {
        Name = "pub-sub2"
        "kubernetes.io/cluster/pri-cluster" = "owned"
        "kubernetes.io/role/elb" = "1"
    
    }
    depends_on = [ aws_internet_gateway.this ]
}
# NATGW를 생성

resource "aws_nat_gateway" "this" {
    allocation_id = aws_eip.this.id
    subnet_id     = aws_subnet.pub_sub1.id
    tags = {
        Name = "eks-vpc-natgw"
    }
    lifecycle {
      create_before_destroy = true
    }
}

# 프라이빗 서브넷 생성

resource "aws_subnet" "pri_sub1" {
    vpc_id = aws_vpc.this.id #위에서 aws_vpc라는 리소스로 만든 this라는 리소스의 id
    cidr_block = "10.50.20.0/24"
    enable_resource_name_dns_a_record_on_launch = true
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "pri-sub1"
        "kubernetes.io/cluster/pri-cluster" = "owned"
        "kubernetes.io/role/internal-elb" = "1"
    
    }
    depends_on = [ aws_nat_gateway.this ]
}

resource "aws_subnet" "pri_sub2" {
    vpc_id = aws_vpc.this.id #위에서 aws_vpc라는 리소스로 만든 this라는 리소스의 id
    cidr_block = "10.50.21.0/24"
    enable_resource_name_dns_a_record_on_launch = true
    availability_zone = "ap-northeast-2c"
    tags = {
        Name = "pri-sub2"
        "kubernetes.io/cluster/pri-cluster" = "owned"
        "kubernetes.io/role/internal-elb" = "1"
    
    }
    depends_on = [ aws_nat_gateway.this ]
}

# 퍼블릭 라우팅 테이블 정의
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "10.50.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "eks-vpc-pub-rt"
  }
}
# 프라이빗 라우팅 테이블 정의
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "10.50.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }
  tags = {
    Name = "eks-vpc-pri-rt"
  }
}

# 라우팅 테이블과 서브넷을 연결
# 퍼블릭 라우팅테이블과 퍼블릭 서브넷을 연결

resource "aws_route_table_association" "pub1_rt_asso" {
    subnet_id = aws_subnet.pub_sub1.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub2_rt_asso" {
    subnet_id = aws_subnet.pub_sub2.id
    route_table_id = aws_route_table.pub_rt.id
}

# 퍼블릭 라우팅테이블과 퍼블릭 서브넷을 연결

resource "aws_route_table_association" "pri1_rt_asso" {
    subnet_id = aws_subnet.pri_sub1.id
    route_table_id = aws_route_table.pri_rt.id
}

resource "aws_route_table_association" "pri2_rt_asso" {
    subnet_id = aws_subnet.pri_sub2.id
    route_table_id = aws_route_table.pri_rt.id
}

# 퍼블릭 라우팅테이블과 퍼블릭 서브넷을 연결

resource "aws_route_table_association" "pub_rt_asso" {
    subnet_id = aws_subnet.pub_sub1.id
    route_table_id = aws_route_table.pub_rt.id
}

# 보안그룹 생성

resource "aws_security_group" "eks-vpc-pub-sg" {
    vpc_id = aws_vpc.this.id
    name = "eks-vpc-pub-sg"
    tags = {
        Name = "eks-vpc-pub-sg"
    }
}

# http 인그리스 허용.

resource "aws_security_group_rule" "eks-vpc-http-ingress" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.eks-vpc-pub-sg.id
    lifecycle {
      create_before_destroy = true
    }
  
}

resource "aws_security_group_rule" "eks-vpc-ssh-ingress" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.eks-vpc-pub-sg.id
    lifecycle {
      create_before_destroy = true
    }
  
}

# 이그리스 규칙.

resource "aws_security_group_rule" "eks-vpc-all-egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0"]
    security_group_id = aws_security_group.eks-vpc-pub-sg.id
    lifecycle {
      create_before_destroy = true
    }
  
}


# RDS 보안그룹
resource "aws_security_group" "eks-vpc-db-sg" {
    vpc_id = aws_vpc.this.id
    name = "eks-vpc-db-sg"
    tags = {
        Name = "eks-vpc-db-sg"
    }
}

resource "aws_security_group_rule" "eks-vpc-db-egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0"]
    security_group_id = aws_security_group.eks-vpc-db-sg.id
    lifecycle {
      create_before_destroy = true
    }
  
}

resource "aws_security_group_rule" "eks-vpc-db-ingress" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "TCP"
    cidr_blocks = [ "0.0.0.0/0"]
    security_group_id = aws_security_group.eks-vpc-db-sg.id
    lifecycle {
      create_before_destroy = true
    }
  
}

resource "aws_db_subnet_group" "this" {
  name = "min-subgroup"
  subnet_ids = [ aws_subnet.pri_sub1.id, aws_subnet.pri_sub2.id ]

  tags = {
    "Name" = "min-pub-subgroup"
  }

}
resource "aws_db_subnet_group" "that" {
  name = "min-pub-subgroup"
  subnet_ids = [ aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id ]

  tags = {
    "Name" = "min-pub-subgroup"
  }

}

# RDS for postgre DB 생성
resource "aws_db_instance" "this" {
  # 오토스케일링 설정
  allocated_storage = 20
  max_allocated_storage = 50
  skip_final_snapshot = true
  # 자동 백업 주기 설정
  # backup_retention_period = 7
  db_subnet_group_name = aws_db_subnet_group.that.name
  vpc_security_group_ids = [aws_security_group.eks-vpc-db-sg.id]
  engine = "mysql"
  engine_version = "5.7.44"
  instance_class = "db.t3.micro"
  storage_type   = "gp2"
  identifier = "database-1"
  # 유저 ID, Password 지정
  username = "root"
  password = "test1234"
  # 허용 포트 설정
  port = "3306"
  db_name = "db"
  # 다중AZ 설정
  multi_az = true
  # CloudWatch 로그 전송
  # enabled_cloudwatch_logs_exports = ["mysql", "upgrade"]
  parameter_group_name = "mysql57"
  publicly_accessible = true
  tags = {
    "Name" = "database-1"
  }
}
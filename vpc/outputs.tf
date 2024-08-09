output "eks-vpc-id" {
  value = aws_vpc.this.id
  # eks-vpc-id 라는 키값에 aws_vpc.this.id가 들어갈 예정.
  # 예) vpc-08f1cd2c950c9b9f3
}

output "pri-sub1-id" {
    value = aws_subnet.pri_sub1.id
}

output "pri-sub2-id" {
    value = aws_subnet.pri_sub2.id
}

output "pub-sub1-id" {
    value = aws_subnet.pub_sub1.id
}

output "pub-sub2-id" {
    value = aws_subnet.pub_sub2.id
}
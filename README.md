## vpc, eks terraform으로 구성

### vpc 
- main.tf -> aws 프로바이더, vpc, igw, eip, public subnet 2개, priviate subnet 2개, 라우팅 테이블, 보안그룹 정의
- outputs.tf -> eks클러스터 생성할 때 필요한 정보

### eks
- main.tf -> 노드가 될 인스턴스, 최대, 최소, 인스턴스 타입 등등 정의
- variables.tf -> vpc에서 output으로 출력한 거 받아오기 위한 변수 생성

## terraform 명령어
```terraform init
terraform plan
terraform apply --auto-approve
```

## eks configmap
```aws eks update-kubeconfig --name bookstore-cluster
```




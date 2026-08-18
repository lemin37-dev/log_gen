# ECS -> CloudWatch -> S3, kinesis, ... => 외부연결 X
resource "aws_security_group" "fargate" {
  name        = "${var.project_name}-fargate-sg"
  description = "Only fargate without external connection"
  vpc_id      = aws_vpc.this.id
  # ingress allow X (모두 차단)

  tags = {
    Name = "${var.project_name}-fargate-sg"
  }
}

# ECR push, CloudWatch logs 전송 -> outbound 허용
# security group 정의 시 egress를 작성하지 않고 특정 sg에 반영하는 방식으로 적용
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.fargate.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # 모든 프로토콜 대응
}

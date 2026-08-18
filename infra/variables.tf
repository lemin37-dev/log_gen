variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름에 사용할 프로젝트명"
  type        = string
  default     = "de-ai-19-loggen"
}

variable "vpc_cidr" {
  description = "VPC CIDR, Fargate 전용"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록, Fargage Task 작동 시 매번 다른 가용영역 사용"
  type        = list(string)
  # AZ 가용영역을 2개 사용하는 것을 염두
  default = ["10.20.1.0/24", "10.20.2.0/24"]

  # 유효성
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "최소 1개의 public subnet cidr 필수"
  }
}

# Fargate Task CPU
variable "task_cpu" {
  description = "cpu unit (512 = 0.5 vCPU)"
  type        = number
  default     = 512
}

# Fargate Task Memory
variable "task_memory" {
  description = "memory (Mib)"
  type        = number
  default     = 1024
}

# CloudWatch log retention
variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 7
}

# ECS Task가 ECR 이미지 획득 시 접근할 태그
variable "image_tag" {
  description = "Task가 정의될 때 참고하는 태그명 (가장 최신 Image 사용)"
  type        = string
  default     = "latest"
}
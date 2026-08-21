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

# @bronze : kinesis, firehose 관련 변수 추가
# Kinesis Data Sterams : KDS
# 성능에 영향을 주는 요소 -> shard 개수, 데이터 보관기간(retention)
# 프로비저닝 방식으로 구성한다 (샤드 수 직접 지정) <-> 온디맨트(샤드 수 자동 조율)
variable "kinesis_shard_count" {
  description = "KDS's shard count"
  type        = number
  default     = 1
}
# 전송되지 않은 데이터는 하루만 보관
variable "kinesis_retention_hour" {
  description = "KDS's retention period in hours"
  type        = number
  default     = 24
}

# Amazon Data Firehose : ADF
# 최소 1 MiB, 최대 128 MiB입니다. 5 MiB을(를) 권장합니다.
variable "firehose_buffer_size" {
  description = "해당 크기(mib)만큼 데이터가 쌓이면 강제 전송"
  type        = number
  default     = 1
}
# 최소 0 초, 최대 900 초입니다. 300 초을(를) 권장합니다.
variable "firehose_buffer_interval" {
  description = "해당 시간(s)만큼 데이터가 쌓이면 강제 전송"
  type        = number
  default     = 60
}

# @silver : 새로운 리소스에 대한 변수 추가
# silver layer에서 사용할 kinesis의 출력용 샤드 수
variable "silver_kinesis_shard_count" {
  description = "Silver KDS's shard count"
  type        = number
  default     = 1
}
# kinesis 보관 기간
variable "silver_kinesis_retention_hour" {
  description = "Silver KDS's retention period in hours"
  type        = number
  default     = 24
}
# PyFlink 버전(런타임 환경 버전)
variable "flink_runtime_environment" {
  description = "Managed Apache Flink의 런타임 환경"
  type        = string
  default     = "FLINK-1_20"
}
# Flink Application 병렬 구성 수
variable "flink_parallelism" {
  description = "Initial Flink application parallelism"
  type        = number
  default     = 1
}
# KPU(Kinesis Processing Unit) 하나당 Parallel task 수 설정
# 기본 컴퓨팅의 과금단위
variable "flink_parallelism_per_kpu" {
  description = "Flink parallel tasks per KPU"
  type        = number
  default     = 1
}
# true일 경우 인프라가 적용된 후 바로 실행
# false일 경우 실제 사용 시 적용
# flink는 실행중으로 설정해두어야만 작동됨
variable "flink_start_application" {
  description = "Whether Terraform should start the Managed Flink application"
  type        = bool
  default     = true
}
# Flink를 가동하고 나서 입력(브론즈)방향 kinesis에서 데이터를 읽을 때 어디서부터 처리할 것인지에 대한 설정
# 데이터는 계속해서 전송중 -> 추후 Flink 가동 -> 가동 전에 도달한 데이터도 처리할 것인지 or 가동 이후 도착 데이터에 대해서만 처리할 것인지
# LATEST : flink 가동 후 들어오는 데이터만 처리
# TRIM_HORIZON : kinesis에 남아있는 과거 로그데이터 모두 처리 -> 재처리/테스트/전체(이전) 데이터 처리
variable "flink_source_init_position" {
  description = "flink가 데이터 처리 시 입력원의 어디서부터 처리할 것인지 설정"
  type        = string
  default     = "LATEST"

  validation {
    # 2가지 option만 허용
    condition = contains([
      "LATEST",
      "TRIM_HORIZON"
    ], var.flink_source_init_position)
    error_message = "flink_source_init_position is only LATEST or TRIM_HORIZON"
  }
}

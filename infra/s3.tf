# @bronze : S3 추가
# 브론즈/실버/골드 데이터가 저장될 데이터레이크 정의
resource "aws_s3_bucket" "data" {
  # 버킷 1개 구성, 하위에 브론즈/실버/골드 레이어 관리
  bucket = "${var.project_name}-loggen-s3-bk-${data.aws_caller_identity.current.account_id}"

  # 버킷 삭제 옵션 (저장된 객체가 있어도 같이 삭제)
  force_destroy = true
}

# 외부 public 접근 차단(내부 or 권한이 있는 경우에만 접근)
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  # 정책 설정
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
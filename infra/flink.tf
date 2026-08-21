locals {
  # flink 앱 경로 -> flink-silver 파일은 스크립트에서 정의(flink 최종 산출물 경로)
  # ${path.module} -> ~/infra (현재 디렉터리 위치)
  flink_artifact_path = "${path.module}/../flink/target/flink-silver.zip"

  # zip 내용에 MD5 해시를 계산하여 코드 변경여부 식별 용도
  flink_artifact_hash = filemd5(local.flink_artifact_path)
}

# flink_app은 flink-silver.zip을 의미하고 aws s3에 위치해야 함
resource "aws_s3_object" "flink_app" {
  # 버킷 지정
  bucket = aws_s3_bucket.data.id
  # flink 앱 지정 -> 키
  key = "flink/applications/flink-silver-${local.flink_artifact_hash}.zip"

  # local -> s3 업로드한 zip(flink app) 경로
  source = local.flink_artifact_path
  # flink app hash 값 -> 소스 변경 시 감지됨
  source_hash = local.flink_artifact_hash

  depends_on = [
    aws_s3_bucket_public_access_block.data
  ]
}

# flink 자체 내용
resource "aws_kinesisanalyticsv2_application" "silver" {
  name        = local.flink_application_name
  description = "Raw(Bronze) Kinesis events to Silver Kinesis using PyFlink"
  # runtime env (version)
  runtime_environment = var.flink_runtime_environment
  # role
  service_execution_role = aws_iam_role.flink.arn
  # application - true : 생성 후 즉시 실행 / false : 생성만 진행(따로 실행필요)
  start_application = var.flink_start_application

  # application 상세 구성
  application_configuration {
    # snapshot 활성화 여부
    application_snapshot_configuration {
      snapshots_enabled = false
    }
    # flink application code 설정
    application_code_configuration {
      # flink application 위치
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.data.arn
          file_key   = aws_s3_object.flink_app.key
        }
      }
      # application code type(extension)
      code_content_type = "ZIPFILE"
    }

    # 환경 구성
    environment_properties {
      # Raw(bronze) layer kinesis 입력부 리소스 
      property_group {
        property_group_id = "InputStream0" # flink 앱의 application_properties.json에 지정한 PropertyGroupId과 일치시켜야 함

        property_map = {
          "stream.arn"                 = aws_kinesis_stream.logs.arn
          "aws.region"                 = var.aws_region
          "flink.source.init.position" = var.flink_source_init_position
        }
      }

      # 가공/전처리(Silver) layer kinesis 출력부 리소스
      property_group {
        property_group_id = "OutputStream0" # flink 앱의 application_properties.json에 지정한 PropertyGroupId과 일치시켜야 함

        property_map = {
          "stream.arn" = aws_kinesis_stream.silver.arn
          "aws.region" = var.aws_region
        }
      }

      # Flink 실행 옵션
      property_group {
        # AWS Managed Flink를 인식하는 예약 그룹명
        property_group_id = "kinesis.analytics.flink.run.options"

        property_map = {
          # Flink application entry point
          "python" = "main.py"
          # pyFlink -> kinesis 접근에 필요한 라이브러리(드라이버)
          "jarfile" = "lib/pyflink-dependencies.jar"
          # pytnon UDF Worker가 transform.py를 import하도록 등록
          "pyFiles" = "transform.py"
        }
      }
    }

    # flink 엔진 설정
    flink_application_configuration {
      # 장애 복구 시 checkpoint 설정
      checkpoint_configuration {
        configuration_type = "DEFAULT" # 기본값
      }
      # flink 로그, 메트릭 수집 수준 설정
      monitoring_configuration {
        configuration_type = "CUSTOM"      # 직접 설정
        log_level          = "INFO"        # 정보 수준
        metrics_level      = "APPLICATION" # 애플리케이션 단위(레벨) 정보 (system log/metric X)
      }
      # application 구동 시 병렬처리, KPU 설정 
      parallelism_configuration {
        configuration_type   = "CUSTOM" # 직접 설정
        auto_scaling_enabled = true     # 오토스케일링 on
        parallelism          = var.flink_parallelism
        parallelism_per_kpu  = var.flink_parallelism_per_kpu
      }
    }
  }

  # flink 실행 -> 로그(정상/에러) -> cloudwatch 저장
  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink.arn
  }

  # 사전에 role 정책과 flink app이 s3에 구성되어 있어야 함
  depends_on = [
    aws_iam_role_policy.flink,
    aws_s3_object.flink_app
  ]

  tags = {
    DataLayer = "silver"
    Processor = "flink"
  }
}
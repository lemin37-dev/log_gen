# 개요
- Bronze (Raw 데이터 적재)
  - Log generator -> Kinesis -> Firehose(1Mib/60s) -> S3 bronze (raw data, Gzip)
- Silver (Raw 데이터 정제/전처리 등 데이터 조작 -> 저장)
  - Streaming Ingestion -> Streaming Processing + Medalion Architecture
  - Step 1
    - Log generator -> Kinesis -> Flink(java, python, pom.xml) -> Kinesis -> Firehose -> S3 bronze (raw data, Gzip)
  - Step 2
    - Log generator -> Kinesis -> lambda -> Kinesis -> Firehose -> S3 bronze (raw data, Gzip)


# Flink
- 실시간으로 스트리밍 데이터에서 실행 가능한 분석 정보를 확보
  - 실시간 데이터를 실시간으로 전처리/정제 등 작업 가능 (거의 지연이 없음)
- 실시간일 필요가 없을 경우 -> Airflow or Step Function(AWS) 이용하여 Batch Processing 처리
- Silver layer로 저장하는 방법
  - 실시간 : flink, lambda
  - 배치 : airflow, step function
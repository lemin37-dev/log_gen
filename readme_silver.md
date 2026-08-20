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
- 특징
  - 실시간 스트림 처리: Kinesis에서 들어오는 데이터를 계속 읽으면서 즉시 처리
  - Stateful Processing: 이전 이벤트 상태를 기억하면서 집계·판단 가능
  - Event Time 지원: 데이터가 실제 발생한 시간을 기준으로 처리 가능
  - Window 처리: 1분, 5분, 1시간 단위 집계 같은 작업에 강함
  - Checkpoint / 장애 복구: 처리 상태를 저장해서 장애 후 이어서 처리 가능
  - Exactly-once 처리 지원: 중복이나 누락을 최소화하는 신뢰성 높은 스트림 처리 가능
  - `대용량 처리에 적합`: 지속적인 고속 이벤트 처리에 Lambda보다 유리
  - 복잡한 처리 가능: 필터링, 변환, 집계, 조인, 이상 탐지 등에 적합
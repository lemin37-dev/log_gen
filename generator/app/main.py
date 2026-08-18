# 프로그램 진입(entrypoint)
from domains import ecommerce
from faker import Faker

fake = Faker("ko-KR") # locale 정보는 환경변수에서 획득

def run() -> int:
  log = ecommerce.generate(fake, timezone_name="", environment="", run_id="")
  print(log)

  # 정상종료
  return 0

if __name__ == '__main__':
  # run() 반환값을 프로세스 종료코드로 활용
  raise SystemExit(run())


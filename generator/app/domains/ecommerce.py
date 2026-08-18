'''
- 도메인 : 이커머스
- 이커머스 로그 : 상품 조회, 검색, 장바구니, 주문, 결제, ... 관련 로그
'''
from faker import Faker
import random

# 해당 도메인에서 발생가능한 이벤트 종류 정의
EVENTS = ["product_view", "search", "add_to_cart", "checkout", "order_created", "payment_completed"]
# 가중치 부여하여 이벤트의 발생빈도 조절 (도메인 인사이트를 활용하여 분석 설계)
WEIGHTS = [34, 20, 17, 9, 11, 9]

def generate(fake:Faker, *, timezone_name:str, environment:str, run_id:str) -> dict:
  # 1. 이벤트 타입 선택
  event_type = random.choices(EVENTS, weights=WEIGHTS, k=1)[0]

  return {
    "event_type" : event_type
  }
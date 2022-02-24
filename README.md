# The differences from the origin repo

## Translate later
* 풀 자동화
* 오리진은 보일러플레이트 느낌, 이거는 서브모듈로 두고 쓰는 솔루션으로, 독립성 보장을 위해서 src/ 를 바깥 디렉터리에서 가져옴.
* 레이어와 함수 코드 분리
* python이 python3를 가르키는지 check
* 의존성에 pip 추가
* pipreqs로 requirements.txt 자동 생성
* WebDriverWrapper 삭제
* 람다 함수 배포 자동화
* 람다 레이어 배포 자동화
* 기본 S3 사용으로 대용량 파일 지원
* /var/task , /opt/bin /opt/python 등 실제 환경에 맞게 구성
todo: 서브모듈 구성방법 소개, 예시 저장소 만들기


# [Origin repo](https://github.com/jairovadillo/pychromeless)
#!/bin/bash

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

# --- 동적으로 경로 설정 ---
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# 프로젝트 루트 디렉터리로 이동
cd "$PROJECT_ROOT"

# --- 변수 설정 ---
DOCKER_IMAGE_NAME="lambda-builder-image"
OUTPUT_ZIP_FILE="./terraform/thumbnail-generator.zip"
DOCKERFILE_PATH="./Dockerfile.build"

# --- 스크립트 시작 ---
echo "Lambda 배포 패키지 빌드를 시작합니다 (Docker 사용)..."

# 1. 이전 ZIP 파일 정리
if [ -f "$OUTPUT_ZIP_FILE" ]; then
    echo "기존 ZIP 파일을 삭제합니다: $OUTPUT_ZIP_FILE"
    rm "$OUTPUT_ZIP_FILE"
fi

# 2. Docker 이미지 빌드
echo "빌드용 Docker 이미지를 생성합니다: $DOCKER_IMAGE_NAME"
docker build -t "$DOCKER_IMAGE_NAME" -f "$DOCKERFILE_PATH" .

# 3. [핵심 수정] Docker 컨테이너 실행 시 Entrypoint를 'zip'으로 지정
#    AWS Lambda 이미지의 기본 Entrypoint를 무시하고 'zip' 명령어를 직접 실행합니다.
#    Dockerfile에 정의된 CMD ["-r", "-", "."]는 이 'zip' 명령어의 인자로 사용됩니다.
echo "Docker 컨테이너를 실행하여 ZIP 파일을 생성합니다..."
docker run --rm --entrypoint "zip" "$DOCKER_IMAGE_NAME" -r - . > "$OUTPUT_ZIP_FILE"

# --- 완료 메시지 ---
echo "--------------------------------------------------"
echo "빌드 완료! 아래 경로에 파일이 생성되었습니다:"
echo "$(pwd)/terraform/thumbnail-generator.zip"
echo "이제 'cd terraform' 후 'terraform apply'를 실행하세요."
echo "--------------------------------------------------"

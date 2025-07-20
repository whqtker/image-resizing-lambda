#!/bin/bash

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

SOURCE_DIR="$PROJECT_ROOT/script"
BUILD_DIR="$PROJECT_ROOT/lambda_build"
OUTPUT_ZIP_FILE="$PROJECT_ROOT/terraform/thumbnail-generator.zip"

echo "Lambda 배포 패키지 빌드를 시작합니다..."

# 1. 이전 빌드 결과물 정리
echo "이전 빌드 파일을 정리합니다: $BUILD_DIR, $OUTPUT_ZIP_FILE"
rm -rf "$BUILD_DIR" "$OUTPUT_ZIP_FILE"

# 2. 빌드 디렉터리 생성
echo "빌드 디렉터리를 생성합니다: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 3. 의존성 라이브러리 설치
if [ -f "$SOURCE_DIR/requirements.txt" ]; then
    echo "requirements.txt를 사용하여 의존성을 설치합니다..."
    pip install -r "$SOURCE_DIR/requirements.txt" -t "$BUILD_DIR"
else
    echo "경고: requirements.txt 파일이 없어 의존성 설치를 건너뜁니다."
fi

# 4. 소스 코드 복사
echo "소스 코드를 빌드 디렉터리로 복사합니다..."
cp "$SOURCE_DIR"/*.py "$BUILD_DIR/"

# 5. ZIP 파일 생성
echo "ZIP 배포 패키지를 생성합니다: $OUTPUT_ZIP_FILE"
(cd "$BUILD_DIR" && zip -r "$OUTPUT_ZIP_FILE" .)

# 6. 빌드 디렉터리 정리
echo "임시 빌드 디렉터리를 정리합니다..."
rm -rf "$BUILD_DIR"

echo "빌드 완료! $OUTPUT_ZIP_FILE 파일이 생성되었습니다."

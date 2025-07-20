import boto3
import os
import urllib.parse
from PIL import Image
import io

# boto3 S3 클라이언트 초기화
s3_client = boto3.client('s3')

DEST_BUCKET_NAME = os.environ.get('BUCKET_NAME')

THUMBNAIL_SIZE = (200, 200)

# s3에 이미지가 업로드되면 썸네일을 생성하는 람다 함수
def lambda_handler(event, context):
    for record in event['Records']:
        source_bucket = record['s3']['bucket']['name']

        # 1. 파일 이름 디코딩
        source_key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')

        print(f"처리 시작: s3://{source_bucket}/{source_key}")

        # 2. 무한 루프 방지
        if not source_key.startswith('original/'):
            print(f"경고: 'original/' 폴더의 파일이 아니므로 처리를 건너뜁니다: {source_key}")
            continue

        # 3. S3에서 원본 이미지 다운로드
        try:
            response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
            image_content = response['Body'].read()

            source_image = Image.open(io.BytesIO(image_content))

            image_format = source_image.format
            if not image_format:
                raise ValueError("이미지의 포맷을 확인할 수 없습니다.")

            print(f"이미지 다운로드 및 열기 성공: {source_key}, 포맷: {image_format}")

        except Exception as e:
            print(f"오류: 이미지를 다운로드하거나 여는 데 실패했습니다. {e}")
            continue

        # 4. 썸네일 생성
        resized_image = source_image.copy()
        resized_image.thumbnail(THUMBNAIL_SIZE)

        thumbnail_buffer = io.BytesIO()
        resized_image.save(thumbnail_buffer, format=image_format)
        thumbnail_buffer.seek(0)

        print(f"썸네일 생성 완료. 크기: {resized_image.size}")

        # 5. 생성된 썸네일을 S3에 업로드
        dest_key = source_key.replace('original/', 'thumbnails/', 1)

        try:
            s3_client.put_object(
                Bucket=DEST_BUCKET_NAME,
                Key=dest_key,
                Body=thumbnail_buffer,
                ContentType=f'image/{image_format.lower()}'
            )
            print(f"성공: 썸네일이 s3://{DEST_BUCKET_NAME}/{dest_key} 에 업로드되었습니다.")

        except Exception as e:
            print(f"오류: 썸네일을 업로드하는 데 실패했습니다. {e}")
            continue

    return {
        'statusCode': 200,
        'body': '썸네일 생성이 성공적으로 처리되었습니다.'
    }

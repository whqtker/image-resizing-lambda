package org.ll.imageresizinglambda.global.s3.dto;

public record ImageUploadResponse(
        String imageUrl
) {

    public static ImageUploadResponse of(String imageUrl) {
        return new ImageUploadResponse(imageUrl);
    }
}

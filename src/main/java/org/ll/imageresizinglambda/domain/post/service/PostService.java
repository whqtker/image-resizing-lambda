package org.ll.imageresizinglambda.domain.post.service;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.ll.imageresizinglambda.domain.post.entity.Post;
import org.ll.imageresizinglambda.domain.post.repository.PostRepository;
import org.ll.imageresizinglambda.global.s3.service.S3Service;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final S3Service s3Service;

    public void createPost(String title, String content, MultipartFile image) {
        String imgUrl = getImgUrl(image);
        String thumbnailUrl = getThumbnailUrl(imgUrl);

        Post post = new Post(title, content, imgUrl, thumbnailUrl);
        postRepository.save(post);
    }

    private String getImgUrl(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            return null;
        }

        return s3Service.uploadImage(image).imageUrl();
    }

    private String getThumbnailUrl(String imgUrl) {
        if (imgUrl == null) {
            return null;
        }

        return imgUrl.replace("/images/", "/thumbnails/");
    }

    public List<Post> getPosts() {
        return postRepository.findAll();
    }
}

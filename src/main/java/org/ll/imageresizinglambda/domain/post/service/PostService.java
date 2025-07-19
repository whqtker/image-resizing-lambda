package org.ll.imageresizinglambda.domain.post.service;

import lombok.RequiredArgsConstructor;
import org.ll.imageresizinglambda.domain.post.repository.PostRepository;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;

}

package org.ll.imageresizinglambda.domain.post.controller;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.ll.imageresizinglambda.domain.post.service.PostService;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/create")
    public String createPost() {
        return "create-post";
    }
}

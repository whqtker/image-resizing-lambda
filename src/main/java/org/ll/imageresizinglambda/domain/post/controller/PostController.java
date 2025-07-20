package org.ll.imageresizinglambda.domain.post.controller;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.ll.imageresizinglambda.domain.post.entity.Post;
import org.ll.imageresizinglambda.domain.post.service.PostService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Controller
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    @GetMapping("/")
    public String index(Model model) {
        List<Post> posts = postService.getPosts();
        model.addAttribute("posts", posts);
        return "index";
    }

    @GetMapping("/create")
    public String createPostForm() {
        return "create-post";
    }

    @PostMapping("/create")
    public String createPost(
            @RequestParam("title") String title,
            @RequestParam("content") String content,
            @RequestParam(value = "image", required = false) MultipartFile image
    ) {
        postService.createPost(title, content, image);
        return "redirect:/";
    }
}

package org.ll.imageresizinglambda.domain.post.repository;

import org.ll.imageresizinglambda.domain.post.entity.Post;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Long> {

}

---
name: backend-spring-boot
description: >-
  Enterprise Java 17 and Spring Boot 3 engineering: REST APIs, Spring Security,
  JWT authentication, JPA/Hibernate, Gradle/Maven builds, and JUnit/Mockito testing.
---

# Spring Boot 3 & Java 17 Engineering Skill

## Stack Best Practices
1. **Architecture & Standards**:
   - Layer structure: `controller/`, `service/`, `repository/`, `model/`, `dto/`, `config/`.
   - Immutable DTOs using Java 17 records:
     ```java
     public record LoginRequest(
       @NotBlank @Email String email,
       @NotBlank String password
     ) {}
     ```
2. **Security & Authentication**:
   - Configure `SecurityFilterChain` bean with stateless session management (`SessionCreationPolicy.STATELESS`).
   - Implement custom JWT authentication filter extending `OncePerRequestFilter`.
3. **Database & Migrations**:
   - Use Spring Data JPA repositories with derived query methods or JPQL.
   - Run tests with `@DataJpaTest` and Mockito for isolated unit and integration coverage.

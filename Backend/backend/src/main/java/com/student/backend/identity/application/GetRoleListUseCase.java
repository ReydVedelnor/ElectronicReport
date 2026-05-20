package com.student.backend.identity.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.identity.domain.repository.UserRoleRepository;
import com.student.backend.identity.dto.request.GetRoleListRequest;
import com.student.backend.identity.dto.response.RoleListItemResponse;
import com.student.backend.identity.dto.response.RoleListResponse;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GetRoleListUseCase {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 10;
    private static final int MAX_SIZE = 100;

    private final RoleRepository roleRepository;
    private final UserRoleRepository userRoleRepository;

    @Transactional(readOnly = true)
    public RoleListResponse get(GetRoleListRequest request) {
        if (request == null) {
            request = new GetRoleListRequest();
        }

        int page = normalizePage(request.getPage());
        int size = normalizeSize(request.getSize());

        ActivityFilter activityFilter = ActivityFilter.from(request.getActivity());
        List<String> searchTokens = tokenizeSearch(request.getSearch());

        Pageable pageable = PageRequest.of(page, size, buildSort());

        Specification<Role> specification = buildSpecification(activityFilter, searchTokens);

        Page<Role> rolePage = roleRepository.findAll(specification, pageable);
        List<Role> roles = rolePage.getContent();

        if (roles.isEmpty()) {
            return RoleListResponse.builder()
                    .items(List.of())
                    .page(rolePage.getNumber())
                    .size(rolePage.getSize())
                    .totalElements(rolePage.getTotalElements())
                    .totalPages(rolePage.getTotalPages())
                    .hasNext(rolePage.hasNext())
                    .build();
        }

        List<UUID> roleIds = roles.stream()
                .map(Role::getRoleId)
                .toList();

        Map<UUID, Long> participantsCountByRoleId = getParticipantsCountByRoleId(roleIds);

        List<RoleListItemResponse> items = roles.stream()
                .map(role -> RoleListItemResponse.builder()
                        .roleId(role.getRoleId())
                        .name(role.getName())
                        .description(role.getDescription())
                        .isActive(role.getIsActive())
                        .participantsCount(participantsCountByRoleId.getOrDefault(role.getRoleId(), 0L))
                        .build())
                .toList();

        return RoleListResponse.builder()
                .items(items)
                .page(rolePage.getNumber())
                .size(rolePage.getSize())
                .totalElements(rolePage.getTotalElements())
                .totalPages(rolePage.getTotalPages())
                .hasNext(rolePage.hasNext())
                .build();
    }

    private int normalizePage(Integer page) {
        if (page == null) {
            return DEFAULT_PAGE;
        }

        if (page < 0) {
            throw new BadRequestException("page не может быть меньше 0");
        }

        return page;
    }

    private int normalizeSize(Integer size) {
        if (size == null) {
            return DEFAULT_SIZE;
        }

        if (size < 1) {
            throw new BadRequestException("size должен быть больше 0");
        }

        return Math.min(size, MAX_SIZE);
    }

    private Sort buildSort() {
        return Sort.by(
                Sort.Order.desc("isActive"),
                Sort.Order.asc("name").ignoreCase(),
                Sort.Order.asc("roleId")
        );
    }

    private Specification<Role> buildSpecification(ActivityFilter activityFilter, List<String> searchTokens) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            switch (activityFilter) {
                case ACTIVE -> predicates.add(cb.isTrue(root.get("isActive")));
                case INACTIVE -> predicates.add(cb.isFalse(root.get("isActive")));
                case ALL -> {
                    // Без фильтра по активности
                }
            }

            if (searchTokens != null && !searchTokens.isEmpty()) {
                for (String token : searchTokens) {
                    String pattern = "%" + escapeLikePattern(token) + "%";

                    Predicate nameMatches = cb.like(
                            cb.lower(root.get("name")),
                            pattern,
                            '\\'
                    );

                    Predicate descriptionMatches = cb.like(
                            cb.lower(cb.coalesce(root.get("description"), "")),
                            pattern,
                            '\\'
                    );

                    predicates.add(cb.or(nameMatches, descriptionMatches));
                }
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    private List<String> tokenizeSearch(String rawSearch) {
        if (rawSearch == null) {
            return List.of();
        }

        String normalized = rawSearch
                .trim()
                .replaceAll("\\s+", " ")
                .toLowerCase(Locale.ROOT);

        if (normalized.isEmpty()) {
            return List.of();
        }

        String[] parts = normalized.split(" ");
        List<String> tokens = new ArrayList<>();

        for (String part : parts) {
            if (!part.isBlank()) {
                tokens.add(part);
            }
        }

        return tokens;
    }

    private Map<UUID, Long> getParticipantsCountByRoleId(List<UUID> roleIds) {
        if (roleIds == null || roleIds.isEmpty()) {
            return Map.of();
        }

        return userRoleRepository.countActiveParticipantsByRoleIds(roleIds)
                .stream()
                .collect(Collectors.toMap(
                        UserRoleRepository.RoleParticipantsCountProjection::getRoleId,
                        projection -> projection.getParticipantsCount() == null ? 0L : projection.getParticipantsCount(),
                        (left, right) -> left,
                        LinkedHashMap::new
                ));
    }

    private String escapeLikePattern(String value) {
        return value
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
    }

    private enum ActivityFilter {
        ACTIVE,
        INACTIVE,
        ALL;

        static ActivityFilter from(String value) {
            if (value == null || value.isBlank()) {
                return ACTIVE;
            }

            String normalized = value.trim().toLowerCase(Locale.ROOT);

            return switch (normalized) {
                case "true" -> ACTIVE;
                case "false" -> INACTIVE;
                case "all" -> ALL;
                default -> throw new BadRequestException("activity должен быть одним из значений: true, false, all");
            };
        }
    }
}
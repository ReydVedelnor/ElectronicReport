package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.employee.dto.request.GetEmployeeListRequest;
import com.student.backend.employee.dto.response.EmployeeListItemResponse;
import com.student.backend.employee.dto.response.EmployeeListResponse;
import com.student.backend.identity.domain.model.Credential;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.model.UserRole;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Tuple;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Order;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Deque;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetEmployeeListUseCase {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 10;
    private static final int MAX_SIZE = 100;

    private final EntityManager entityManager;
    private final DepartmentRepository departmentRepository;
    private final EmployeeAccessService employeeAccessService;

    @Transactional(readOnly = true)
    public EmployeeListResponse get(GetEmployeeListRequest request) {
        validateRequest(request);

        int page = normalizePage(request.getPage());
        int size = normalizeSize(request.getSize());
        Pageable pageable = PageRequest.of(page, size);

        Department currentUserDepartment = employeeAccessService.getSingleActiveDepartment(request.getUserId());
        Set<UUID> availableDepartmentIds = collectAvailableDepartmentIds(currentUserDepartment);

        Set<UUID> requestedDepartmentIds = normalizeIds(request.getDepartmentIds());
        Set<UUID> effectiveDepartmentIds = resolveEffectiveDepartmentIds(availableDepartmentIds, requestedDepartmentIds);

        if (effectiveDepartmentIds.isEmpty()) {
            return buildEmptyResponse(pageable);
        }

        Set<UUID> roleIds = normalizeIds(request.getRoleIds());
        ActivityFilter activityFilter = ActivityFilter.from(request.getActivity());
        List<String> searchTokens = tokenizeSearch(request.getSearch());

        long totalElements = countEmployees(
                effectiveDepartmentIds,
                roleIds,
                activityFilter,
                searchTokens
        );

        if (totalElements == 0) {
            return buildEmptyResponse(pageable);
        }

        List<EmployeeListItemResponse> items = findEmployees(
                effectiveDepartmentIds,
                roleIds,
                activityFilter,
                searchTokens,
                pageable
        );

        int totalPages = (int) Math.ceil((double) totalElements / pageable.getPageSize());

        return EmployeeListResponse.builder()
                .items(items)
                .page(pageable.getPageNumber())
                .size(pageable.getPageSize())
                .totalElements(totalElements)
                .totalPages(totalPages)
                .hasNext(pageable.getPageNumber() + 1 < totalPages)
                .build();
    }

    private void validateRequest(GetEmployeeListRequest request) {
        if (request == null) {
            throw new BadRequestException("Параметры запроса отсутствуют");
        }

        if (request.getUserId() == null) {
            throw new BadRequestException("userId обязателен");
        }
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

    private Set<UUID> normalizeIds(Collection<UUID> ids) {
        Set<UUID> result = new LinkedHashSet<>();

        if (ids == null || ids.isEmpty()) {
            return result;
        }

        for (UUID id : ids) {
            if (id != null) {
                result.add(id);
            }
        }

        return result;
    }

    private Set<UUID> resolveEffectiveDepartmentIds(Set<UUID> availableDepartmentIds, Set<UUID> requestedDepartmentIds) {
        if (requestedDepartmentIds == null || requestedDepartmentIds.isEmpty()) {
            return availableDepartmentIds;
        }

        Set<UUID> result = new LinkedHashSet<>(requestedDepartmentIds);
        result.retainAll(availableDepartmentIds);
        return result;
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

    private Set<UUID> collectAvailableDepartmentIds(Department rootDepartment) {
        Set<UUID> result = new LinkedHashSet<>();
        Deque<Department> queue = new ArrayDeque<>();
        queue.add(rootDepartment);

        while (!queue.isEmpty()) {
            Department current = queue.poll();

            if (current == null || current.getDepartmentId() == null) {
                continue;
            }

            if (!result.add(current.getDepartmentId())) {
                continue;
            }

            List<Department> children = departmentRepository
                    .findAllByParentDepartment_DepartmentIdOrderByNameAsc(current.getDepartmentId());

            queue.addAll(children);
        }

        return result;
    }

    private long countEmployees(
            Set<UUID> effectiveDepartmentIds,
            Set<UUID> roleIds,
            ActivityFilter activityFilter,
            List<String> searchTokens
    ) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Long> query = cb.createQuery(Long.class);

        Root<User> user = query.from(User.class);
        Root<Credential> credential = query.from(Credential.class);
        Root<UserRole> userRole = query.from(UserRole.class);
        Root<Role> role = query.from(Role.class);
        Root<DepartmentUser> departmentUser = query.from(DepartmentUser.class);
        Root<Department> department = query.from(Department.class);

        List<Predicate> predicates = buildCommonPredicates(
                cb,
                user,
                credential,
                userRole,
                role,
                departmentUser,
                department,
                effectiveDepartmentIds,
                roleIds,
                activityFilter,
                searchTokens
        );

        query.select(cb.countDistinct(user.get("userId")));
        query.where(predicates.toArray(new Predicate[0]));

        return entityManager.createQuery(query).getSingleResult();
    }

    private List<EmployeeListItemResponse> findEmployees(
            Set<UUID> effectiveDepartmentIds,
            Set<UUID> roleIds,
            ActivityFilter activityFilter,
            List<String> searchTokens,
            Pageable pageable
    ) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Tuple> query = cb.createTupleQuery();

        Root<User> user = query.from(User.class);
        Root<Credential> credential = query.from(Credential.class);
        Root<UserRole> userRole = query.from(UserRole.class);
        Root<Role> role = query.from(Role.class);
        Root<DepartmentUser> departmentUser = query.from(DepartmentUser.class);
        Root<Department> department = query.from(Department.class);

        List<Predicate> predicates = buildCommonPredicates(
                cb,
                user,
                credential,
                userRole,
                role,
                departmentUser,
                department,
                effectiveDepartmentIds,
                roleIds,
                activityFilter,
                searchTokens
        );

        query.multiselect(
                user.get("userId").alias("userId"),
                user.get("lastName").alias("lastName"),
                user.get("firstName").alias("firstName"),
                user.get("middleName").alias("middleName"),
                user.get("isActive").alias("isActive"),
                credential.get("login").alias("login"),
                role.get("roleId").alias("roleId"),
                role.get("name").alias("roleName"),
                role.get("isActive").alias("isRoleActive"),
                department.get("departmentId").alias("departmentId"),
                department.get("name").alias("departmentName"),
                department.get("isActive").alias("isDepartmentActive")
        );

        query.where(predicates.toArray(new Predicate[0]));
        query.orderBy(buildOrders(cb, user, role, department));

        List<Tuple> rows = entityManager.createQuery(query)
                .setFirstResult((int) pageable.getOffset())
                .setMaxResults(pageable.getPageSize())
                .getResultList();

        List<EmployeeListItemResponse> result = new ArrayList<>(rows.size());

        for (Tuple row : rows) {
            String lastName = row.get("lastName", String.class);
            String firstName = row.get("firstName", String.class);
            String middleName = row.get("middleName", String.class);

            result.add(EmployeeListItemResponse.builder()
                    .userId(row.get("userId", UUID.class))
                    .fullName(buildFullName(lastName, firstName, middleName))
                    .login(row.get("login", String.class))
                    .roleId(row.get("roleId", UUID.class))
                    .roleName(row.get("roleName", String.class))
                    .isRoleActive(row.get("isRoleActive", Boolean.class))
                    .departmentId(row.get("departmentId", UUID.class))
                    .departmentName(row.get("departmentName", String.class))
                    .isDepartmentActive(row.get("isDepartmentActive", Boolean.class))
                    .isActive(row.get("isActive", Boolean.class))
                    .build());
        }

        return result;
    }

    private List<Predicate> buildCommonPredicates(
            CriteriaBuilder cb,
            Root<User> user,
            Root<Credential> credential,
            Root<UserRole> userRole,
            Root<Role> role,
            Root<DepartmentUser> departmentUser,
            Root<Department> department,
            Set<UUID> effectiveDepartmentIds,
            Set<UUID> roleIds,
            ActivityFilter activityFilter,
            List<String> searchTokens
    ) {
        List<Predicate> predicates = new ArrayList<>();

        predicates.add(cb.equal(credential.get("userId"), user.get("userId")));
        predicates.add(cb.equal(userRole.get("userId"), user.get("userId")));
        predicates.add(cb.equal(role.get("roleId"), userRole.get("roleId")));
        predicates.add(cb.equal(departmentUser.get("userId"), user.get("userId")));
        predicates.add(cb.equal(department.get("departmentId"), departmentUser.get("departmentId")));

        predicates.add(department.get("departmentId").in(effectiveDepartmentIds));

        if (roleIds != null && !roleIds.isEmpty()) {
            predicates.add(role.get("roleId").in(roleIds));
        }

        switch (activityFilter) {
            case ACTIVE -> predicates.add(cb.isTrue(user.get("isActive")));
            case INACTIVE -> predicates.add(cb.isFalse(user.get("isActive")));
            case ALL -> {
                // без фильтра
            }
        }

        if (searchTokens != null && !searchTokens.isEmpty()) {
            for (String token : searchTokens) {
                predicates.add(buildTokenPredicate(cb, user, credential, role, department, token));
            }
        }

        return predicates;
    }

    private Predicate buildTokenPredicate(
            CriteriaBuilder cb,
            Root<User> user,
            Root<Credential> credential,
            Root<Role> role,
            Root<Department> department,
            String token
    ) {
        String pattern = "%" + escapeLikePattern(token) + "%";

        List<Predicate> anyFieldMatches = new ArrayList<>();

        anyFieldMatches.add(ilike(cb, user.get("lastName").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, user.get("firstName").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, user.get("middleName").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, credential.get("login").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, role.get("name").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, department.get("name").as(String.class), pattern));
        anyFieldMatches.add(ilike(cb, department.get("shortName").as(String.class), pattern));

        return cb.or(anyFieldMatches.toArray(new Predicate[0]));
    }

    private Predicate ilike(CriteriaBuilder cb, Expression<String> expression, String pattern) {
        return cb.like(cb.lower(expression), pattern, '\\');
    }

    private List<Order> buildOrders(
            CriteriaBuilder cb,
            Root<User> user,
            Root<Role> role,
            Root<Department> department
    ) {
        Expression<Integer> activeOrder = cb.<Integer>selectCase()
                .when(cb.isTrue(user.get("isActive")), 1)
                .otherwise(0);

        return List.of(
                cb.desc(activeOrder),
                cb.asc(cb.lower(department.get("name").as(String.class))),
                cb.asc(cb.lower(role.get("name").as(String.class))),
                cb.asc(cb.lower(user.get("lastName").as(String.class))),
                cb.asc(cb.lower(user.get("firstName").as(String.class))),
                cb.asc(cb.lower(user.get("middleName").as(String.class))),
                cb.asc(user.get("userId"))
        );
    }

    private String escapeLikePattern(String value) {
        return value
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
    }

    private EmployeeListResponse buildEmptyResponse(Pageable pageable) {
        return EmployeeListResponse.builder()
                .items(List.of())
                .page(pageable.getPageNumber())
                .size(pageable.getPageSize())
                .totalElements(0)
                .totalPages(0)
                .hasNext(false)
                .build();
    }

    private String buildFullName(String lastName, String firstName, String middleName) {
        StringBuilder fullName = new StringBuilder();

        if (lastName != null && !lastName.isBlank()) {
            fullName.append(lastName.trim());
        }

        if (firstName != null && !firstName.isBlank()) {
            if (!fullName.isEmpty()) {
                fullName.append(" ");
            }
            fullName.append(firstName.trim());
        }

        if (middleName != null && !middleName.isBlank()) {
            if (!fullName.isEmpty()) {
                fullName.append(" ");
            }
            fullName.append(middleName.trim());
        }

        return fullName.toString();
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
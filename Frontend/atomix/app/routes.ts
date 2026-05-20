import { route, index } from "@react-router/dev/routes";

export default [
  index("routes/dashboard.tsx"),
  route("reports", "routes/reports.tsx"),
  route("reports/view", "routes/report-view.tsx"),
  route("templates", "routes/templates.tsx"),
  route("templates/editor", "routes/template-editor.tsx"),
  route("analytics", "routes/analytics.tsx"),
  route("employees", "routes/employees.tsx"),
  route("enterprise-structure", "routes/enterprise-structure.tsx"),
  route("role-system", "routes/role-system.tsx"),
  route("employees-modal","routes/employees-modal.tsx"),
  route("/login", "routes/login.tsx"),
  route("employees/edit/:id", "routes/editing.tsx")
];

export type Employee = {
  id: number;
  name: string;
  position: string;
  role: string;
  office: string;
  login?: string;
  isActive?: boolean;
  password?: string;
};

export type EmployeeInput = Omit<Employee, "id">;

/* ----------------------------- ADD ----------------------------- */

export const addEmployee = (
  employees: Employee[],
  employeeData: EmployeeInput
): Employee[] => {
  const maxId =
    employees.length > 0
      ? Math.max(...employees.map((employee) => employee.id))
      : 0;

  return [
    ...employees,
    {
      id: maxId + 1,
      ...employeeData,
    },
  ];
};

/* --------------------------- DELETE ---------------------------- */

export function deleteEmployee(
  employees: Employee[],
  id: number
): Employee[] {
  return employees.filter((employee) => employee.id !== id);
}

/* --------------------------- UPDATE ---------------------------- */

export function updateEmployee(
  employees: Employee[],
  id: number,
  updatedData: Partial<EmployeeInput>
): Employee[] {
  return employees.map((employee) =>
    employee.id === id ? { ...employee, ...updatedData } : employee
  );
}

/* --------------------------- SEARCH ---------------------------- */

export function searchEmployees(
  employees: Employee[],
  query: string
): Employee[] {
  const search = query.trim().toLowerCase();

  if (!search) return employees;

  return employees.filter((employee) => {
    return (
      String(employee.id).includes(search) ||
      employee.name.toLowerCase().includes(search) ||
      employee.position.toLowerCase().includes(search) ||
      employee.role.toLowerCase().includes(search) ||
      employee.office.toLowerCase().includes(search)
    );
  });
}

/* ----------------------------- INFO ----------------------------- */

export function getEmployeeInfo(employee: Employee): string {
  return `
Дополнительная информация:

№: ${employee.id}
ФИО: ${employee.name}
Должность: ${employee.position}
Роль доступа: ${employee.role}
Рабочее место: ${employee.office}
  `;
}
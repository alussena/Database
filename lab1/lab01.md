Part 1: Key Identification Exercises

Task 1.1:

1) .
1. EmpID
2. SSN
3. Email
4. EmpID, phone
5. SSN, Email
6. EmpID, Name, Department

2) Candidate Keys (мин.суперключи)
- EmpID
- SSN
- Email

3) Primary Key - EmpID
Unique, no personal information, stable, numeric, not null,

Relation B:
1) minimum attributes needed for the primary key - StudentID, CourseCode, Section, Semester, Year
2) StudentID - student who registered
CourseCode - which course
Section - course section
Semester, Year - to decide which year/semester
3) No, we have only one candidate key - StudentID, CourseCode, Section, Semester, Year

Task 1.2:

StudentProject(
    studentID,
    studentName,
    studentMajor,
    projectID,
    projectTitle,
    projectType,
    supervisorID,
    supervisorName,
    supervisorDept,
    Role,
    HoursWorked,
    StartDate,
    EndDate
)

Foreign Keys:
1. Student.AdvisorID -> Professor.ProfID
2. Professor.Department -> Department.DeptCode
3. Course.DepartmentCode -> Department.DeptCode
4. Department.ChairID -> Professor.ProfID
5. Enrollment.StudentID -> Student.StudentID
6. Enrollment.CourseID -> Course.CourseID

Part 4: Normalization Workshop

4.1: Denormalization Table Analysis

1. Functional Dependencies (FDs)
- StudentID -> StudentName, StudentMajor
- ProjectID -> ProjectTitle, ProjectType, SupervisorID
- SupervisorID - > SupervisorName, SupervisorID
- (StudentID, ProjectID) -> Role, HoursWorked, StartDate, EndDate
- ProjectID -> SupervisorName, SupervisorDept (supervisorID)

2. Problems (Redundancy & Anomalies)
- Redundancy: StudentName/StudentMajor
(повторяются для каждого проекта;)
ProjectTitle/Type & Supervisor данные повторяются для каждого студента
- Update anomaly: Изменения SupervisorName требует обновления во многих строках
- Insert anomaly: нельзя вставить новый проект без студента
- Delete anomaly: Удаление послед.студента (может удалить и все сведения о проекте)

3. 1NF
- нарушений нет (все значения атомарные)
- таблица находится в 1NF

4. 2NF
- PRIMARY KEY: StudentID, ProjectID
- Partial Dependencies:
    - StudentID -> StudentName, StudentMajor
    - projectID -> ProjectTitle, ProjectType, SupervisorID
- Decomposition (2NF):
    - student (StudentID, StudentName, StudentMajor)
    - supervisor (SupervisorID, SupervisorName, SupervisorDept)
    - project (ProjectID, ProjectTitle, ProjectType, SupervisorID)
StudentProject(StudentID, ProjectID, Role, HoursWorked, StartDate, EndDate)

5. 3NF
- Transitive Dependency: ProjectID -> SupervisorName, SupervisorDept -> SupervisorID
Final 3NF Schema:
- Student (StudentID PK, StudentName, StudentMajor)
- Supervisor (SupervisorID PK, SupervisorName, SupervisorDept)
- Project (ProjectID PK, ProjectTitle, ProjectType, SupervisorID FK)
- StudentProject (StudentID PK/FK, ProjectID PK/FK, Role, HoursWorked, StartDate, EndDate)

Task 4.2: Advanced Normalization
1. Primary Key
- PK: (StudentID, CourseID)
2. Functional Dependencies
- StudentID -> StudentMajor
- CourseID -> CourseName, InstructorID, TimeSlot, Room

- InstructorID -> InstructorName
- Room -> Building
- (StudentID, CourseID)
3. BCNF Check
- StudentID -> StudentMajor -- StudentID is not superkey => not BCNF
- Room -> Building -- Room is not superkey => not BCNF
- InstructorID -> InstructorName -- InstructorID is not a superkey => not BCNF
// The rable is not in BCNF
4. Decomposition to BCNF
- Student (StudentID PK, StudentMajor)
- Instructor (InstructorID PK, InstructorName)
- Room (Room PK, Building)
- CourseSection (CourseID PK, CourseName, InstructorID FK, TimeSlot, Room FK)
- Enrollments (StudentID PK/FK, CourseID PK/FK)
5. Loss of Information
- Декомпозиция lossless: пересечение таблиц содержат ключи (StudentID, courseID, InstructorID, Room)
- Все функциональные зависимости сохранены: 
    - StudentID -> Major (в Student)
    - CourseID -> CourseName, InstructorID, TimeSlot, Room (в CourseSection)
    - InstructorID -> Name
    - Room -> Building

Part 5: Design Challenge
Task 5.1: Real-World Application

set serveroutput on

set echo on

spool t:setup.txt

/* ----- Kevin Wu 012977482 ----- */


/* ----- IS 480 Advanced Database Project ----- */


/* --- Create tables and insert test data --- */

drop table enrollments;
drop table prereq;
drop table schclasses;
drop table courses;
drop table students;
drop table majors;



create table MAJORS
	(major varchar2(5) Primary key,
	mdesc varchar2(30));

insert into majors values ('ACC','Accounting');
insert into majors values ('FIN','Finance');
insert into majors values ('IS','Information Systems');
insert into majors values ('MKT','Marketing');


create table STUDENTS 
	(snum varchar2(4) primary key,
	sname varchar2(10),
	standing number(1),
	major varchar2(5) constraint fk_students_major references majors(major),
	gpa number(2,1),
	major_gpa number(2,1));

insert into students values ('101','Andy',3,'IS',2.8,3.2);
insert into students values ('102','Betty',2,null,3.2,null);
insert into students values ('103','Cindy',3,'IS',2.5,3.5);
insert into students values ('104','David',2,'FIN',3.3,3.0);
insert into students values ('105','Ellen',1,null,2.8,null);
insert into students values ('106','Frank',3,'MKT',3.1,2.9);


create table COURSES
	(dept varchar2(4) constraint fk_courses_dept references majors(major),
	cnum varchar2(4),
	ctitle varchar2(30),
	crhr number(3),
	standing number(1),
	primary key (dept,cnum));

insert into courses values ('IS','300','Intro to MIS',3,2);
insert into courses values ('IS','301','Business Communicatons',3,2);
insert into courses values ('IS','310','Statistics',3,2);
insert into courses values ('IS','340','Programming',3,3);
insert into courses values ('IS','380','Database',3,3);
insert into courses values ('IS','385','Systems',3,3);
insert into courses values ('IS','480','Adv Database',3,4);


create table SCHCLASSES (
	callnum number(5) primary key,
	year number(4),
	semester varchar2(3),
	dept varchar2(4),
	cnum varchar2(4),
	section number(2),
	capacity number(3));

alter table schclasses 
	add constraint fk_schclasses_dept_cnum foreign key 
	(dept, cnum) references courses (dept,cnum);

insert into schclasses values (10110,2014,'Fa','IS','300',1,45);
insert into schclasses values (10115,2014,'Fa','IS','300',2,118);
insert into schclasses values (10120,2014,'Fa','IS','300',3,35);
insert into schclasses values (10125,2014,'Fa','IS','301',1,35);
insert into schclasses values (10130,2014,'Fa','IS','301',2,35);
insert into schclasses values (10135,2014,'Fa','IS','310',1,35);
insert into schclasses values (10140,2014,'Fa','IS','310',2,35);
insert into schclasses values (10145,2014,'Fa','IS','340',1,30);
insert into schclasses values (10150,2014,'Fa','IS','380',1,33);
insert into schclasses values (10155,2014,'Fa','IS','385',1,35);
insert into schclasses values (10160,2014,'Fa','IS','480',1,35);


create table PREREQ
	(dept varchar2(4),
	cnum varchar2(4),
	pdept varchar2(5),
	pcnum varchar2(5),
	primary key (dept, cnum, pdept, pcnum));
alter table Prereq 
	add constraint fk_prereq_dept_cnum foreign key 
	(dept, cnum) references courses (dept,cnum);
alter table Prereq 
	add constraint fk_prereq_pdept_pcnum foreign key 
	(pdept, pcnum) references courses (dept,cnum);

insert into prereq values ('IS','380','IS','300');
insert into prereq values ('IS','380','IS','301');
insert into prereq values ('IS','380','IS','310');
insert into prereq values ('IS','385','IS','310');
insert into prereq values ('IS','340','IS','300');
insert into prereq values ('IS','480','IS','380');


create table ENROLLMENTS (
	snum varchar2(4) constraint fk_enrollments_snum references students(snum),
	callnum number(5) constraint fk_enrollments_callnum references schclasses(callnum),
	grade varchar2(5),
	primary key (snum, callnum));

insert into enrollments values (101,10110,'A');
insert into enrollments values (102,10110,'B');
insert into enrollments values (103,10120,'A');
insert into enrollments values (101,10125,null);
insert into enrollments values (102,10130,null);

drop table waitlist;

create table WAITLIST (
	snum varchar2(4),
	callnum number(5),
	request_time date );

commit;


/* ----- Create ENROLL package ----- */

-- Package Specification
Create or Replace Package ENROLL as

-- Validate snum
Function Validate_Snum (
	p_snum students.snum%type )
	return varchar2;

-- Validate callnum
Function Validate_Callnum ( 
	p_callnum schclasses.callnum%type )
	return varchar2;

-- Check enrollment
Function Repeat_Enrollment (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- Check for double enrollment
Function Double_Enrollment (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- 15 hour rule
Procedure TotalCreditHours_AtMost15 (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 );

-- Check standing
Function Standing_Requirement (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- Validate prereq
Function Validate_Prereq (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- Check capacity
Procedure Available_Room (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 );

-- Waitlist/Repeat Waitlist
Procedure Repeat_Waitlist (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 );

-- AddMe procedure
Procedure AddMe (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorMsg OUT varchar2 );



-- Validate student Done

-- Not enrolled
Function Not_Enrolled (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- Already graded
Function Already_Graded (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2;

-- DropMe procedure
Procedure DropMe (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type );

End ENROLL;
/


-- Package Body
Create or Replace Package Body ENROLL as

-- Validate snum
Function Validate_Snum (
	p_snum students.snum%type )
	return varchar2 as

	v_count number;
begin
	select count(*) into v_count from students
		where snum = p_snum;

	If v_count = 0 Then
		dbms_output.put_line ('Student number is invalid');
		Return 'Invalid SNum';
	Else
		dbms_output.put_line ('Student number is valid');
		Return null;
	End If;
end;

-- Validate callnum
Function Validate_Callnum (
	p_callnum schclasses.callnum%type )
	return varchar2 as
	
	v_count number;
begin
	select count(*) into v_count from schclasses
		where callnum = p_callnum;

	If v_count = 0 Then
		dbms_output.put_line ('Call number is invalid');
		Return 'Invalid CallNum';
	Else
		dbms_output.put_line ('Call number is valid');
		Return null;
	End If;
end;

-- Repeat enrollment
Function Repeat_Enrollment (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2 as

	v_count number;
begin
	select count(*) into v_count from enrollments
		where snum = p_snum
		and callnum = p_callnum;

	If v_count = 0 Then
		dbms_output.put_line ('Enrollment valid');
		Return null;
	Else
		dbms_output.put_line ('Enrollment repeated');
		Return 'Repeat Enrollment';
	End If;
end;

-- Double enrollment
Function Double_Enrollment (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2 as

	v_dept varchar2(100);
	v_cnum varchar2(100);
	v_count number;
begin
	select dept, cnum into v_dept, v_cnum 
		from schclasses
		where callnum = p_callnum;

	select count(*) into v_count
		from enrollments e, schclasses sch
		where e.callnum = sch.callnum
		and dept = v_dept
		and cnum = v_cnum
		and snum = p_snum;

	If v_count = 0 Then
		dbms_output.put_line ('Enrollment valid');
		Return null;
	Else
		dbms_output.put_line ('Double enrollment');
		Return 'Double Enrollment';
	End If;
end;

-- 15 hour rule
Procedure TotalCreditHours_AtMost15 (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 ) as

	v_CrHr_ToAdd number;
	v_CrHr_Enrolled number;
begin
	select crhr into v_CrHr_ToAdd 
		from schclasses sch, courses c
		where callnum = p_callnum
		and sch.dept = c.dept
		and sch.cnum = c.cnum;

	select nvl(sum(crhr), 0) into v_CrHr_Enrolled 
		from schclasses sch, courses c, enrollments e
		where snum = p_snum
		and sch.callnum = e.callnum
		and sch.cnum = c.cnum
		and sch.dept = c.dept;

	If v_CrHr_ToAdd + v_CrHr_Enrolled <= 15 Then
		dbms_output.put_line ('15 hour rule valid');
		p_ErrorTxt := null;
	Else
		dbms_output.put_line ('15 hour rule invalid');
		p_ErrorTxt := 'Over Credit Hours';
	End If;
end;

-- Check Standing
Function Standing_Requirement (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2 as

	v_s_standing number;
	v_c_standing number;
begin
	select standing into v_s_standing from students
		where snum = p_snum;

	select standing into v_c_standing 
		from schclasses sch, courses c
		where callnum = p_callnum
		and sch.cnum = c.cnum
		and sch.dept = c.dept;

	If v_s_standing >= v_c_standing Then
		dbms_output.put_line ('Standing valid');
		Return null;
	Else
		dbms_output.put_line ('Standing invalid');
		Return 'Invalid Standing';
	End If;
end;

-- Validate Prereq
Function Validate_Prereq (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type) 
	return varchar2 as
	
	v_dept varchar2(200);
	v_cnum varchar2(200);
	v_prereqnum number;
	v_prereq number;
	v_pass varchar2(200);

begin

	select dept into v_dept
	from schclasses
	where callnum = p_callnum;
	
	select cnum into v_cnum
	from schclasses
	where callnum = p_callnum;
	
	select count(*) into v_prereqnum
	from prereq
	where dept = v_dept
	and cnum = v_cnum;

	select count(*) into v_prereq
	from schclasses sch, enrollments e, prereq pr
	where pr.dept = v_dept
	and pr.cnum = v_cnum
	and snum = p_snum
	and e.callnum = sch.callnum
	and pr.dept = sch.dept
	and pr.cnum = sch.cnum
	and grade in ('A', 'B', 'C', 'D');
	
	If v_prereqnum - v_prereq = 0 THEN
		v_pass := null;
	Else
		v_pass := 'Prerequisites have not been met';
	End if;
	
	return v_pass;

end;



-- Check capacity
Procedure Available_Room (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 ) as

	v_cap schclasses.capacity%type;
	v_count number;
begin
	select capacity into v_cap from schclasses
		where callnum = p_callnum;

	select count(snum) into v_count
		from enrollments
		where callnum = p_callnum and nvl(grade, 'Undeclared') != 'W';

	If v_cap > v_count Then
		dbms_output.put_line ('Room available');
		p_ErrorTxt := null;
	Else
		dbms_output.put_line ('Room unavailable');
		p_ErrorTxt := 'Unavailable Room';
	End If;
end;


-- Waitlist/Repeat Waitlist
Procedure Repeat_Waitlist (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorTxt OUT varchar2 ) as

	v_count number;
begin
	select count(*) into v_count from waitlist
		where snum = p_snum
		and callnum = p_callnum;
	
	If v_count = 0 Then
		dbms_output.put_line ('Waitlist valid');
		p_ErrorTxt := null;
	Else
		dbms_output.put_line ('Repeat waitlist');
		p_ErrorTxt := 'Repeat Waitlist';
	End If;
end;



-- AddMe procedure
Procedure AddMe (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type,
	p_ErrorMsg OUT varchar2 ) as

	v_error_Snum varchar2(200);
	v_error_Callnum varchar2(200);
	v_error_Repeat varchar2(200);
	v_error_Double varchar2(200);
	v_error_CrHr varchar2(200);
	v_error_Standing varchar2(200);
	v_error_Prereq varchar2(200);
	v_error_Cap varchar2(200);
	v_error_RepeatWait varchar2(200);
begin
	-- Checking requirement 1
	v_error_Snum := Validate_Snum (p_snum);
	v_error_Callnum := Validate_Callnum (p_callnum);

	IF v_error_Snum is null and v_error_Callnum is null THEN
		p_ErrorMsg := null;

		v_error_Repeat := Repeat_Enrollment (p_snum, p_callnum);
		v_error_Double := Double_Enrollment (p_snum, p_callnum);
		TotalCreditHours_AtMost15 (p_snum, p_callnum, v_error_CrHr);
		v_error_Standing := Standing_Requirement (p_snum, p_callnum);
		
		If v_error_Repeat is null and v_error_Double is null and
		   v_error_CrHr is null and v_error_Standing is null and
		   v_error_Prereq is null Then
			p_ErrorMsg := null;

			Available_Room (p_snum, p_callnum, v_error_Cap);
			if v_error_Cap is null then
				p_ErrorMsg := null;

				insert into enrollments
					values (p_snum, p_callnum, null);
				dbms_output.put_line ('Congrats; Student number '||p_snum||' is successfully enrolled in course number '||p_callnum||'.');
				commit;
					
			else
				Repeat_Waitlist (p_snum, p_callnum, v_error_RepeatWait);
				if v_error_RepeatWait is null then
					p_ErrorMsg := null;
					insert into waitlist
						values (p_snum, p_callnum, sysdate);
					dbms_output.put_line ('Student number '||p_snum||' is now on the waiting list for class number '||p_callnum||'.');
					commit;
				end if;
			end if;
		End If;
	END IF;
end;



----

-- Validate student Checked

-- Not enrolled
Function Not_Enrolled (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2 as

	v_count number;
begin
	select count(*) into v_count from enrollments
		where snum = p_snum 
		and callnum = p_callnum;

	If v_count = 0 Then
		dbms_output.put_line ('Student is not enrolled yet; cannot drop');
		Return 'Not Enrolled';
	Else
		dbms_output.put_line ('Student enrolled');
		Return null;
	End If;
end;

-- Already graded
Function Already_Graded (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type )
	return varchar2 as

	v_count number;
begin
	select count(grade) into v_count from enrollments
		where snum = p_snum
		and callnum = p_callnum;

	If v_count = 0 Then
		dbms_output.put_line ('Not graded yet');
		Return null;
	Else
		dbms_output.put_line ('Already graded, the student cannot drop');
		Return 'Already Graded';
	End If;
end;


-- DropMe procedure
Procedure DropMe (
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type ) as
	
	v_error_Snum varchar2(200);
	v_error_Callnum varchar2(200);
	v_error_NotEnrolled varchar2(200);
	v_error_Graded varchar2(200);
	v_error_Prereq varchar2(200);
	v_ErrorMsg varchar2(200);
begin
	v_error_Snum := Validate_Snum (p_snum);
	v_error_Callnum := Validate_Callnum (p_callnum);

	IF v_error_Snum is null and v_error_Callnum is null THEN

		v_error_NotEnrolled := Not_Enrolled (p_snum, p_callnum);
		v_error_Graded := Already_Graded (p_snum, p_callnum);

		If v_error_NotEnrolled is null and v_error_Graded is null Then
			update enrollments en set grade = 'W'
				where p_snum = en.snum and p_callnum = en.callnum;
			dbms_output.put_line ('Student number '||p_snum||' is successfully dropped from course number '||p_callnum||'.');
			commit;

			FOR eachstudent IN (
				select snum, callnum, request_time
				from waitlist
				where callnum = p_callnum
				order by request_time ) LOOP
				
				dbms_output.put_line ('New student number '||eachstudent.snum||' is waiting for course number '||eachstudent.callnum||'.');
				AddMe (eachstudent.snum, eachstudent.callnum, v_ErrorMsg);

				if v_ErrorMsg is null then
					delete from waitlist
						where snum = eachstudent.snum
						and callnum = eachstudent.callnum;
					commit;
					exit;
				end if;
			END LOOP;
		End If;
	END IF;
end;


End ENROLL;
/

spool off

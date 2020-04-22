-- comp9311 19T3 Project 1
--
-- MyMyUNSW Solutions


-- Q1:
create or replace view Q1(unswid, longname)
as
select distinct r.unswid,r.longname from rooms  r 
inner join room_facilities rf on r.id = rf.room 
inner join facilities f on rf.facility = f.id 
where f.description = 'Air-conditioned';
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q2:
create or replace view Q2(unswid,name)
as 
select distinct p.unswid,p.name from course_enrolments ce 
inner join course_staff cs on ce.course = cs.course 
inner join people p on cs.staff = p.id 
where ce.student = (select id from people where name = 'Hemma Margareta');
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q3:
create or replace view Q3_9311(unswid, name,semester)
as 
select p.unswid,p.name,c.semester from people p 
inner join students s on p.id=s.id 
inner join course_enrolments ce on s.id=ce.student 
inner join courses c on ce.course=c.id 
inner join subjects su on c.subject = su.id 
where su.code='COMP9311' and ce.grade='HD' and s.stype='intl';

create or replace view Q3_9024(unswid, name,semester)
as 
select p.unswid,p.name,c.semester from people p 
inner join students s on p.id=s.id 
inner join course_enrolments ce on s.id=ce.student 
inner join courses c on ce.course=c.id 
inner join subjects su on c.subject = su.id 
where su.code='COMP9024' and ce.grade='HD' and s.stype='intl';

create or replace view Q3(unswid, name)
as 
select distinct a.unswid,a.name from Q3_9311 a,Q3_9024 b 
where a.term=b.term and a.unswid=b.unswid;
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q4:
create or replace view Q4_HD(student,course,grade)
as
select student,course,grade from course_enrolments 
where grade='HD';

create or replace view Q4_HD_num(student,num_of_hd)
as
select distinct student,count(grade) from Q4_HD group by student;

create or replace view Q4_new(student, num)
as
select distinct ce.student, coalesce(a.num_of_hd,0) from course_enrolments ce 
left join Q4_HD_num a on ce.student = a.student;

create or replace view Q4_avg(avg)
as
select avg(num) from Q4_new;

create or replace view Q4(num_student)
as
select  count(a.student) from Q4_HD_num a,Q4_avg b where a.num_of_hd > b.avg;
--... SQL statements, possibly using other views/functions defined by you ...
;

--Q5:
create or replace view Q5_max(semester, course, max_mark)
as
select c.semester,c.id,max(ce.mark) from courses c, course_enrolments ce ,semesters se
where ce.course=c.id, c.semester=se.id
group by c.semester,c.id
having count(ce.mark is not null)>=20;

create or replace view Q5_min(semester, mark)
as
select semester,min(max_mark) from Q5_max
where max_mark is not null
group by semester;


create or replace view Q5_min_course(semester,course)
as
select a.semester,a.course from Q5_max a and Q5_min b
where a.semester = b.semester and a.max_mark=b.mark;

create or replace view Q5(code, name, semester)
as
select su.code,su.name,se.name from courses c,subjects su,semesters se,Q5_min_course a
where a.semester=se.id and a.course=c.id and c.subject=su.id and c.semester=se.id;

--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q6:
create or replace view Q6_management(student)
as
select distinct pe.student from semesters see inner join program_enrolments pe on see.id = pe.semester inner join stream_enrolments se on pe.id = se.partof inner join streams s on se.stream=s.id where s.name ='Management' and see.year = '2010' and see.term= 'S1';

create or replace view Q6_FOE(student)
as
select distinct ce.student from course_enrolements ce inner join courses c  on ce.course=c.id inner join subjects s on s.id = c.subject inner join orgunits o on s.offeredby = o.id where o.name ='Faculty of Engineering';

create or replace view Q6_left(student)
as
select * from Q6_management 
except
select * from Q6_FOE;

create or replace view Q6(num)
as
select count(student) from Q6_left a 
inner join students s on a.student = s.id 
where s.stype='local';
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q7:
create or replace view Q7_ytm(year, term,mark)
as
select s.year,s.term,ce.mark from semesters s, courses c, subjects su, course_enrolments ce where s.id = c.semester and su.id = c.subject and ce.course = c.id and su.name = 'Database Systems' and ce.mark is not null;

create or replace view Q7(year, term, average_mark)
as
select a.year,a.term,AVG(a.mark) :: numeric (4,2) as average from Q7_ytm a group by a.year,a.term order by a.year;
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q8: 
create or replace view Q8_semester(id, year, term)
as
select id,year,term from semester where year >=2004 and year <=2013  and term like 'S%' ;

create or replace view Q8_courses(id, subject)
as
select c.id,c.subject,su.code,s.year,s.term from Q8_semester s,courses c, subjects su 
where c.subject = su.id and s.id = c.semester and su.code like 'COMP93%';

create or replace view Q8_count(subject, count)
as
select subject ,count(code) as count from Q8_courses group by subject;

create or replace view Q8_two(subject)
as
select subject from Q8_count where count = 20;

create or replace view Q8_4899(zid, name,mark)
as
select p.unswid,p.name,ce.mark from courses c 
inner join course_enrolments ce on c.id=ce.course 
inner join people p on ce.student=p.id 
where c.subject = 4899
and (ce.mark is not null)<50;

create or replace view Q8_4897(zid, name,mark)
as
select p.unswid,p.name,ce.mark from courses c 
inner join course_enrolments ce on c.id=ce.course 
inner join people p on ce.student=p.id 
where c.subject = 4899
and ce.mark <50;

create or replace view Q8(zid, name)
as
select concat('z',p.unswid),p.name from Q8_4899 p
where p.mark is not null 
intersect
select 'z'+p.unswid,p.name from Q8_4897 p
where p.mark is not null; 
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q9:
create or replace view Q9_bsc(id, name)
as
select distinct p.id,p.name from program_degrees pd 
inner join program_enrolments pe on pe.program=pd.program 
inner join people p on p.id = pe.student 
inner join course_enrolments ce on p.id = ce.student 
inner join courses c on ce.course=c.id 
inner join semesters s on c.semester=s.id 
where pd.abbrev='BSc' and s.year = 2010 and s.term = 'S2' and ce.mark >= 50 and pe.semester = s.id;

create or replace view Q9_avg(id, avg)
as
select p.id,Avg(ce.mark) as average from people p 
inner join course_enrolments ce on p.id=ce.student
inner join courses c on c.id = ce.course
inner join semesters s on c.semester=s.id
where s.year <2011 and ce.mark >=50;
group by p.unswid
having avg(ce.mark)>=80;

create or replace view Q9_intersect(id)
as
select unswid from Q9_bsc
intersect
select unswid from Q9_avg;


create or replace view Q9_earn(id,code,uoc,program)
as
select a.id,su.code,su.uoc,pe.program from Q9_intersect a, program_enrolments pe, subjects su,
course_enrolments ce,courses c,semesters s
where pe.student=a.id and a.id=ce.student and ce.course =c.id and c.subject = su.id
and c.semester=s.id and s.year <2011 and ce.mark >=50 and pe.semester = s.id; 

create or replace view Q9_sum(id,sum,program)
as
select id, sum(uoc) as sum, program from Q9_earn
group by id,program; 

create or replace view Q9_program(id,uoc,program)
as 
select a.id,p.uoc,p.id from Q9_intersect a, program_enrolments pe,programs p 
where a.id=pe.student and p.program=p.id;

create or replace view Q9_compare(id)
as
select id from Q9_sum a,Q9_program b 
where a.id=b.id and a.program=b.program and a.sum >=b.uoc;

create or replace view Q9(unswid, name)
as
select p.unswid,p.name from Q9_compare a
inner join people p on a.id = p.id; 
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q10:
create or replace view Q10_room(id, unswid, longname)
as
select r.id,r.unswid,r.longname from rooms r 
inner join room_types rt on r.rtype = rt.id 
where rt.description = 'Lecture Theatre';

create or replace view Q10_class(rid, runswid, clid)
as
select r.id,r.unswid,cl.id from rooms r inner join classes cl on r.id = cl.room 
inner join courses co on cl.course = co.id 
inner join semesters s on co.semester = s.id 
where s.year = '2011' and s.term = 'S1';

create or replace view Q10_countcls(rid, count)
as
select rid,count(clid) as num from Q10_class group by rid;

create or replace view Q10_num(unswid, longname, num)
as
select  r.unswid,r.longname,coalesce(a.count,0) as num from Q10_room r left join Q10_countcls a on r.id =a.rid;

create or replace view Q10(unswid, longname, num, rank)
as
select unswid,longname,num,rank() over(order by num desc) as rank from Q10_num;
--... SQL statements, possibly using other views/functions defined by you ...
;

insert into public.chapters (chapter_number, chapter_name, description, published)
values
(1, 'Real Numbers', 'Learn the fundamental concepts of real numbers.', true),
(2, 'Polynomials', 'Understand polynomials through short and simple lessons.', true),
(3, 'Pair of Linear Equations', 'Learn methods for solving pairs of linear equations.', true),
(4, 'Quadratic Equations', 'Master quadratic equations step by step.', true),
(5, 'Arithmetic Progressions', 'Learn arithmetic progressions with quick examples.', true)
on conflict (chapter_number) do nothing;

insert into public.courses (course_name, description, price, premium, published)
select 'Class 10 Mathematics', 'Complete Class 10 Mathematics course with short video lessons.', 499, true, true
where not exists (select 1 from public.courses where course_name = 'Class 10 Mathematics');

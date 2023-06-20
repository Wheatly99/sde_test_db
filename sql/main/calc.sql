-- 0. Создать таблицу results c атрибутами id (INT), response (TEXT)
create table results (
id INT,
response TEXT
)
;

-- 1. Максимальное число бронирований
insert into results(id, response)
values (1, (select max(a.count_bookings) as Максимальное_число_бронирований
			from (
				select book_ref
					  ,count(passenger_id) as count_bookings
				from bookings.tickets
				group by book_ref
				
				) as a))
;

-- 2. Количество бронирований с количеством людей больше среднего значения людей на одно бронирование
insert into results(id, response)
values(2, (select count(distinct a.book_ref) as Количество
			from (
				select book_ref
					  ,count(passenger_id) as count_bookings
				  	  ,avg(count(passenger_id)) over() as average
				from bookings.tickets
				group by book_ref
				) as a
			where a.count_bookings > a.average)
			)
;

-- 3. Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?
insert into results(id, response)
values(3, (select sum(f.count) as count
			from (
				select cast((count(q.book_ref) > 1) as int) as count
				from (
					select t.book_ref
						  ,string_agg(t.passenger_id, ' ') as passangers
					from
						(
						select *
						from bookings.tickets
						where book_ref in (
											select book_ref
											from bookings.tickets
											group by book_ref
											having count(passenger_id) = 
																	(
																	select max(a.count_bookings)
																	from (
																		select b.book_ref
																			  ,count(t.ticket_no) as count_bookings
																		from bookings.bookings b
																			inner join bookings.tickets t
																				on b.book_ref = t.book_ref
																		group by b.book_ref
																		
																		) as a
																	)
										  )
						order by passenger_id
						) as t
					group by t.book_ref
					) as q
				group by q.passangers
				) as f))
;

-- 4. Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3
insert into results
select 4, concat(a.book_ref, '|', a.passenger_id, '|', a.passenger_name, '|', a.email, '|', a.phone)
from (
	select book_ref
		  ,passenger_id 
		  ,passenger_name 
		  ,cast(contact_data::json->'email' as text) as email
		  ,cast(contact_data::json->'phone' as text) as phone
	from bookings.tickets
	where book_ref in (
					  select book_ref 
					  from bookings.tickets
					  group by book_ref
					  having count(passenger_id) = 3
					  )
	order by book_ref, passenger_id, passenger_name, email, phone
	) as a
;

-- 5. Вывести максимальное количество перелётов на бронь
insert into results(id, response)
values(5, (select MAX(f.count) as Максимальное_количество_на_бронь
			from
				(
				select a.book_ref
					  ,count(b.ticket_no) as count
				from bookings.tickets a
					full outer join bookings.ticket_flights b
						on a.ticket_no = b.ticket_no
				group by a.book_ref
				) as f)
				)
;

-- 6. Вывести максимальное количество перелётов на пассажира в одной брони
insert into results(id, response)
values(6, (select max(f.count) as Максимальное_количество
			from
				(
				select a.book_ref
					  ,a.passenger_id
					  ,count(b.ticket_no) as count
				from bookings.tickets a
					full outer join bookings.ticket_flights b
						on a.ticket_no = b.ticket_no
				group by a.book_ref, a.passenger_id
				) as f)
				)
;

-- 7. Вывести максимальное количество перелётов на пассажира
insert into results(id, response)
values(7, (select max(f.count) as Максимальное_количество
			from
				(
				select a.passenger_id
					  ,count(b.ticket_no) as count
				from bookings.tickets a
					full outer join bookings.ticket_flights b
						on a.ticket_no = b.ticket_no
				group by a.passenger_id
				) as f)
				)
;

-- 8. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
insert into results
select 8, concat(q.passenger_id, '|', q.passenger_name, '|', q.email, '|', q.phone, '|', q.sum_flights)
from
	(
	select a.passenger_id
		  ,a.passenger_name 
		  ,cast(a.contact_data::json->'email' as text) as email
	  ,cast(a.contact_data::json->'phone' as text) as phone
	  ,sum(b.amount) as sum_flights
	from bookings.tickets a
		full outer join bookings.ticket_flights b
			on a.ticket_no = b.ticket_no
	group by a.passenger_id, a.passenger_name, a.contact_data
	having sum(b.amount) = (select min(f.summa)
							from
								(
								select sum(b.amount) as summa
								from bookings.tickets a
									full outer join bookings.ticket_flights b
										on a.ticket_no = b.ticket_no
								group by a.passenger_id
								) as f)
	order by a.passenger_id, a.passenger_name, email, phone
	) as q
;

-- 9. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах, для пассажира, который провёл максимальное время в полётах
insert into results
select 9, concat(q.passenger_id, '|', q.passenger_name, '|', q.email, '|', q.phone, '|', q.full_time)
from
	(
	select a.passenger_id
		  ,a.passenger_name 
		  ,cast(a.contact_data::json->'email' as text) as email
		  ,cast(a.contact_data::json->'phone' as text) as phone
		  ,sum(c.actual_arrival - c.actual_departure) as full_time
	from bookings.tickets a
		left join bookings.ticket_flights b
			on a.ticket_no = b.ticket_no
		left join bookings.flights c
			on b.flight_id = c.flight_id
	group by a.passenger_id, a.passenger_name, a.contact_data
	having sum(c.actual_arrival - c.actual_departure) = 
														(
														select max(f.full_time) as full_time
														from
															(
															select sum(c.actual_arrival - c.actual_departure) as full_time
															from bookings.tickets a
																left join bookings.ticket_flights b
																	on a.ticket_no = b.ticket_no
																left join bookings.flights c
																	on b.flight_id = c.flight_id
															group by a.passenger_id
															) as f
														)
	order by a.passenger_id, email, phone
	) as q
;

-- 10. Вывести город(а) с количеством аэропортов больше одного
insert into results
select 10, city
from bookings.airports
group by city
having count(city) > 1
order by city
;

-- 11. Вывести город(а), у которого самое меньшее количество городов прямого сообщения
insert into results
select 11, a.city
from bookings.flights f
	left join bookings.airports a
		on f.departure_airport = a.airport_code 
group by a.city 
having count(distinct f.arrival_airport) = (
										select min(a.count)
										from
											(
											select departure_airport
												  ,count(distinct arrival_airport) as count
											from bookings.flights
											group by departure_airport
											) as a
											)
order by city
;

-- 12. Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
insert into results
select 12, concat(f.airoport_dep, '|', f.airoport_arr)
from
	(
	select z.airoport_dep
		  ,z.airoport_arr
	from
		(
		select a.city as airoport_dep, b.city as airoport_arr
		from bookings.airports a
			cross join bookings.airports b
		
		except
		
		select distinct departure_city, arrival_city
		from bookings.flights_v
		) as z
	where z.airoport_dep <= z.airoport_arr
	
	union
	
	select z.airoport_arr
		  ,z.airoport_arr
	from
		(
		select a.city as airoport_dep, b.city as airoport_arr
		from bookings.airports a
			cross join bookings.airports b
		
		except
		
		select distinct departure_city, arrival_city
		from bookings.flights_v
		) as z
	where z.airoport_dep > z.airoport_arr
	) as f
where f.airoport_dep != f.airoport_arr
order by f.airoport_dep, f.airoport_arr
;

-- 13. Вывести города, до которых нельзя добраться без пересадок из Москвы?
insert into results
select 13, *
from
	(
	select distinct arrival_city
	from bookings.flights_v
	where arrival_city in (
						  select arrival_city
						  from bookings.flights_v
						  group by arrival_city
						  having count(distinct departure_city) = 1
						  )
		and departure_city = 'Москва'
	order by arrival_city
	) as f
;

-- 14. Вывести модель самолета, который выполнил больше всего рейсов
insert into results
select 14, a.model
from bookings.flights f
	left join bookings.aircrafts a
		on f.aircraft_code = a.aircraft_code
where f.status = 'Arrived'
	or f.status = 'Departed'
group by a.model
order by count(*) desc
limit 1
;

-- 15. Вывести модель самолета, который перевез больше всего пассажиров
insert into results
select 15, a.model
from bookings.flights f
	left join bookings.aircrafts a
		on f.aircraft_code = a.aircraft_code
	right join bookings.ticket_flights tf 
		on f.flight_id = tf.flight_id
	left join bookings.tickets t
		on t.ticket_no = tf.ticket_no
where f.status = 'Arrived'
	or f.status = 'Departed'
group by a.model
order by count(t.passenger_id) desc
limit 1
;

-- 16. Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
insert into results
select 16, cast(extract(epoch from sum((actual_arrival - actual_departure) - (scheduled_arrival - scheduled_departure)))/60 as int)
from bookings.flights
where actual_arrival is not null
;

-- 17. Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13
select arrival_city
from bookings.flights_v
where to_char(scheduled_arrival, 'YYYY-MM-DD') = '2016-09-13'
	and departure_city = 'Санкт-Петербург'
order by arrival_city
;
-- В п.17 нет строк, внесем напрямую в таблицу
insert into results(id, response)
values(17, 0)
;

-- 18. Вывести перелёт(ы) с максимальной стоимостью всех билетов
insert into results
select 18, f.flight_id
from bookings.flights f
	inner join bookings.ticket_flights tf
		on f.flight_id = tf.flight_id
group by f.flight_id
having sum(tf.amount) =
					(
					select max(summa)
					from
						(
						select sum(tf.amount) as summa
						from bookings.flights f
							inner join bookings.ticket_flights tf
								on f.flight_id = tf.flight_id
						group by f.flight_id
						) as f
					)
;

-- 19. Выбрать дни в которых было осуществлено минимальное количество перелётов
insert into results
select 19, to_char(scheduled_arrival, 'YYYY-MM-DD') as data
from bookings.flights
where status = 'Arrived'
group by to_char(scheduled_arrival, 'YYYY-MM-DD')
having count(flight_id) = 
							(
							select min(f.cnt)
							from
								(
								select count(flight_id) as cnt
								from bookings.flights
								where status = 'Arrived'
								group by to_char(scheduled_arrival, 'YYYY-MM-DD')
								) as f
							)
;

-- 20. Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года
insert into results
select 20, coalesce(avg(f.cnt), 0)
from
	(
	select to_char(scheduled_departure, 'YYYY-MM-DD')
		  ,count(distinct flight_id) as cnt
	from bookings.flights_v
	where departure_city = 'Москва'
		and	(status = 'Departed'
			or status = 'Arrived')
		and date_part('month', scheduled_departure) = 9
		and date_part('year', scheduled_departure) = 2016
	group by to_char(scheduled_departure, 'YYYY-MM-DD')
	) as f
;

-- 21. Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
insert into results
select 21, f.departure_city
from
	(
	select departure_city
	from bookings.flights_v
	group by departure_city
	order by avg(extract(epoch from (scheduled_arrival - scheduled_departure))/3600) desc
	limit 5
	) as f
order by f.departure_city
;

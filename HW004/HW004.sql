DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамиль', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	phone BIGINT UNSIGNED UNIQUE, 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'юзеры';

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100)
	
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE -- (значение по умолчанию)
    ON DELETE RESTRICT; -- (значение по умолчанию)

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL, -- изменили на составной ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'declined', 'unfriended'), # DEFAULT 'requested',
    -- `status` TINYINT(1) UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, -- можно будет даже не упоминать это поле при обновлении
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)-- ,
    -- CHECK (initiator_user_id <> target_user_id)
);
-- чтобы пользователь сам себе не отправил запрос в друзья
ALTER TABLE friend_requests 
ADD CHECK(initiator_user_id <> target_user_id);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	
	INDEX communities_name_idx(name), -- индексу можно давать свое имя (communities_name_idx)
	FOREIGN KEY (admin_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL,
    name VARCHAR(255), -- записей мало, поэтому в индексе нет необходимости
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body VARCHAR(255),
    filename VARCHAR(255),
    -- file BLOB,    	
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

-- DROP TABLE IF EXISTS likes;
-- CREATE TABLE likes(
-- 	id SERIAL,
--     user_id BIGINT UNSIGNED NOT NULL,
--     media_id BIGINT UNSIGNED NOT NULL,
--     created_at DATETIME DEFAULT NOW()
-- 
--     -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
--   	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  
-- 
-- 
--     FOREIGN KEY (user_id) REFERENCES users(id)
--     FOREIGN KEY (media_id) REFERENCES media(id)
-- );

CREATE TABLE likes(
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()
    , FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE restrict
    , FOREIGN KEY (media_id) REFERENCES media(id)
);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk 
FOREIGN KEY (media_id) REFERENCES vk.media(id);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk_1 
FOREIGN KEY (user_id) REFERENCES vk.users(id);

ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_1 
FOREIGN KEY (photo_id) REFERENCES media(id);


------------------ Задача 1.
-- Написать крипт, добавляющий в БД vk, которую создали на занятии, 2-3 новые таблицы (с перечнем полей, указанием индексов и внешних ключей) (CREATE TABLE)

-- добавим таблицу фотоальбомов
DROP TABLE IF EXISTS photo_albums;
CREATE TABLE photo_albums (
	id SERIAL,
	name varchar(255),
    user_id BIGINT UNSIGNED NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- добавим таблицу фотографий
DROP TABLE IF EXISTS photos;
CREATE TABLE photos (
	id SERIAL,
	album_id BIGINT unsigned,
	media_id BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);



-- добавим таблицу городов
-- DROP TABLE IF EXISTS cities;
-- CREATE TABLE cities (
-- 	id SERIAL,
-- 	`name` varchar(255) NOT NULL,
-- ); пишит ошибку с назначением неправильных ковычек.
-- 
-- добавим поле с идентификатором города
-- ALTER TABLE profiles ADD COLUMN city_id BIGINT UNSIGNED NOT NULL ;
-- 
-- сделаем это поле внешним ключом
-- ALTER TABLE `profiles` ADD CONSTRAINT fk_profiles_city_id
--     FOREIGN KEY (city_id) REFERENCES cities(id)

/*3. Заполнить 2 таблицы БД vk данными (по 10 записей в каждой таблице) (INSERT)*/

INSERT INTO `users` 
VALUES ('1','Иванов','Иван','ivan.ivan@yandex.ru','1','89222222222'),
    ('2','Петров','Петр','petrov.petr@yandex.ru','2','89111111111'),
    ('3','Вилкова','Вера','vilkova.vera@yandex.ru','3','89000000000'),
    ('4','Сидорова','Ксения','sidorova.ksenya@yandex.ru','4','89333333333'),
    ('5','Сталин','Иосив','stalin.iosiv@yandex.ru','5','89444444444'),
    ('6','Ленин','Владимир','lenin.vladimir@yandex.ru','6','89555555555'),
    ('7','Пунин','Владимир','putin.vladimir@yandex.ru','7','89666666666'),
    ('8','Великая','Елизавета','velikay.elizaveta@yandex.ru','8','89777777777'),
    ('9','Королева','Наташа','koroleva.natasha@yandex.ru','9','89888888888'),
    ('10','Княжна','Александра','knazna.alexandra@yandex.ru','10','89999999999');

   
INSERT INTO likes VALUES 
('1','1','1','1988-10-14 18:47:39'),
('2','2','1','1988-09-04 16:08:30'),
('3','3','1','1994-07-10 22:07:03'),
('4','4','1','1991-05-12 20:32:08'),
('5','5','2','1978-09-10 14:36:01'),
('6','6','2','1992-04-15 01:27:31'),
('7','7','2','2003-02-03 04:56:27'),
('8','8','8','2017-04-24 09:30:19'),
('9','9','9','1974-02-07 20:53:55'),
('10','10','10','1973-05-11 03:21:40'),
('11','11','11','2008-12-17 13:03:56'),
('12','12','12','1995-07-17 21:22:38'),
('13','13','13','1985-09-07 23:34:21'),
('14','14','14','1973-01-27 23:11:53')
; 

------------------ Задача 4.
/* Написать скрипт, удаляющий сообщения «из будущего» (дата позже сегодняшней) */

-- добавим флаг is_deleted 
ALTER TABLE messages 
ADD COLUMN is_deleted BIT DEFAULT 0;

-- отметим пару сообщений неправильной датой
update messages
set created_at = now() + interval 1 year
limit 2;

-- отметим, как удаленные, сообщения "из будущего"
update messages
set is_deleted = 1
where created_at > NOW();

/*
-- физически удалим сообщения "из будущего"
delete from messages
where created_at > NOW()
*/

-- проверим
select *
from messages
order by created_at desc;

------------------ Задача 3.
/*
Написать скрипт, отмечающий несовершеннолетних пользователей как неактивных (поле is_active = false). При необходимости предварительно добавить такое поле в таблицу profiles со значением по умолчанию = true (или 1)
*/
-- добавим флаг is_active 
ALTER TABLE vk.profiles 
ADD COLUMN is_active BIT DEFAULT 1;

-- сделать невовершеннолетних неактивными
UPDATE profiles
SET is_active = 0
WHERE (birthday + INTERVAL 18 YEAR) > NOW();

-- проверим не активных
select *
from profiles
where is_active = 0
order by birthday;

-- проверим активных
select *
from profiles
where is_active = 1
order by birthday;

-- Домашняя работа 3
-- 1.Написать скрипт, возвращающий список имен (только firstname) пользователей без повторений в алфавитном порядке. [ORDER BY]

SELECT firstname
FROM users
GROUP BY firstname # добовляет сортировку по столбцу fistname 
ORDER BY firstname;

-- 2. Выведите количество мужчин старше 35 лет [COUNT].

SELECT *
FROM profiles 
WHERE 
     TIMESTAMPDIFF(YEAR, birthday, NOW()) > 35
     AND gender = 'm'

-- 3. Сколько заявок в друзья в каждом статусе? (таблица friend_requests) [GROUP BY]
     
SELECT 
COUNT(*),status
FROM friend_requests 
GROUP BY status

-- Домашняя работа 4
-- 1. Подсчитать количество групп (сообществ), в которые вступил каждый пользователь.
SELECT user_id, COUNT(*) 'Количество групп'
FROM users_communities
INNER join messages ON id=community_id
GROUP BY user_id

-- 2. Подсчитать количество пользователей в каждом сообществе.

SELECT name, COUNT(user_id)
FROM communities 
INNER JOIN users_communities on community_id=id
GROUP BY name

-- 3. Пусть задан некоторый пользователь. Из всех пользователей соц. сети найдите человека, который больше всех общался с выбранным пользователем (написал ему сообщений).

-- SELECT id, firstname, lastname
-- FROM messages
-- INNER JOIN users  ON id= from_user_id
-- WHERE to_user_id = '1'
-- GROUP BY from_user_id
-- ORDER BY from_user_id DESC 
-- LIMIT 1;
SELECT
    from_user_id
    , COUNT(*) as send 
FROM messages 
WHERE to_user_id=1
GROUP BY from_user_id
ORDER BY send DESC;
-- 4* * Подсчитать общее количество лайков, которые получили пользователи младше 18 лет..
SELECT COUNT(*) as 'likes' FROM profiles WHERE (YEAR(NOW())-YEAR(birthday)) < 18;
-- 5* Определить кто больше поставил лайков (всего): мужчины или женщины.
SELECT gender, COUNT(*) as 'Кол-во' FROM profiles GROUP BY gender;
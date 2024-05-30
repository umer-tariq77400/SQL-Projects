USE music_store;


-- Easy
-- Selecting senior most employee
SELECT * 
FROM employee
WHERE levels = (SELECT max(levels) 
                FROM employee);

-- Selecting countries with the most invoices
SELECT billing_country, COUNT(invoice_id) AS c
FROM invoice
GROUP BY billing_country
ORDER BY c DESC
limit 5;

-- Top 3 Values of total invoice
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;

-- City and its sum of invoice total that has highest sum of invoice total
SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY SUM(total) DESC
LIMIT 1;

-- Customer that has spent the most money
SELECT c.customer_id,c.first_name, c.last_name, SUM(total) AS totalspending
FROM invoice AS i
RIGHT JOIN customer AS c
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY SUM(total) DESC
LIMIT 1;


-- Moderate

-- Make a column that tells if the track is long or short
SELECT track_id, name, milliseconds,
CASE 
    WHEN milliseconds > (SELECT AVG(milliseconds) FROM track) THEN "LONG TRACK"
    WHEN milliseconds < (SELECT AVG(milliseconds) FROM track) THEN "SHORT TRACK"
    ELSE "MODERATE TRACK"
END AS song_length_atatus
FROM track;

-- Make a column that tells if the artist is popular, normal or not popular on the basis of total tracks sold
SELECT a.artist_id, a.name, COUNT(track_id) AS total_tracks,
CASE 
    WHEN percent_rank() OVER (ORDER BY COUNT(track_id)) >= 0.9 THEN 'Popular'
    WHEN percent_rank() OVER (ORDER BY COUNT(track_id)) <= 0.1 THEN 'Not Popular'
    ELSE 'Normal'
END AS Popularity
FROM artist AS a
JOIN album AS al ON a.artist_id = al.artist_id
JOIN track AS t ON al.album_id = t.album_id
GROUP BY a.artist_id;




-- Top 10 Email, first name, last name and genre of all rock music listener
SELECT c.first_name, c.last_name, c.email, g.name 
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY email
LIMIT 10;

-- Names and total track counts of the to 10 rock bands
SELECT a.name, a.artist_id, COUNT(a.artist_id) AS total_rock_track
FROM artist AS a
JOIN album as al ON a.artist_id = al.artist_id
JOIN track AS t ON al.album_id = t.album_id
JOIN genre AS G on t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id
ORDER BY COUNT(a.artist_id) DESC
LIMIT 10;

-- Name of track songs having lenght greater than average lenght of the songs
SELECT name, milliseconds 
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) 
                      FROM track)
ORDER BY milliseconds DESC;


-- Advance
-- Name of customer, their total spending and the artist on which they spent
WITH CTE1 AS 
(SELECT i.customer_id, il.track_id, SUM(unit_price*quantity) OVER (PARTITION BY i.customer_id) AS total_price 
FROM invoice_line AS il
JOIN invoice AS i ON il.invoice_id = i.invoice_id),
CTE2 AS
(SELECT at.artist_id,at.name, a.album_id, t.track_id
FROM artist AS at
JOIN album AS a ON at.artist_id = a.artist_id
JOIN track AS t ON a.album_id = t.album_id
)
SELECT *
FROM CTE1, CTE2;

-- Most popular genre in each country with respect to sales
WITH CTE1 AS
(SELECT COUNT(il.quantity) AS purchases, c.country, g.name, g.genre_id,
ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(il.quantity)) AS Row_no
FROM invoice_line AS il
JOIN invoice AS i ON il.invoice_id = i.invoice_id
JOIN customer AS c ON i.customer_id = c.customer_id
JOIN track AS t ON il.track_id = t.track_id
JOIN genre AS g ON t.genre_id = g.genre_id
GROUP BY 2,3,4
ORDER BY 2 ASC, 1 DESC)
SELECT * 
FROM CTE1
WHERE Row_no <= 1;

-- The customers who spent most in country
WITH CTE1 AS
(SELECT c.customer_id, c.first_name, c.last_name, c.country, SUM(i.total) AS total_spending,
row_number() OVER (PARTITION BY c.country ORDER BY c.country, SUM(i.total) DESC) AS Row_no
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
GROUP BY 4,1,2,3
ORDER BY 4 DESC,5 DESC)
SELECT *  
FROM CTE1
WHERE Row_no = 1;














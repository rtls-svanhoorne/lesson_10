WITH WinePerformance AS (
    SELECT
        name,
        region,
        variety,
        CAST(substr(name, length(name) - 3, 4) AS INTEGER) AS wine_year, -- Extract year from name
        rating,
        notes
    FROM wines
),
TopRegions AS (
    SELECT region
    FROM (
        SELECT region, AVG(rating) AS avg_rating
        FROM WinePerformance
        GROUP BY region
        ORDER BY avg_rating DESC
        LIMIT 15
    )
),
WineWithAvg AS (
    SELECT
        wp.*,
        AVG(wp.rating) OVER (
            PARTITION BY wp.region, wp.variety
            ORDER BY wp.wine_year
            ROWS BETWEEN 600 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_rating
    FROM WinePerformance wp
)
SELECT
    wwa.name,
    wwa.region,
    wwa.variety,
    wwa.wine_year,
    wwa.rating,
    wwa.rolling_avg_rating,
    ROUND(wwa.rating * 1000 / NULLIF(wwa.rolling_avg_rating, 0), 2) AS performance_ratio,
    CASE
        WHEN wwa.rating > wwa.rolling_avg_rating THEN 'Above Rolling Avg'
        WHEN wwa.rating = wwa.rolling_avg_rating THEN 'Equal to Rolling Avg'
        ELSE 'Below Rolling Avg'
    END AS performance_trend,
    CASE
        WHEN wwa.rating < 50 THEN 'Low Rating'
        WHEN wwa.rating BETWEEN 50 AND 75 THEN 'Medium Rating'
        ELSE 'High Rating'
    END AS rating_category
FROM WineWithAvg wwa
INNER JOIN TopRegions tr ON wwa.region = tr.region
ORDER BY wwa.region, wwa.variety, wwa.wine_year DESC, LENGTH(wwa.name) DESC
LIMIT 50;

/* In this analysis, we are going to look at sales trends across stores and months 
to determine if there are specific stores, departments, or times of year that are associated with better or worse sales performance. */

/* Data Cleaning: */


SELECT  COUNT(DISTINCT saledate) AS num_days,
 	EXTRACT(MONTH from saledate) AS month_num,
        EXTRACT(YEAR from saledate) AS year_num
FROM trnsact
GROUP BY month_num, year_num
ORDER BY  year_num ASC, month_num ASC;

/* Observations: 
1. There are 27 days recorded in the database during August, 2005, but 31 days recorded during August, 2004. 
This is because that’s how the database is created when it is 	donated. 
Thus, we will restrict our analysis of August sales to those recorded in 2004.
2. None of the stores have data for Nov. 25 (Thanksgiving), Dec. 25 (Christmas), or March 27. */

/* For the analysis of sales performance, there are different numbers of days in each month of the year. 
If we simply add up all the sales in each month to look at sales trends across the year, 
we will get more sales for the months that have more days in them,
but those increased numbers, by themselves, will not reflect true buying trends. */

/* To make sure this, we first analyze, How many distinct dates are there in the sale date column of the transaction table
for each month/year/store combination in the database. */


SELECT COUNT(DISTINCT saledate) AS numdate,
	EXTRACT(MONTH from saledate) AS month_num,
	EXTRACT(YEAR from saledate) AS year_num,
	Store
FROM trnsact
GROUP BY 2,3,4
ORDER BY 1 ASC;


/* Observation:
1. From this, there are about 21% of stores have at least one day of transaction missing. 
We can’t assess sales performance by simply adding up all the revenue, because like months that have more days in them, 
stores that have more data recorded from them will artificially appear to have better sales performance.
2. Also, we don’t want to exclude all the information from stores that have some missing data,
because 21% is a lot of data to throw away, and the stores with missing data may have some common features
that would skew our results if they were excluded. */

/* For further analysis, we will assess sales by summing the total revenue for a given time period and 
 dividing it by the total number of days that contributed to that time period. 
 This will give us “average daily revenue”.
 And will only examine store/month/year combinations that have at least 27 days of data within that month. */
 
 
/* Data analysis:*/

/* Now, we’ll find the average daily revenue Dillard’s brought in during each month of the year using the following query.
(considering only ‘purchase’ transactions) */

 
SELECT month_num, SUM(revenue)/SUM(numdate) AS avg_daily_revenue
FROM(   SELECT COUNT(DISTINCT saledate) AS numdate,	
	EXTRACT(MONTH from saledate) AS month_num,
	EXTRACT(YEAR from saledate) AS year_num,
	SUM(amt) AS revenue
	FROM trnsact
	WHERE stype = 'P'
	GROUP BY 2,3
	HAVING numdate > 27) AS New_data
GROUP BY 1
ORDER BY 2 DESC;


/* Results show that December consistently has the best sales, August consistently has the worst or close to the worst sales,
and July has very good sales, although less than December. */

/* To make recommendations about seasonal marketing strategies or what inventory to have at different times of the year, 
we consider these consistently high- and low- performing months. */


SELECT s1.store, s1.percent_change_revenue, st.city, st.state, s1.dept, d.deptdesc
FROM	(SELECT SUM(CASE WHEN EXTRACT(MONTH from t.saledate) =11 THEN amt END) AS Nov_revenue,
                SUM(CASE WHEN EXTRACT(MONTH from t.saledate) =12 THEN amt END) AS Dec_revenue,
                COUNT(DISTINCT CASE WHEN EXTRACT(MONTH from t.saledate) = 11 THEN t.saledate END) AS Nov_days,
		COUNT(DISTINCT CASE WHEN EXTRACT(MONTH from t.saledate) = 12 THEN t.saledate END) AS Dec_days,
		Nov_revenue/Nov_days AS Nov_daily_revenue,
                Dec_revenue/Dec_days AS Dec_daily_revenue,
                (Dec_daily_revenue-Nov_daily_revenue)/Nov_daily_revenue*100 AS Percent_change_revenue, dept, store, 
                CASE WHEN EXTRACT(YEAR from t.saledate) = 2005 AND EXTRACT(MONTH from t.saledate) = 8 THEN 'exclude' END AS exclude_flag
	FROM skuinfo s JOIN trnsact t ON
		s.sku=t.sku 
	WHERE stype = 'P' AND exclude_flag IS NULL
	GROUP BY dept, store, exclude_flag
	HAVING Nov_days > 27 AND Dec_days > 27) AS s1 JOIN strinfo st ON
					S1.store=st.store JOIN deptinfo d ON
					S1.dept=d.dept
GROUP BY 1,2,3,4,5,6
ORDER BY 2 DESC;


/* From November to December,
the store located in Dallas, TX and Department 7205, LOUISVILLE had the greatest 417% increase in average daily sales revenue. */

SELECT s1.change_revenue, s1.store, st.city, st.state
FROM (	SELECT  SUM(CASE WHEN EXTRACT(MONTH from saledate) =7 THEN amt END) AS Jul_revenue,
       		SUM(CASE WHEN EXTRACT(MONTH from saledate) = 8 THEN amt END) AS Aug_revenue,
		COUNT(DISTINCT CASE WHEN EXTRACT(MONTH from saledate) = 7 THEN saledate END) AS Jul_days,
		COUNT(DISTINCT CASE WHEN EXTRACT(MONTH from saledate) = 8 THEN saledate END) AS Aug_days,
		Jul_revenue/Jul_days AS Jul_avg_revenue,
		Aug_revenue/Aug_days AS Aug_avg_revenue, 
		Jul_avg_revenue - Aug_avg_revenue AS change_revenue, store, 
		CASE WHEN EXTRACT(YEAR from saledate) = 2005 AND EXTRACT(MONTH from saledate)= 8 THEN 'exclude' END AS exclude_flag
       	FROM 	trnsact
	WHERE	stype = 'P' AND exclude_flag IS NULL
        GROUP BY store, exclude_flag
        HAVING Jul_revenue > 27 AND Aug_revenue > 27) AS s1 JOIN strinfo st ON 
				S1.store=st.store 
GROUP BY 1,2,3,4
ORDER BY change_revenue DESC;


/* From July to August, store 2707, at Mcallen, TX had the greatest decrease in average daily revenue. */ 

/* Recommendations:
1. August and September had the worst sales, for this duration changing marketing strategies might lead to an increase in sales.
2. Top 6 out of 10 Dillards’ stores located in Florida, had nearly $10,000 decrease in the average daily revenue from July to August. 
   For that, reducing the sales price and increasing marketing in that specific area for that specific time,
   might lead to an increase in the average daily revenue. */


/* Analysis considering the population statistics of the geographical location surrounding a store and relate to sales performance. */

/* By doing such analysis, we can design strategies that will allow Dillard’s to take advantage of the geographic trends 
  or make decisions about how to handle geographic locations that consistently have poor sales performance. */
 
/* Doing this analysis in three parts:

1. Considering the level of Median Income

2. Considering populations

3. Considering the level of high school education */

/*
1) Considering Median Income

To analyze the relationship between income and average daily revenue,
first created income brackets in the following query and then assigned it to the respected average daily revenue from then per store. */


SELECT SUM(revenue_per_store.revenue)/SUM(numdays) AS avg_group_revenue, 
       CASE WHEN revenue_per_store.msa_income BETWEEN 1 AND 20000 THEN 'low'
       WHEN revenue_per_store.msa_income BETWEEN 20001 AND 30000 THEN 'med-low'
       WHEN revenue_per_store.msa_income BETWEEN 30001 AND 40000 THEN 'med-high'
       WHEN revenue_per_store.msa_income BETWEEN 40001 AND 60000 THEN 'high'
       END AS income_group
FROM ( SELECT m.msa_income, t.store, 
              CASE WHEN EXTRACT(YEAR from t.saledate) = 2005 AND EXTRACT(MONTH from t.saledate) = 8 then 'exclude' END AS exclude_flag, 
	      SUM(t.amt) AS revenue, COUNT(DISTINCT t.saledate) AS numdays, EXTRACT(MONTH from t.saledate) AS monthID
       FROM   store_msa m JOIN trnsact t ON
       		m.store=t.store
       WHERE  t.stype = 'P' AND exclude_flag IS NULL AND t.store||EXTRACT(YEAR from t.saledate)||EXTRACT(MONTH from t.saledate) 
		IN (SELECT store||EXTRACT(YEAR from saledate) || EXTRACT(MONTH from saledate)
       FROM   trnsact
       GROUP BY store, EXTRACT(YEAR from saledate), EXTRACT(MONTH from saledate)
       HAVING COUNT(DISTINCT saledate) >= 27)
       GROUP BY t.store, m.msa_income, monthID, exclude_flag) AS revenue_per_store
GROUP BY income_group
ORDER BY avg_group_revenue DESC;     


/* Results show that the bracket of the low-income population generate highest daily revenue of $34,159 per store, 
  and high-income population had the lowest average daily revenue of $18,157. 
  Population of Med-high and Med-low income bracket had the average daily revenue of $22,030 and $ $18,157 respectively. */ 

/* Further, comparing the average daily revenue of the store with the highest msa_income 
  and the store with the lowest median msa_income, using the following query */


SELECT SUM(store_rev.tot_sales)/SUM(store_rev.numdays) AS daily_average, store_rev.msa_income as med_income, 
       store_rev.city, store_rev.state
FROM ( SELECT 	COUNT(DISTINCT t.saledate) AS numdays, EXTRACT(YEAR from t.saledate) AS s_year, 
               	EXTRACT(MONTH from t.saledate) AS s_month,
       		t.store, SUM(t.amt) AS tot_sales, 
       		CASE WHEN EXTRACT(YEAR from t.saledate) = 2005 AND EXTRACT(MONTH from t.saledate) = 8 THEN 'exclude' END AS exclude_flag, 
      		m.msa_income, s.city, s.state
       FROM 	trnsact t JOIN store_msa m ON m.store = t.store 
       		JOIN strinfo s ON t.store = s.store
       WHERE	t.stype = 'P' AND exclude_flag IS NULL
       GROUP BY s_year, s_month, t.store, m.msa_income, s.city, s.state
       HAVING numdays >= 27) AS store_rev
WHERE store_rev.msa_income IN ((SELECT MAX(msa_income) from store_msa), (SELECT MIN(msa_income) from store_msa))
GROUP BY med_income, store_rev.city, store_rev.state;


/* The store with the highest median msa_income is in Spanish Fort, AL. 
 It had a lower average daily revenue than the store with the lowest median msa_income, which was in McAllen, TX. */
*/

Median_income    Daily_average_revenue
$56,099                         $18,280
$16,022                         $56,602

*/

/*
2)  Considering Population

The following query gives results of population groups and their respected daily average revenue. */


SELECT	SUM(store_rev.tot_sales)/SUM(store_rev.numdays) AS daily_avg,
	CASE WHEN store_rev.msa_pop BETWEEN 1 AND 100000 THEN 'very small'
	WHEN store_rev.msa_pop BETWEEN 100001 AND 200000 THEN 'small'
	WHEN store_rev.msa_pop BETWEEN 200001 AND 500000 THEN  'med_small'
	WHEN store_rev.msa_pop BETWEEN 500001 AND 1000000 THEN 'med_large'
	WHEN store_rev.msa_pop BETWEEN 1000001 AND 5000000 THEN 'large'
	WHEN store_rev.msa_pop > 5000000 THEN 'very large' 
	END as pop_group
FROM(	SELECT COUNT(DISTINCT t.saledate) as numdays, EXTRACT(YEAR from t.saledate) as s_year,
	       EXTRACT(MONTH from t.saledate) as s_month, t.store, SUM(t.amt) AS tot_sales,
	       CASE WHEN EXTRACT(YEAR from t.saledate) = 2005 AND EXTRACT(MONTH from t.saledate) = 8 THEN 'exclude' END AS exclude_flag, m.msa_pop
 	FROM   trnsact t JOIN store_msa m ON m.store = t.store
        WHERE  t.stype = 'P' AND exclude_flag IS NULL 
        GROUP BY s_year, s_month, t.store, m.msa_pop
        HAVING numdays >= 27)  AS store_rev
GROUP BY pop_group
ORDER BY daily_avg;


/* Outcome: */
/*
 	
	Daily_average revenue			pop_group
	$12,687				very_small
	$16,376				small
	$21,211				med_small
	$22,131				large
	$24,246				med_large
	$25,560				very_large
	
*/


/*
3) Considering the level of high school education

Using the following query, we will find the relation between the level of high school education of the nearby population 
and how much daily average revenue they generate. */


SELECT store_rev.edu_level, (SUM(store_rev.rev)/SUM(store_rev.saledays)) AS daily_rev
FROM( 	SELECT 	EXTRACT( YEAR from saledate) AS year_num, EXTRACT(MONTH from saledate) AS month_num, 
		t.store, COUNT(DISTINCT saledate) AS saledays, SUM(amt) AS rev,
		CASE WHEN m.msa_high > 50 AND m.msa_high <=60 THEN 'low'
		     WHEN m.msa_high > 60 AND m.msa_high <=70 THEN 'medium'
		     WHEN m.msa_high > 70 THEN 'High'
		     ELSE 'check' END AS edu_level,
		CASE WHEN EXTRACT(YEAR FROM saledate) = 2005 AND EXTRACT(MONTH FROM saledate) = 8 THEN 'exclude'  
		     END as exclude_flag
	FROM	 trnsact t JOIN store_msa  m
			ON t.store=m.store
	WHERE 	stype = 'P' AND exclude_flag IS NULL
	GROUP BY year_num, month_num, t.store, edu_level
	HAVING 	saledays > 27 ) AS store_rev
GROUP BY store_rev.edu_level
ORDER BY daily_rev DESC;

	
/*	Result:
	
	High school education 		avg_daily_revenue
	Low 				$34,159
	Medium				$25,183
	High				$20,917
	
*/

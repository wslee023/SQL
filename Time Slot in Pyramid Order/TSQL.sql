--================================
-- Time slots in pyramid ordering
--================================
--********************************
-- Tally table: -1024 to 1024
--********************************

DECLARE	@dtLastTrStart AS DATETIME
DECLARE @dEarliestAvailableDateByBrand AS DATE
DECLARE @iResultTimeSlotSeparationInMinute AS INT
DECLARE @iResultTimeSlotIterationCount AS INT
DECLARE @iSearchPeriodInMonth AS INT
DECLARE @iTrDurationInMinute AS INT

SET @dtLastTrStart = '2017-1-1 19:00:00'
SET @dEarliestAvailableDateByBrand = '2017-1-15'
SET @iResultTimeSlotSeparationInMinute = 60
SET @iResultTimeSlotIterationCount = 30
SET @iSearchPeriodInMonth = 1
SET @iTrDurationInMinute = 90

DECLARE	@iDayofWeek AS INT
DECLARE @dtSearchEnd AS DATETIME
DECLARE	@iTimeRefUpperBound AS INT
DECLARE	@iTimeRefLowerBound AS INT

SET @iDayofWeek = DATEPART(dw, @dtLastTrStart)
SET @dtSearchEnd = DATEADD(MONTH, @iSearchPeriodInMonth, @dEarliestAvailableDateByBrand)
SET @iTimeRefUpperBound = DATEDIFF(MINUTE, @dtLastTrStart, CAST(CONVERT(VARCHAR(10), @dtLastTrStart, 110) + ' 00:00:00' AS DATETIME)) / @iResultTimeSlotSeparationInMinute
SET @iTimeRefLowerBound = DATEDIFF(MINUTE, @dtLastTrStart, CAST(CONVERT(VARCHAR(10), @dtLastTrStart, 110) + ' 23:59:59' AS DATETIME)) / @iResultTimeSlotSeparationInMinute

IF object_id('tempdb..#tmp_search_datetime') IS NOT NULL  
 BEGIN  
    DROP TABLE #tmp_search_datetime 
 END; 
 
IF object_id('tempdb..#tmp_result_A') IS NOT NULL  
 BEGIN  
    DROP TABLE #tmp_result_A 
 END; 
  
IF object_id('tempdb..#tmp_result_B') IS NOT NULL  
 BEGIN  
    DROP TABLE #tmp_result_B
 END; 

CREATE TABLE #tmp_search_datetime 
 ( 
   [display_order] [int]
   , [search_datetime_start] [datetime]
   , [search_datetime_end] [datetime]
 );

CREATE TABLE #tmp_result_A
 ( 
   [display_order] [int]
   , [search_datetime_start] [datetime]
   , [search_datetime_end] [datetime]
   , [shop_id] [int]	NULL
   , [biz_unit_id] [int] NULL
   , [loc_id] [int] NULL
 );
 
CREATE TABLE #tmp_result_B
 ( 
   [display_order] [int]
   , [search_datetime_start] [datetime]
   , [search_datetime_end] [datetime]
   , [shop_id] [int]	NULL
   , [biz_unit_id] [int] NULL
   , [loc_id] [int] NULL
 );

INSERT INTO #tmp_search_datetime
(
	[display_order]
	, [search_datetime_start]
	, [search_datetime_end]
)
SELECT	
		ROW_NUMBER() OVER (ORDER BY	[time_order]
									, [date_ref])
									AS [display_order]
		, CONVERT(DATETIME, CONVERT(CHAR(8), [date_ref], 112) 
			+ ' ' 
			+ CONVERT(CHAR(8), [time_ref], 108))	
			AS [search_datetime_start]		
		, DATEADD(MINUTE
					, @iTrDurationInMinute
					, CONVERT(DATETIME, CONVERT(CHAR(8), [date_ref], 112) 
						+ ' ' 
						+ CONVERT(CHAR(8), [time_ref], 108))
					) AS [search_datetime_end]
FROM
(
	-- Get date source
	SELECT	DATEADD(dd
					, [digit]
					, @dEarliestAvailableDateByBrand) 
					AS [date_ref]
	FROM	[dbo].[xxx_tmp_digit]
	WHERE	[digit] > -1
			AND DATEADD(dd, [digit], @dEarliestAvailableDateByBrand) <= @dtSearchEnd
			AND DATEPART(dw ,DATEADD(dd,[digit],@dEarliestAvailableDateByBrand)) = @iDayofWeek
) [date_source]
CROSS JOIN (
				-- Get time source
				SELECT	DATEADD(MINUTE
								, @iResultTimeSlotSeparationInMinute * ([digit])
								, @dtLastTrStart)
								AS [time_ref]
				FROM	[dbo].[xxx_tmp_digit]
				WHERE	ABS([digit]) <= @iResultTimeSlotIterationCount
						AND	@iTimeRefUpperBound <= [digit]
						AND @iTimeRefLowerBound >= [digit]
) [time_source]
WHERE	DATEPART(dd, @dtLastTrStart) = DATEPART(dd, [time_ref])

SELECT	
	[display_order]
	, [search_datetime_start]
	, [search_datetime_end]
FROM	#tmp_search_datetime

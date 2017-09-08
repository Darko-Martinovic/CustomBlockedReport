--TESTER ZA PROVJERU FUNKCIONALNOSTI MONITORA NA DB3/TEST_DARKO_KLEMM
 
--+++++++++++++++++KEYLOCK  
SELECT
	DBO.[GetResourceName]('KEY: 41:72057594544062464 (b14200e25741)', default);
SELECT
DBO.[GetResourceContent]('KEY: 41:72057594544062464 (b14200e25741)','PLACE_0.OBRACUNI',default);
DECLARE @waitResource as nvarchar(256) = 'KEY: 41:72057594544062464 (b14200e25741)'
DECLARE @sql as nvarchar(max)
DECLARE @tableName as nvarchar(256)
DECLARE @resCon as nvarchar(max)
SET @SQL = DBO.[GetResourceContent]('KEY: 41:72057594544062464 (b14200e25741)','PLACE_0.OBRACUNI','@PROBA');
--SET @sql = DBO.GetResourceName(@waitResource, '@proba')

EXEC sp_executesql	@sql
				,N'@proba nvarchar(max) output'
				,@resCon OUTPUT;
SELECT
	@resCon

--U prvom prozoru startamo 
--BEGIN TRAN USERTRAN
--;WITH X AS ( SELECT
--	*
--FROM PLACE_0.OBRACUNI
--WHERE SIFRA = '9999')
--UPDATE X SET NASLOV_OBRACUNA = NASLOV_OBRACUNA
--ROLLBACK
--U drugom prozoru startamo 
--SELECT
--	*
--FROM PLACE_0.OBRACUNI
--WHERE SIFRA = '9999'

--++++++++++++OBJECT LOCK
SELECT
	DBO.[GetResourceName]('OBJECT: 41:642153383:0',default);
SELECT
	DBO.[GetResourceContent]('OBJECT: 41:642153383:0','PLACE_0.OBRACUNI');
DECLARE @waitResourceObj as nvarchar(256) = 'OBJECT: 41:642153383:0'
DECLARE @sqlObj as nvarchar(max)
DECLARE @tableNameObj as nvarchar(256)

SET @sqlObj = DBO.GetResourceName(@waitResourceObj, '@proba')
EXEC sp_executesql	@sqlobj
				,N'@proba nvarchar(max) output'
				,@tableNameObj OUTPUT;
SELECT
	@tableNameObj


--begin tran
--;
--WITH X AS ( SELECT
--	*
--FROM  PLACE_0.OBRACUNI with(tablock,holdlock ))
--UPDATE X SET NASLOV_OBRACUNA = NASLOV_OBRACUNA
----ROLLBACK


--U drugom prozoru 

--begin tran proba
--;
--WITH X
--AS
--(SELECT
--		*
--	FROM PLACE_0.OBRACUNI)
--UPDATE X
--SET NASLOV_OBRACUNA = NASLOV_OBRACUNA
--ROLLBACK


---+++++++++++++++PAGELOCK
 --7:1:422000
SELECT
	DBO.GetResourceName('PAGE: 41:1:170526',default);
SELECT
DBO.GetResourceContent('PAGE: 41:1:170526','PLACE_0.OBRACUNI',default);

DECLARE @waitResourcePage as nvarchar(256) = 'PAGE: 41:1:170526'
DECLARE @sqlPage as nvarchar(max)
DECLARE @tableNamePage as nvarchar(256)
DECLARE @resourcContent as nvarchar(max)

--SET @sqlPage = DBO.GetResourceName(@waitResourcePage, '@proba')
SET @sqlPage = DBO.GetResourceContent('PAGE: 41:1:170526', 'PLACE_0.OBRACUNI', '@proba');

EXEC sp_executesql	@sqlPage
				,N'@proba nvarchar(max) output'
				,@resourcContent OUTPUT;
SELECT
	@resourcContent



-- U prvom prozoru startamo ovaj query dolje
--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
--BEGIN TRAN
--UPDATE PLACE_0.Obracuni WITH (PAGLOCK)
--SET NASLOV_OBRACUNA = NASLOV_OBRACUNA
--WHERE SIFRA = '9999'
--ROLLBACK
--U drugom prozoru startamo 
--SELECT
--	*
--FROM PLACE_0.OBRACUNI
--WHERE SIFRA > '1000'


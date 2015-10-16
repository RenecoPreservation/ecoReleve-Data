/****** Script de la commande SelectTopNRows à partir de SSMS  ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[split]
(
    @string varchar(MAX),
    @delimiter CHAR(1),
    @pos INT
)
RETURNS varchar(255)
AS
BEGIN
    DECLARE @start INT, @end INT, @count INT
    SELECT @start = 1, @end = CHARINDEX(@delimiter, @string), @count = 1 
    WHILE @start < LEN(@string) + 1 BEGIN
        IF @end = 0 
            SET @end = LEN(@string) + 1 
 
        IF @count = @pos
            RETURN SUBSTRING(@string, @start, @end - @start)
 
        SET @start = @end + 1 
        SET @end = CHARINDEX(@delimiter, @string, @start)
        SET @count = @count + 1 
 
    END
    RETURN '' -- not found
END

GO

---- migration des données argos/GPS/GSM --------------------------------------------------------------------------------------------
INSERT INTO NewModelERD.[dbo].[Individual_Location]
           ([LAT]
           ,[LON]
           ,[Date]
           ,[Precision]
		   ,[ELE]
		   ,creator
		   ,CreationDate
           ,[FK_Sensor]
           ,[FK_Individual]
		   ,type_
		   ,OriginalData_ID)
SELECT [LAT]
      ,[LON]
	  ,[DATE]
      ,[Precision]
      ,[ELE]
      ,[Creator]
      ,[Creation_date]
	  ,s.ID as fk_sensor
	  ,CASE WHEN i.ID IS NOT NULL THEN i.ID ELSE i2.ID END as fk_ind
	  ,CASE WHEN i.ID IS NOT NULL THEN 'argos' ELSE 'gps' END as type_
	  ,CASE WHEN i.ID IS NOT NULL THEN 'eReleve_TProtocolDataArgos_'+CONVERT(VARCHAR,a.PK) ELSE 'eReleve_TProtocolDataGPS_'+CONVERT(VARCHAR,g.PK) END

  FROM [ECWP_ecoReleveData].[dbo].[TStations] sta
  LEFT JOIN [ECWP_ecoReleveData].[dbo].TProtocol_ArgosDataArgos a ON sta.TSta_PK_ID = a.FK_TSta_ID
  LEFT JOIN [ECWP_ecoReleveData].[dbo].TProtocol_ArgosDataGPS g ON sta.TSta_PK_ID = g.FK_TSta_ID
  LEFT JOIN NewModelERD.dbo.Individual i ON 'eReleve_'+CONVERT(Varchar,a.FK_TInd_ID) = i.Original_ID
  LEFT JOIN NewModelERD.dbo.Individual i2 ON 'eReleve_'+CONVERT(Varchar,g.FK_TInd_ID) = i2.Original_ID
  JOIN NewModelERD.dbo.Sensor s ON dbo.split(sta.Name,'_',2) = s.UnicName
  where [FieldActivity_ID] = 27



  ------------------------ migration des données RFID --------------------------------------------------------------------------------------------
  INSERT INTO NewModelERD.[dbo].[Individual_Location]
           ([LAT]
           ,[LON]
           ,[Date]
		   ,creator
		   ,CreationDate
           ,[FK_Sensor]
           ,[FK_Individual]
		   ,type_
		   ,OriginalData_ID)
  SELECT [lat]
      ,[lon]
	  ,[date_]
	  ,[FK_creator]
      ,[creation_date]
	  ,s.ID
      ,i.ID
	  ,'rfid'
	  ,'eReleve_TAnimalLocation_'+CONVERT(VARCHAR,a.PK_id)

  FROM [ECWP_ecoReleveData].[dbo].[T_AnimalLocation] a
  JOIN NewModelERD.dbo.Individual i ON 'eReleve_'+CONVERT(Varchar,a.FK_ind) = i.Original_ID
  JOIN NewModelERD.dbo.Sensor s ON a.FK_obj = s.UnicName


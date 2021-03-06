
/****** Object:  StoredProcedure [dbo].[sp_validate_rfid]    Script Date: 15/10/2015 11:00:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_validate_rfid]
	@IdEquip int,
	@freq int,
	@user int,
	@nb_insert int OUTPUT,
	@exist int OUTPUT,
	@error int OUTPUT 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @data_to_insert table ( PK_id int
		, FK_ind int
		, FK_Sensor int
		, chip_code varchar(10)
		, date_ datetime
		, lat decimal(9,5)
		, lon decimal(9,5)
		,freq int );
	Declare @data_duplicate table (
		PK_id int
	
	);

	-- Gather not validated data.
	WITH data AS (
		SELECT ID
			, FK_Sensor
			, chip_code
			, date_
			,validated
			,checked
			, FK_MonitoredSite
			, ROW_NUMBER() OVER (PARTITION BY FK_Sensor, chip_code, CONVERT(DATE, date_), DATEPART(hour, date_), DATEPART(minute, date_)/@freq ORDER BY date_) as r
		FROM VRfidData_With_equipSite where equipID = @IdEquip 
	)
	INSERT INTO @data_to_insert
	(	PK_id
		, FK_Sensor
		, chip_code 
		, date_
		, lat 
		, lon
		,freq)
    SELECT data.ID
		, data.FK_Sensor
		, data.chip_code
		, data.date_
		, lat
		, lon
		,@freq
    FROM data
	JOIN MonitoredSitePosition p 
		ON p.FK_MonitoredSite = data.FK_MonitoredSite AND p.StartDate <= data.date_
	WHERE not exists (SELECT * FROM MonitoredSitePosition p1 
					WHERE p.FK_MonitoredSite = p1.FK_MonitoredSite AND p1.StartDate > p.StartDate AND  p1.StartDate <= data.date_ )
	and data.FK_MonitoredSite is not null AND data.r = 1 AND data.validated = 0 and data.checked=0;

	UPDATE d SET FK_ind = iv.FK_Individual
	FROM @data_to_insert d
	JOIN IndividualDynPropValue iv
		ON d.chip_code = iv.ValueString AND iv.FK_IndividualDynProp = 27 AND iv.StartDate <= d.date_
	WHERE NOT EXISTS (
			SELECT * FROM IndividualDynPropValue iv2 
			WHERE iv.FK_Individual = iv2.FK_IndividualDynProp AND iv.FK_IndividualDynProp = iv2.FK_IndividualDynProp 
			AND iv2.StartDate > iv.StartDate AND iv2.StartDate <= d.date_)

	delete from @data_to_insert where FK_ind is null 

	insert into @data_duplicate
	SELECT d.PK_id
	FROM @data_to_insert d JOIN Individual_Location loc 
	ON d.FK_ind = loc.FK_Individual and d.date_ = loc.Date and d.FK_Sensor = loc.FK_Sensor
	
	-- Insert only the first chip lecture per RFID, per individual, per hour.
	INSERT INTO Individual_Location (creator, FK_Sensor, FK_Individual, type_, Date, lat, lon, creationDate)
	SELECT @user, FK_Sensor, FK_ind, 'rfid', date_, lat, lon, CURRENT_TIMESTAMP
	FROM @data_to_insert d WHERE d.PK_id NOT IN (SELECT * FROM @data_duplicate)



	-- Update inserted data.
	UPDATE t SET validated = 1 , frequency= @freq
	from ecoReleve_Sensor.dbo.T_rfid t
	WHERE t.ID IN (SELECT PK_id FROM @data_to_insert);
	UPDATE VRfidData_With_equipSite SET checked = 1	Where equipID = @IdEquip


	
	SELECT @nb_insert = COUNT(*) FROM @data_to_insert where PK_id not in (select * from @data_duplicate)
	Select @exist = Count (*) from @data_duplicate 
	SELECT @error = @@ERROR

	RETURN
END








GO





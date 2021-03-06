-------------------------------------INSERT Static Prop Values -------------------------------------------------------------
--INSERT INTO Individual (
--[creationDate],
--Age,
--Species,
--Birth_date,
--Death_date,
--Original_ID,
--fk_individualType
--)
--SELECT o.[Creation_date]
--      ,[id2@Thes_Age_Precision]
--	  ,[id34@TCaracThes_Species_Precision]
--      ,[id35@Birth_date]
--      ,[id36@Death_date]
--	  ,'eReleve_'+CONVERT(VARCHAR,Individual_Obj_PK)
--	  , IT.ID
--FROM [ECWP-eReleveData].[dbo].[TViewIndividual] I
--JOIN [ECWP-eReleveData].[dbo].TObj_Objects o on I.Individual_Obj_PK = o.Object_Pk
--JOIN IndividualType IT ON  IT.name ='Standard'
--GO

-------------------------------------INSERT Sex in Dynamic Prop Values -------------------------------------------------------------
--INSERT INTO IndividualDynPropValue(
--		[StartDate]
--      ,[ValueString]
--      ,[FK_IndividualDynProp]
--      ,[FK_Individual]
--) 
--SELECT I.[creationDate],
--		IV.[id30@TCaracThes_Sex_Precision],
--		(SELECT ID FROM IndividualDynProp WHERE Name = 'Sex'),
--		I.ID
--FROM [ECWP-eReleveData].[dbo].[TViewIndividual] IV 
--JOIN Individual I ON 'eReleve_'+CONVERT(VARCHAR,IV.Individual_Obj_PK) = I.Original_ID
--GO

-------------------------------------INSERT Dynamic Prop Values -------------------------------------------------------------
--INSERT INTO IndividualDynPropValue(
--		[StartDate]
--      ,[ValueInt]
--      ,[ValueString]
--      ,[ValueDate]
--      ,[ValueFloat]
--      ,[FK_IndividualDynProp]
--      ,[FK_Individual]
--)

--SELECT
--val.begin_date,
--Case 
--	WHEN dp.TypeProp = 'Integer' AND val.value_precision is NULL THEN val.value
--	WHEN dp.TypeProp = 'Integer' AND val.value_precision is NOT NULL THEN val.value_precision
--	ELSE NULL
--	END as ValueInt,
--Case 
--	WHEN dp.TypeProp = 'String' AND val.value_precision is NULL THEN val.value
--	WHEN dp.TypeProp = 'String' AND val.value_precision is NOT NULL THEN val.value_precision
--	ELSE NULL
--	END as ValueString,
--Case 
--	WHEN dp.TypeProp = 'Date' AND val.value_precision is NULL THEN val.value
--	WHEN dp.TypeProp = 'Date' AND val.value_precision is NOT NULL THEN val.value_precision
--	ELSE NULL
--	END as ValueDate,
--Case 
--	WHEN dp.TypeProp = 'Float' AND val.value_precision is NULL THEN val.value
--	WHEN dp.TypeProp = 'Float' AND val.value_precision is NOT NULL THEN val.value_precision
--	ELSE NULL
--	END as ValueFloat,
--dp.ID,
--I_I.ID
--FROM [ECWP-eReleveData].[dbo].[TObj_Carac_value] val 
--JOIN [ECWP-eReleveData].[dbo].[TObj_Carac_type] typ on typ.Carac_type_Pk = val.Fk_carac
--JOIN IndividualDynProp dp ON 'TCaracThes_'+dp.Name = typ.name or 'TCarac_'+dp.Name = typ.name or  'Thes_'+dp.Name = typ.name
--JOIN Individual I_I ON  'eReleve_'+CONVERT(VARCHAR,val.fk_object) = I_I.Original_ID


--------------------------------DYNPROP V2 ----------------------------------------


--WITH toto as (
--SELECT 
--	cv.begin_date as StartDate,
--	dp.TypeProp,
--	s.ID as IndivID,
--	dp.Name as dynPropName,
--	dp.ID as dynPopID,
--	typ.name, 
--	CASE WHEN cv.value_precision IS not null THEN cv.value_precision 
--	ELSE cv.value END as Value,
--	s.Original_ID 

--  FROM [ECWP-eReleveData_old].[dbo].[TObj_Carac_value] cv
--  JOIN [ECWP-eReleveData_old].[dbo].[TObj_Carac_type] typ 
--		ON cv.Fk_carac = typ.Carac_type_Pk 
--  JOIN dbo.IndividualDynProp dp 
--		ON 'TCaracThes_'+dp.Name = typ.name 
--		or 'TCarac_'+dp.Name = typ.name 
--		or dp.Name = typ.name 
--		or 'Thes_'+dp.Name = typ.name 
--		or 'Thes_txt_'+dp.Name = typ.name
--		or 'TCaracThes_txt_'+dp.Name = typ.name
--  JOIN dbo.Individual s on 'eReleve_'+CONVERT(VARCHAR,cv.fk_object) = s.Original_ID
--  where [object_type] = 'Individual'
--  )


--INSERT INTO [dbo].[IndividualDynPropValue]
--	([StartDate]
--      ,[ValueInt]
--      ,[ValueString]
--      ,[ValueDate]
--      ,[ValueFloat]
--      ,[FK_IndividualDynProp]
--      ,[FK_Individual]
--)
--SELECT 
--	toto.StartDate,
--	CASE WHEN toto.TypeProp = 'Integer' THEN toto.value else NULL end as ValueInt,
--	CASE WHEN toto.TypeProp = 'String' THEN toto.value else NULL end as ValueString,
--	CASE WHEN toto.TypeProp = 'Date' THEN toto.value else NULL end as ValueDate,
--	CASE WHEN toto.TypeProp = 'Float' THEN toto.value else NULL end as ValueFloat,
--	toto.dynPopID,
--	toto.IndivID
--FROM toto;

--GO

/****** Script for SelectTopNRows command from SSMS  ******/
--INSERT LAST END DATE 
WITH TOTO as (SELECT 
val.end_date as StartDate,
NULL as ValueInt,
NULL as ValueString,
NULL as ValueDate,
NULL as ValueFloat,
dp.ID as FK_IndividualDynProp,
I_I.ID as FK_Individual
FROM [ECWP-eReleveData_old].[dbo].[TObj_Carac_value] val 
JOIN [ECWP-eReleveData_old].[dbo].[TObj_Carac_type] typ on typ.Carac_type_Pk = val.Fk_carac
JOIN IndividualDynProp dp ON 'TCaracThes_'+dp.Name = typ.name or 'TCarac_'+dp.Name = typ.name or  'Thes_'+dp.Name = typ.name
JOIN Individual I_I ON  'eReleve_'+CONVERT(VARCHAR,val.fk_object) = I_I.Original_ID
where end_date is not null )


INSERT INTO IndividualDynPropValue(
		[StartDate]
      ,[ValueInt]
      ,[ValueString]
      ,[ValueDate]
      ,[ValueFloat]
      ,[FK_IndividualDynProp]
      ,[FK_Individual]
)
SELECT  toto.*
  FROM [EcoReleve_ECWP].[dbo].[IndividualDynPropValuesNow] v 
  JOIN toto ON v.FK_Individual = TOTO.FK_Individual and v.FK_IndividualDynProp = toto.FK_IndividualDynProp and v.StartDate < toto.StartDate
 -- where toto.FK_IndividualDynProp = 17

with tutu as (
select Distinct cv.value,cv.value_precision
from [ECWP-eReleveData_old].dbo.TObj_Carac_value cv 
JOIN [ECWP-eReleveData_old].dbo.TObj_Carac_type ct ON cv.Fk_carac = ct.Carac_type_Pk
Where cv.value_precision is not null 
)


Update v set ValueString = th.TTop_FullPath
	FROM IndividualDynPropValue v
  JOIN dbo.IndividualDynProp dp ON v.FK_IndividualDynProp = dp.ID
  JOIN dbo.Individual i on v.FK_Individual = I.ID
  JOIN tutu ON tutu.value_precision = v.ValueString
  LEFT join THESAURUS.dbo.TTopic th 
		ON th.TTop_PK_ID> 204082
		and th.TTop_NameEn = v.ValueString 
		and tutu.value+204081 = th.TTop_PK_ID
  where  dp.name not in 
  ('Chip_Code','Comments','Individual_Status','Release_Ring_Code','Breeding_Ring_Code','Mark_code_1','Mark_code_2' )
  
  
  	 
  
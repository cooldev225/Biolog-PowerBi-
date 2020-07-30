USE [BDS-Devices]
GO

/****** Object:  View [dbo].[vw_Site_List]    Script Date: 4/12/2020 5:32:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vw_Site_List]
AS
	(
	SELECT distinct value as [Site_Name], max(CreationDate) as [Creation_Date] 
	FROM [BDS-Security].[dbo].[UserAttribute] 
	Group by [value]
	)
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[vw_User_List]
AS (
	SELECT distinct u.id, u.CreationDate, u.UserName, u.Email, u.FirstName, u.LastName, a.Value as [Site]
	FROM [BDS-Security].[dbo].[user] u
		  join [BDS-Security].[dbo].[UserAttribute] a
				on u.id = a.id 
		  join [BDS-Security].[dbo].[UserRole] ur
				on u.id = ur.UserId
		  join [BDS-Security].[dbo].[Role] r
				on r.Id = ur.RoleId
	)
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[vw_Device_List]
AS  (
	SELECT DISTINCT d.DeviceName, d.Endpoint, d.port, dm.DeviceType, dm.Reference, i.Name, ia.[Key], ia.Value
	FROM [BDS-Devices].[dbo].[DEVICE] d
		 join [BDS-Devices].[dbo].[DeviceModels] dm
			on d.DeviceModelId = dm.id 
		join [BDS-Location]..item i 
			on i.Name = d.DeviceName
		join [BDS-Location]..ItemAttribute ia
			on ia.ItemId = i.Id 
	WHERE ia.[Key] = 'type'
	)
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vm_SSTEvent]
AS
	(SELECT  ID, cast(ReceptionDate as date) as ReceptionDate, SSTDeviceId, SSTDeviceName, SSTEventId
	 FROM	 [BDS-Devices]..SSTEvent
	 )
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vm_SSTNotification] 
AS
	(SELECT  *
	 FROM	 [BDS-Devices]..SSTNotification
	 )
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


cREATE VIEW [dbo].[vw_EventCnt_Device]
AS
	(	
		select SSTDevicename, count(SSTEventId) as [Event_Cnt]
		FROM [BDS-Devices].[dbo].[SSTEvent]
		group by SSTDevicename
	)
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[vw_Current_Inv]
AS 
with data as
	(
	select  i.*,
			i.name as Unit_ID, 
			date as [Last_Entry_Date],
			row_number() over (partition by name order by date desc) as RN,
			ItemId 
			,ParentId 
			,d.DeviceName as StorageName
	from	[BDS-Location]..container c
			join [BDS-Location]..item i
				on c.itemid = i.id
			left join [BDS-Devices]..[Device] d
				on d.Id = c.ParentId
	where	i.name like 'E0%'
	)

select     distinct i.name as StorageName, Unit_ID, Last_Entry_Date, d.ItemID, ParentId, ia.Value
from	   data d
		   JOIN [BDS-Location]..ItemAttribute ia 
				on ia.ItemId = d.ParentId
			join [BDS-Location]..item i
				on i.Id = d.ParentId
where	   rn= 1 and parentid is not null 
		and ia.[Key] = 'TYPE'
--order by   i.name

-- select * from ItemAttribute where itemid = 9
-- select * from item order by 1
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



Create view [dbo].[vw_CurrentInv_PC] AS
	(
	SELECT	distinct 
			i.ID, C.StorageName,  i.Name as Unit_ID, i.Creation as [DateCreated], i.Modification, 
			CASE WHEN A.[KEY] = 'ProductNumber' THEN a.[value] END AS [ProductCode], 			
			C.Last_Entry_Date
	FROM	[BDS-Inventory].[dbo].[Item] i
			join [BDS-Inventory].[dbo].[Attribute] a
				ON I.ID = A.ItemId
			INNER JOIN [BDS-Devices]..vw_Current_Inv C
				ON I.Name = C.Unit_ID
 	where	1=1
			AND [KEY] in ('ProductNumber')
	)
GO
--==========================================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create  view [dbo].[vw_Unit_Detail]
AS with Data AS
	(
	SELECT	distinct 
				i.ID, C.StorageName, i.Name as UnitID, i.Creation as [DateCreated], i.Modification as [DateModified], 
				min(CASE WHEN A.[KEY] = 'DrawerAddress' THEN a.[value] END)			AS [DrawerAddress], 
				min(CASE WHEN A.[KEY] = 'DonationAlpha' THEN a.[value] END)			AS [DonationNumber], 
				min(CASE WHEN A.[KEY] = 'BloodGroup' THEN a.[value] END)			AS [BloodGroup], 			
				min(CASE WHEN A.[KEY] = 'Antigens' THEN a.[value] END)				AS [Antigen], 			
				min(CASE WHEN A.[KEY] = 'ProductNumber' THEN a.[value] END)			AS [ProductCode], 									
				min(CASE WHEN A.[KEY] = 'FirstPresence' THEN a.[value] END)			AS [FirstPresence], 
				min(CASE WHEN A.[KEY] = 'SecondReturn' THEN a.[value] END)			AS [SecondReturn], 
				min(CASE WHEN A.[KEY] = 'LastPresence' THEN a.[value] END)			AS [LastPresence], 
				min(CASE WHEN A.[KEY] = 'Expired' THEN a.[value] END)				AS [Expired_YN], 			
				min(CASE WHEN A.[KEY] = 'Expiry' THEN a.[value] END)				AS [ExpirationDate], 
				min(CASE WHEN A.[KEY] = 'ExitedTooLong' THEN a.[value] END)			AS [ExitedTooLong], 
				min(CASE WHEN A.[KEY] = 'ExitTime' THEN a.[value] END)				AS [ExitTime],
				min(CASE WHEN A.[KEY] = 'TotalExitTime' THEN a.[value] END)			AS [TotalExitTime],
				C.Last_Entry_Date AS LastEntryDate 
		FROM	[BDS-Inventory].[dbo].[Item] i
				join [BDS-Inventory].[dbo].[Attribute] a
					ON I.ID = A.ItemId
				LEFT JOIN [BDS-Devices]..vw_Current_Inv C
					ON I.Name = C.Unit_ID
 		where	1=1
				AND [KEY] in ( 'DrawerAddress', 'DonationAlpha','ProductNumber', 'BloodGroup', 'Antigens',  'Expired', 'Expiration', 'FirstPresence',
								'SecondReturn', 'LastPresence', 'ExitedTooLong', 'ExitTime', 'TotalExitTime', 'Expiry')
				AND i.Name like 'E0%'
	 group by	i.ID, C.StorageName, i.Name, i.Creation, i.Modification, c.last_entry_date 
	 
	 )
	 SELECT		ID, 
			    StorageName, 
				UnitID, DateCreated, DateModified, DrawerAddress, DonationNumber, 
				BloodGroup,
				CASE 
					WHEN BloodGroup = 5100 THEN 'O+'
					WHEN BloodGroup = 9500 THEN 'O-'
					WHEN BloodGroup = 6200 THEN 'A+'
					WHEN BloodGroup = 0600 THEN 'A-'
					WHEN BloodGroup = 7300 THEN 'B+'
					WHEN BloodGroup = 1700 THEN 'B-'
					WHEN BloodGroup = 8400 THEN 'AB+'
					WHEN BloodGroup = 2800 THEN 'AB-'
				END AS BloodType,
				Antigen, FirstPresence, SecondReturn, LastPresence, Expired_YN, ExpirationDate, ExitedTooLong, 
				CONVERT(DECIMAL(10,2),ExitTime) AS ExitTime_secs, CONVERT(DECIMAL(10,2),TotalExitTime) AS TotalExitTime_secs, LastEntryDate
	 
	    FROM	DATA	
	 
	 -- select * from [BDS-Inventory]..item
	 -- select * from [BDS-Inventory]..Attribute where itemid = 12 order by 2

	 -- select * from dbo.vw_Unit_Detail
GO
--==========================================================================

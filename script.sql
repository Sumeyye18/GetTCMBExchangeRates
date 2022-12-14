USE [master]
GO
/****** Object:  Database [TcmbCurrencies]    Script Date: 12.09.2022 15:59:43 ******/
CREATE DATABASE [TcmbCurrencies]

ALTER DATABASE [TcmbCurrencies] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [TcmbCurrencies].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [TcmbCurrencies] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET ARITHABORT OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [TcmbCurrencies] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [TcmbCurrencies] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET  DISABLE_BROKER 
GO
ALTER DATABASE [TcmbCurrencies] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [TcmbCurrencies] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET RECOVERY FULL 
GO
ALTER DATABASE [TcmbCurrencies] SET  MULTI_USER 
GO
ALTER DATABASE [TcmbCurrencies] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [TcmbCurrencies] SET DB_CHAINING OFF 
GO
ALTER DATABASE [TcmbCurrencies] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [TcmbCurrencies] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [TcmbCurrencies] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [TcmbCurrencies] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'TcmbCurrencies', N'ON'
GO
ALTER DATABASE [TcmbCurrencies] SET QUERY_STORE = OFF
GO
USE [TcmbCurrencies]
GO
/****** Object:  Table [dbo].[Currency_TCMB]    Script Date: 12.09.2022 15:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Currency_TCMB](
	[date] [datetime] NULL,
	[CurrCode] [nvarchar](20) NULL,
	[CurrName] [nvarchar](150) NULL,
	[ForexBuying] [float] NULL,
	[ForexSelling] [float] NULL,
	[BanknoteBuying] [float] NULL,
	[BanknoteSelling] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetHttpRequest]    Script Date: 12.09.2022 15:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create proc [dbo].[sp_GetHttpRequest]
	@httpUrlAddress			nvarchar(256), -- Http Url Address
	@httpMethod				nvarchar(10), -- Http Web Method (Get, Post, Delete, Put)
	@contentType			nvarchar(100), -- Content Type text/xml, application/json
	@authorization			nvarchar(max), -- Authorization Value
	@headerKey				nvarchar(max), -- Header Key
	@headerValue			nvarchar(max), -- Header Value
	@httpBody				nvarchar(max), -- Send Data
	@responseText			nvarchar(max) out -- Response Data
as
begin

	Declare @objectId		int -- Created Object Id (Token Id)
	Declare @hResult		int -- 0=> No Error

	Declare @statusCode		nvarchar(10) -- Http Request Status Code
	Declare @statusText		nvarchar(max) -- Http Request Status Text 

	exec @hResult = sp_OACreate 'Msxml2.ServerXMLHTTP.6.0', @objectId out, 1
	if @hResult <> 0 exec sp_OAGetErrorInfo @objectId

	--EXEC sp_OASetProperty @objectID, 'setTimeouts','1200000','1200000','9900000','9900000'


	exec @hResult = sp_OAMethod @objectId, 'open', null, @httpMethod, @httpUrlAddress, 0
	if @hResult <> 0 exec sp_OAGetErrorInfo @objectId

	if (Not @contentType is null)
	begin
		exec @hResult = sp_OAMethod @objectId, 'setRequestHeader', null, 'Content-Type', @contentType
		if @hResult <> 0 exec sp_OAGetErrorInfo @objectId
	end

	if (Not @authorization is null)
	begin
		exec @hresult = sp_OAMethod @objectId, 'setRequestHeader', null, 'Authorization', @authorization
		if @hResult <> 0 exec sp_OAGetErrorInfo @objectId
	end

	if ((Not @headerKey is null ) and (Not @headerValue is null))
	begin
		exec @hResult = sp_OAMethod @objectId, 'setRequestHeader', null, @headerKey, @headerValue
		if @hResult <> 0 exec sp_OAGetErrorInfo @objectId
	end

	exec @hResult = sp_OAMethod @objectId, 'send', null, @httpBody
	if @hResult <> 0 exec sp_OAGetErrorInfo @objectId

	exec sp_OAGetProperty @objectId, 'status', @statusCode out
	exec sp_OAGetProperty @objectId, 'statusText', @statusText out

	create table #responseTable(ResponseText nvarchar(max))

	Insert Into #responseTable(ResponseText)
	exec sp_OAGetProperty @objectId, 'ResponseText'

	select @responseText = ResponseText
	From #responseTable
	print @responseText
	drop table #responseTable
	exec sp_OADestroy @objectId

end
GO
/****** Object:  StoredProcedure [dbo].[sp_GetTCMBExchangeRates]    Script Date: 12.09.2022 15:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_GetTCMBExchangeRates]
    @date        datetime = null
as
begin
    declare @urlAddress        nvarchar(max)
    declare @responseText    nvarchar(max)

    if (@date is null)
    begin
        set @urlAddress = 'https://www.tcmb.gov.tr/kurlar/today.xml'
    end
    else
    begin
        set @urlAddress = 'https://www.tcmb.gov.tr/kurlar/' + format(@date, 'yyyyMM') + '/' + Format(@date, 'ddMMyyyy') + '.xml'
    end

    exec sp_GetHttpRequest @urlAddress, 'GET', 'text/xml', null, null, null, null, @responseText out

    Create table #ResponseTable(ResponseXML xml)

    Insert Into #ResponseTable(ResponseXML)
    Select Replace(Replace(@responseText,'<?xml version="1.0" encoding="UTF-8"?>',''),'<?xml-stylesheet type="text/xsl" href="isokur.xsl"?>','') 
       
INSERT INTO Currency_TCMB 
            
    select    Convert(datetime, b.Data.value('../@Tarih', 'nvarchar(20)'),103) [date], 
	b.Data.value('@Kod', 'nvarchar(5)') CurrCode, 
            b.Data.value('(CurrencyName/text())[1]', 'nvarchar(150)') CurrName, 
            b.Data.value('(ForexBuying/text())[1]', 'float') ForexBuying,
            b.Data.value('(ForexSelling/text())[1]', 'float') ForexSelling,
            b.Data.value('(BanknoteBuying/text())[1]', 'float') BanknoteBuying,
            b.Data.value('(BanknoteSelling/text())[1]', 'float') BanknoteSelling
    From    #ResponseTable
        Cross apply #ResponseTable.[ResponseXML].nodes('/Tarih_Date//Currency') b(Data)
    drop table #ResponseTable


end
GO
USE [master]
GO
ALTER DATABASE [TcmbCurrencies] SET  READ_WRITE 
GO

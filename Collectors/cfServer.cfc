<!--- 
Description: 	FlexMon - SeeFusion Collector.
				http://www.cflex.net/ || http://www.dopejam.com
History:		08/08/06 Tariq Ahmed	V0.1 - Created
--->
<cfcomponent hint="FlexMon - Basic CF Server Collector" extends="base">
	
	<cfset Variables.ThresholdsConfig= StructNew()>
	<cfset Variables.Warnings = 0>
	<cfset Variables.Alerts = 0>
		
	<cffunction name="init" output="false" hint="Stores pertinent configuration data related to this collector.">
		<cfargument name="Thresholds" type="xml">

		<cfset Variables.ThresholdsConfig.avgqueuetime = StructNew()>
		<cfset Variables.ThresholdsConfig.avgreqtime = StructNew()>
		<cfset Variables.ThresholdsConfig.reqqueued = StructNew()>
		<cfset Variables.ThresholdsConfig.reqrunning = StructNew()>
		<cfset Variables.ThresholdsConfig.reqtimedout = StructNew()>
		<cfset Variables.ThresholdsConfig.SimpleLoad = StructNew()>
		<cfset Variables.ThresholdsConfig.SessionCount = StructNew()>
		<cfset Variables.ThresholdsConfig.MemUsage = StructNew()>
		<cfset Variables.ThresholdsConfig.avgdbtime = StructNew()>
												
		<cfset Variables.ThresholdsConfig.avgqueuetime.warnat = Arguments.Thresholds.avgqueuetime.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.avgqueuetime.alertat = Arguments.Thresholds.avgqueuetime.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.AvgReqTime.warnat = Arguments.Thresholds.AvgReqTime.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.AvgReqTime.alertat = Arguments.Thresholds.AvgReqTime.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.reqqueued.warnat = Arguments.Thresholds.reqqueued.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.reqqueued.alertat = Arguments.Thresholds.reqqueued.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.ReqRunning.warnat = Arguments.Thresholds.ReqRunning.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.ReqRunning.alertat = Arguments.Thresholds.ReqRunning.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.ReqTimedOut.warnat = Arguments.Thresholds.ReqTimedOut.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.ReqTimedOut.alertat = Arguments.Thresholds.ReqTimedOut.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.SimpleLoad.warnat = Arguments.Thresholds.SimpleLoad.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.SimpleLoad.alertat = Arguments.Thresholds.SimpleLoad.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.SessionCount.warnat = Arguments.Thresholds.SessionCount.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.SessionCount.alertat = Arguments.Thresholds.SessionCount.XmlAttributes.alertAt>		
		
		<cfset Variables.ThresholdsConfig.MemUsage.warnat = Arguments.Thresholds.MemUsage.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.MemUsage.alertat = Arguments.Thresholds.MemUsage.XmlAttributes.alertAt>																

		<cfset Variables.ThresholdsConfig.avgdbtime.warnat = Arguments.Thresholds.avgdbtime.XmlAttributes.warnAt>
		<cfset Variables.ThresholdsConfig.avgdbtime.alertat = Arguments.Thresholds.avgdbtime.XmlAttributes.alertAt>	

		<cfreturn this>
	</cffunction>	
			
	<cffunction name="getMetrics" output="true" returntype="struct" hint="Aggregates info from all the CF Servers. Primary func.">
		<cfset var stRetVal = returnStruct()>
		<cfset var arMetricData = arraynew(1)>
		
		<!--- Fields we set --->
		<cfset var detailsFieldList = "Index,TimeStamp,Title,MemUsage">
		<cfset var detailsFieldTypes = "Integer,Varchar,Varchar,Integer">

		<!--- Fields we collect from the agent --->				
		<cfset var fieldList ="AvgDBTime,AvgQueueTime,AvgReqTime,BytesIn,BytesOut,CachePops,DBHits,InstanceName,PageHits,ReqQueued,ReqRunning,ReqTimedOut,SimpleLoad,SessionCount">
		<cfset var fieldTypes = "Integer,Integer,Integer,Integer,Integer,Integer,Integer,VarChar,Integer,Integer,Integer,Integer,Integer,Integer">
		<cfset var qMetricData = QueryNew("#detailsFieldList#,#fieldList#","#detailsFieldTypes#,#fieldTypes#")>		
		
		<!--- qAlertData is going to store info about each field and whether or not there's a situation. 0=good, 1=warn, 2=alert. --->
		<cfset var qAlertData = "">	
		<!--- This will be used to help generate qAlertData with a list of Integer types. One for each field. --->
		<cfset var alertFieldTypes = "">
		
		<cfset Variables.Warnings = 0>
		<cfset Variables.Alerts = 0>
				
		<cfloop from="1" to="#ListLen("#detailsFieldList#,#fieldList#")#" index="ndx">
			<cfset alertFieldTypes = ListAppend(alertFieldTypes,"Integer")>
		</cfloop>
		
		<cfset qAlertData = QueryNew("#detailsFieldList#,#fieldList#",alertFieldTypes)>
		
		<cfloop from="1" to="#ArrayLen(Application.arServers)#" index="ndx">
			<cfset stRetVal.isError = false>
			<cftry>
				<cfinvoke webservice="#Application.arServers[ndx].agentws#" method="getServerMetrics" returnvariable="someMetricData" timeout="2">
				<cfcatch type="any">
					<cfset stRetVal.isError = true>
					<cfset stRetVal.msg = "The XML Data Is Invalid.">
					<cfset stRetVal.returnStatus = "BADXML">	
					<cfset createNewRow(qMetricData,ndx,Application.arServers[ndx].title,now())>
					<cfset createNewRow(qAlertData,ndx,0,0)>					
					<cfloop list="#fieldList#" index="aField">
						<cfset QuerySetCell(qMetricData,aField,1000)>
						<cfset QuerySetCell(qAlertData,aField,2)>
					</cfloop>			
					<cfset QuerySetCell(qMetricData,"MemUsage",100)>
					<cfset QuerySetCell(qAlertData,"MemUsage",2)>									
				</cfcatch>
			</cftry>
			<cfif NOT stRetVal.isError>
				<cfset arMetricData[ndx] = someMetricData>
				<cfset createNewRow(qMetricData,ndx,Application.arServers[ndx].title,now())>
				<cfset createNewRow(qAlertData,ndx,0,0)>		
				
				<cfloop list="#fieldList#" index="aField">
					<cfset QuerySetCell(qMetricData,aField,someMetricData[aField])>
					<cfset QuerySetCell(qAlertData,aField,getStatusCode(aField,someMetricData[aField]))>
				</cfloop>
				<cfset QuerySetCell(qMetricData,"MemUsage",0)>			
				<cfif Len(Application.arServers[ndx].seefusionurl)>
					<cfif isDefined("Application.stSFData.MemUsage")>
						<cfset QuerySetCell(qMetricData,"MemUsage",Application.stSFData.MemUsage[Application.arServers[ndx].title])>
						<cfset QuerySetCell(qAlertData,"MemUsage",getStatusCode("MemUsage",Application.stSFData.MemUsage[Application.arServers[ndx].title]))>						
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<cfset stRetVal.data = qMetricData>
		<cfset stRetVal["alertdata"] = qAlertData>
		<cfset stRetVal.module = "coldfusion">		
		<cfset stRetVal["warnings"] = Variables.Warnings>
		<cfset stRetVal["alerts"] = Variables.Alerts>		
		<cfreturn stRetVal>
	</cffunction>	

	<cffunction name="getStatusCode" returntype="numeric" hint="Returns a code to see if that metric has exceeded a certain threshold">
		<cfargument name="metricName" type="string">
		<cfargument name="metricValue" type="any">
		<cfset var returnStatus = 0> <!--- 0 = good, 1 = warn, 2 = alert --->
		
			<cfif StructKeyExists(Variables.ThresholdsConfig,Arguments.metricName)>	
				<cfif Arguments.metricValue gte Variables.ThresholdsConfig[Arguments.metricName].alertAt>
					<cfset Variables.Alerts = Variables.Alerts +1>
					<cfset returnStatus = 2>
				<cfelseif Arguments.metricValue gte Variables.ThresholdsConfig[Arguments.metricName].warnAt>
					<cfset returnStatus = 1>
					<cfset Variables.Warnings = Variables.Warnings +1>					
				</cfif>
			</cfif>

		<cfreturn returnStatus>
	</cffunction>

	<cffunction name="createNewRow" hint="Creates a new row of data in a query">
		<cfargument name="queryName" type="query">
		<cfargument name="Index" type="numeric">
		<cfargument name="Title" type="string">
		<cfargument name="TimeStamp" type="string">		
		<cfset QueryAddRow(Arguments.queryName)>
		<cfset QuerySetCell(Arguments.queryName,"Index",Arguments.Index)>
		<cfset QuerySetCell(Arguments.queryName,"Title",Arguments.Title)>
		<cfif NOT isDate(Arguments.TimeStamp)>
			<cfset QuerySetCell(Arguments.queryName,"TimeStamp",Arguments.TimeStamp)>				
		<cfelse>
			<cfset QuerySetCell(Arguments.queryName,"TimeStamp",timeformat(Arguments.TimeStamp,"mm:ss"))>		
		</cfif>
	</cffunction>
	
	<cffunction name="resetCache" returntype="string">
		<cfreturn "ok">
	</cffunction>
	
</cfcomponent>

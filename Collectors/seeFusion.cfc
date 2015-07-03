<!--- 
Description: 	FlexMon - SeeFusion Collector.
							http://www.cflex.net/ || http://www.dopejam.com
History:			08/08/06 Tariq Ahmed	- Created
              11/10/06 Tariq Ahmed  - Updated handling to support V3 and V4 of SeeFusion.
                                    - Added better support for when there are no queries running in SeeFusion
																		  so that exceptions aren't thrown and needed to be caught (resulting in being logged to the application.log).
--->
<cfcomponent hint="FlexMon - SeeFusion Collector" extends="base">
	<cfscript>init();</cfscript>

	<cffunction name="init" output="false" hint="Constructor.">
		<cfif NOT isDefined("Application.stSFData")>
			<cfset Application.stSFData = StructNew()>  <!--- SeeFusion Data --->
			<cfset Application.stSFData["runningreqs"] = QueryNew("Title,URL,Elapsed,SQL,IP","Varchar,Varchar,Integer,Varchar,Varchar")>
			<cfset Application.stSFData["memusage"] = StructNew()>			
			<cfset Application.stSFData["lastUpdate"] = now()>
		</cfif>
		<cfset updateMetrics()>	
	</cffunction>
	
	<cffunction name="resetCache" returntype="string">
		<cfset StructDelete(Application,"stSFData")>
		<cfreturn "ok">		
	</cffunction>
	
	<cffunction name="getMetrics" output="true" returntype="struct" access="remote" hint="Just returns whatever SF data we have.">
		<cfset var stRetVal = returnStruct()>	
	
		<cfset stRetVal.data = Application.stSFData.runningreqs>
		<cfset stRetVal.module = "seefusion">
		<cfreturn stRetVal>
	</cffunction>
	
	<cffunction name="updateMetrics" output="true" returntype="struct" hint="Connects to SF's XML URLs and parses it.">
		<cfset var stRetVal = returnStruct()>		
		<cfset var xmlData = "">
		<cfset var memavail = -1>
		<cfset var memmax = -1>		
		<cfset var memusage = -1>
		<cfset var arRunningreqs = "">
		
		<!--- Wipe out the old data --->
		<cfset Application.stSFData["runningreqs"] = QueryNew("Title,URL,Elapsed,SQL,IP","Varchar,Varchar,Integer,Varchar,Varchar")>
		
		<cfloop from="1" to="#ArrayLen(Application.arServers)#" index="ndx">
			<cfif Len(Application.arServers[ndx].seefusionurl) AND NOT stRetVal.isError>
				<cfhttp url="#Application.arServers[ndx].seefusionurl#">
				
				<cftry>
					<cfset xmlData = XMLParse(trim(CFHTTP.FileContent))>
					<cfcatch type="any">
						<cfset stRetVal.isError = true>
						<cfset stRetVal.msg = "The XML Data Is Invalid.">
						<cfset stRetVal.returnStatus = "BADXML">						
					</cfcatch>
				</cftry>
				
				<cfif NOT stRetVal.isError>
					<cfif Application.arServers[ndx].SeeFusionVer eq "3">
						<cfset memavail = xmlData.seefusioninfo.server.memory.available.XmlText>
						<cfset memmax = xmlData.seefusioninfo.server.memory.currentmax.XmlText>	
		 			<cfelseif Application.arServers[ndx].SeeFusionVer eq "4">
						<cfset memavail = xmlData.seefusioninfo.memory.available.XmlText>
					    <cfset memmax = xmlData.seefusioninfo.memory.currentmax.XmlText>	
					</cfif>
					
					<cfset memusage = Int((memavail/memmax)*100)>
					<cfset Application.stSFData.Memusage[Application.arServers[ndx].title] = Memusage>
					<cfif isDefined("xmlData.seefusioninfo.server.runningRequests.page")>
						<cfset arRunningreqs = xmlData.seefusioninfo.server.runningRequests.page>
						<cfloop from="1" to="#ArrayLen(arRunningReqs)#" index="pgNDX">
							<cfset QueryAddRow(Application.stSFData.RunningReqs)>
							<cfset QuerySetCell(Application.stSFData.RunningReqs,"Title",Application.arServers[ndx].title)>
							<cfset QuerySetCell(Application.stSFData.RunningReqs,"URL",arRunningReqs[pgNDX].Url.xmlText)>
							<cfset QuerySetCell(Application.stSFData.RunningReqs,"Elapsed",NumbersOnly(arRunningReqs[pgNDX].Time.xmlText))>					
							<cfset QuerySetCell(Application.stSFData.RunningReqs,"IP",arRunningReqs[pgNDX].IP.xmlText)>			
							<cfif StructKeyExists(arRunningReqs[pgNDX],"Query")>
								<cfset QuerySetCell(Application.stSFData.RunningReqs,"SQL",arRunningReqs[pgNDX].Query.Sql.xmlText)>	
							<cfelse>
								<cfset QuerySetCell(Application.stSFData.RunningReqs,"SQL","")>				
							</cfif>												
						</cfloop>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<cfset Application.stSFData.lastUpdate = now()>
		<cfquery name="qReOrder" dbtype="query">
		  SELECT * from Application.stSFData.RunningReqs
		    order by Elapsed DESC
		</cfquery>
		
		<cfset Application.stSFData.RunningReqs = qReOrder>
		<cfreturn stRetVal>
	</cffunction>
	
	<cffunction name="NumbersOnly" returntype="string" hint="Used to deal with peculiarities in SF's XML">
		<cfargument name="someString" type="string" default="0">
		<cfreturn reReplace(Arguments.someString,"[^[:digit:]]","","all")>
	</cffunction>
	
</cfcomponent>
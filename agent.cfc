<!--- 
Description: 	Agent Component. Used to send back to the aggregator metrics about this machine.
History:		08/05/06 Tariq Ahmed	V0.1 - Created
--->
<cfcomponent>
	<cffunction name="getServerMetrics" access="remote" returntype="struct" hint="Gets basic details on the machine">
		<cfset var stMetrics = getMetricData("perf_monitor")>
		<cfset var stSessions = "">
		<cfset stMetrics["simpleLoad"] = getMetricData("simple_load")>
		<cfset stSessions = getActiveSessionCount()>
		<cfset stMetrics["sessionCount"] = stSessions.total>
		<cfreturn stMetrics>
	</cffunction>
	
	<cffunction name="getActiveSessionCount" access="public" returntype="struct" hint="Gets a count of all active sessions.">
   		<cfargument name="AppList" default="" hint="A List of all application names. Or leave blank to a combined total.">
		
   	<cfset var sessiontrackerObj= createObject("java","coldfusion.runtime.SessionTracker")>
		<cfset var stSessions = structNew()>
		<cfset var totalSessions = 0>
		
		<cfset stSessions["total"] = sessionTrackerObj.getSessionCount()>
		<cfif Len(Arguments.AppList)>
			<cfloop list="#Arguments.AppList#" index="app">
				<cfset activesessions = sessiontrackerObj.getSessionCollection('#app#')>
			    <cfset totalSessions=ListLen(structkeyList(activeSessions))>
				<cfset stSessions[app] = totalSessions>		
		   </cfloop>
		</cfif>	
		<cfreturn stSessions>
	</cffunction>	
</cfcomponent>
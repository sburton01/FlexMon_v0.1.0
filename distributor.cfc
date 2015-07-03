<!--- 
Description: Primary Component. Aggregates data from all sources and sends to client
             http://www.cflex.net/ || http://www.dopejam.com
History:     08/05/06 Tariq Ahmed	V0.1 - Created
             08/08/06 Tariq Ahmed	V0.2 - Totally restructured the CFCs, introduced the concept of the Collector class.
--->
<cfcomponent>


	<cfscript>init();</cfscript>

	<cffunction name="init" output="true" hint="Constructor. Reads in Configuration Info.">
		<cfif NOT isDefined("Application.arServers")>
			<cfset Application.arServers = arrayNew(1)>
			<cfset Application.xmlConfig = "">
			
			<cffile action="read" file="#ExpandPath(".")#\config.xml" variable="XMLData">
			<cfset Application.xmlConfig = XMLParse(trim(XMLData))>

			<cfloop from="1" to="#ArrayLen(Application.xmlconfig.flexmon.servers.server)#" index="ndx">
				<cfset Application.arServers[ndx] = StructNew()>
				<cfset Application.arServers[ndx].Title   = Application.xmlconfig.flexmon.servers.server[ndx].XmlAttributes.Title>
				<cfset Application.arServers[ndx].AgentWS = Application.xmlconfig.flexmon.servers.server[ndx].AgentWS.XmlText>			
				<cfset Application.arServers[ndx].SeeFusionURL = Application.xmlconfig.flexmon.servers.server[ndx].SeeFusionURL.XmlText>		
				<cfset Application.arServers[ndx].SeeFusionVer = Application.xmlconfig.flexmon.servers.server[ndx].SeeFusionURL.XmlAttributes.majorversion>									
			</cfloop>
			<cfset Application.collectorColdFusion = createObject("component","Collectors.cfServer").init(Application.xmlConfig.flexmon.thresholds.coldfusion)>
			<cfset Application.collectorSeeFusion = createObject("component","Collectors.seeFusion")>		
			<cfset Application.collectorFax = createObject("component","Collectors.fax")>				

		</cfif>

	</cffunction>

	<cffunction name="getMetrics" returntype="any" access="remote">
		<cfargument name="Module" default="Coldfusion" hint="Context, metrics for which module?">
		
		<cfswitch expression="#Arguments.Module#">
			<cfcase value="Coldfusion">
				<cfreturn Application.collectorColdFusion.getMetrics()>
			</cfcase>
			<cfcase value="SeeFusion">
				<cfreturn Application.collectorSeeFusion.getMetrics()>
			</cfcase>					
		</cfswitch>
	</cffunction>

	<cffunction name="resetCache" hint="Nukes the in-memory cache.">
		<cfset StructDelete(Application,"arServers")>
	</cffunction>

</cfcomponent>
